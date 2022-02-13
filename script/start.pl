#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
=pod
    用于接收请求内容并进行调用脚本
=cut

#==============================================================读取请求内容

# 用于解析请求的第一行
sub parseFirstLine {
    my ($line) = @_;
    my @splitGetPathData = split(/ /, $line);
    # 没有提取到数据
    # 这一行的数据为: GET /a/b/c HTTP/1.1
    if(scalar @splitGetPathData < 3){
        die('请求数据异常');
    }
    my ($methodType, $requestUri, $httpVersion) = @splitGetPathData;

    # 解析请求路径和 Get 参数
    # 提取路径
    my @tmpSplitData = split(/\?/, $requestUri);
    my $path = $tmpSplitData[0];
    my $queryStr = '';
    # 解析参数
    if(scalar @tmpSplitData > 1){
        $queryStr = $tmpSplitData[1];
    }
    return ($methodType, $path, $queryStr, $httpVersion);
}

# 从请求参数字符串内容中解析
sub parseQueryParam {
    my ($queryStr) = @_;
    if($queryStr eq ''){
        return ();
    }
    my %paramsMap = ();
    my @tmpSplitParamsData = split(/&/, $queryStr);
    foreach my $itemData (@tmpSplitParamsData){
        my @tmpItemData = split(/=/, $itemData);
        $paramsMap{$tmpItemData[0]} = $tmpItemData[1];
    }
    %paramsMap;
}

# 定义解析出来的内容
my $methodType = '';
my $httpVersion = '';
my $formContent = '';
my $requestPath = '';
my $queryStr = '';
my %paramsMap = ();
my %headerMap = ();

# 按照字节读取输入的所有内容
# 这里按照字节读取, 是因为输入流的最后有可能不是换行, 如果按照行读取, 可能会缺少数据
my $line = ''; # 记录当前行的内容
my $lineNum = 1; # 记录当前读到了第几行
my $contentLen = 0; # 记录 content 内容的字节长度
while(1){
    my $byte = '';
    read (STDIN, $byte, 1);
    $line = "$line$byte";
    # 一行还没有读完, 继续读取下一个字节
    if($byte ne "\n"){
        next;
    }
    # 读到一行内容, 将结尾的换行去掉
    $line =~ s/\r\n//;
    # 若这里读到的是空行, 说明已经将头信息读取完毕了. 读取剩余 content. 结束读取
    if($line eq ''){
        if($contentLen > 0){
            read(STDIN, $formContent, $contentLen);
        }
        last();
    }
    # 第一行是协议以及路径版本
    if($lineNum == 1){
        ($methodType, $requestPath, $queryStr, $httpVersion) = parseFirstLine($line);
        %paramsMap = parseQueryParam($queryStr);
    }else{ # 后面是 header
        my @splitLine = split(/: /, $line);
        if(scalar @splitLine >= 2){
            # 记录内容长度, 最后读取使用
            if(lc($splitLine[0]) eq 'content-length'){
                $contentLen = $splitLine[1];
            }
            $headerMap{$splitLine[0]} = $splitLine[1];
        }
    }
    # 当前行处理完毕, 清空行的缓冲内容, 读取下一行
    $line = '';
    $lineNum++;
}


# 将内容写入到环境变量中
$ENV{'METHOD_TYPE'} = $methodType;
$ENV{'HTTP_VERSION'} = $httpVersion;
$ENV{'REQUEST_URI'} = $requestPath;
$ENV{'QUERY_STR'} = $queryStr;
$ENV{'FORM_CONTENT'} = $formContent;
while(my ($paramKey, $paramValue) = each(%paramsMap)){
    $ENV{"QUERY_PARAM_$paramKey"} = $paramValue;
}
while(my ($headerKey, $headerValue) = each(%headerMap)){
    $ENV{"HEADER_$headerKey"} = $headerValue;
}
# 文件用于接收返回的状态码
my $headerFile = "/var/run/http_cron/add_header_$$";
my $statusFile = "/var/run/http_cron/status_$$";
$ENV{'RESP_HEADER_FILE'} = $headerFile;
$ENV{'RESP_STATUS_FILE'} = $statusFile;


#==============================================================调用脚本获取返回

# 根据访问路径调用不同的脚本
# 将最前面的 / 去掉
my $cronName = substr($requestPath, 1);

my $workspace = $ENV{'WORKSPACE'};
my $cronPath = "$workspace/$cronName";
my $respContent = "";

# 脚本可识别多种脚本
my @suffixList = ('pl', 'sh', 'bash', 'py', 'php', 'rb');
my $isFind = 0;
for my $suffix (@suffixList){
    my $fileName = "$cronPath.$suffix";
    if(-e $fileName){
        $respContent = `$fileName`;
        $isFind = 1;
        last;
    }
}
if(!$isFind){
    `set-status 404`;
}

#==============================================================输出结果信息

# 状态信息
my %statusMsgMap = (
    100 => 'Continue',
    101 => 'Switching Protocols',
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information;',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'Found',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    306 => 'Unused',
    307 => 'Temporary Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Time-out',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Large',
    415 => 'Unsupported Media Type',
    416 => 'Requested range not satisfiable',
    417 => 'Expectation Failed',
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Time-out',
    505 => 'HTTP Version not supported',
);

my %respHeaderMap = ();
my $respStatus = 200;
# 读取返回结果并输出
if(-e $headerFile){
    open(HEADER_FILE, "<$headerFile");
    my @headerList = <HEADER_FILE>;
    my $index = 0;
    while($index < scalar(@headerList) - 1){
        my $headerKey = $headerList[$index];
        my $headerValue = $headerList[$index + 1];
        $headerKey =~ s/\n//;
        $headerValue =~ s/\n//;
        $respHeaderMap{$headerKey} = $headerValue;
        $index += 2;
    }
}
if(-e $statusFile){
    open(STATUS_FILE, "<$statusFile");
    while(<STATUS_FILE>){
        $respStatus = $_;
        $respStatus =~ s/\n//;
    }
}

# 开始输出
my $statusMsg = '';
if(exists($statusMsgMap{$respStatus})){
    $statusMsg = " $statusMsgMap{$respStatus}";
}
print("$httpVersion $respStatus$statusMsg\r\n");
while(my ($headerKey, $headerValue) = each(%respHeaderMap)){
    print("$headerKey: $headerValue\r\n");
}
print("\r\n");
print($respContent);

unlink $headerFile;
unlink $statusFile;