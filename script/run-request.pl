#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
=pod
    用于接收请求内容并进行调用脚本
=cut

#==============================================================读取请求内容

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

my $queryUri = $ENV{'REQUEST_STR'};
# 提取路径
my @tmpSplitData = split(/\?/, $queryUri);
my $requestPath = $tmpSplitData[0];
$ENV{'REQUEST_URI'} = $requestPath;
# 解析 get 请求参数
my %paramsMap = parseQueryParam($ENV{"QUERY_STR"});
while(my ($paramKey, $paramValue) = each(%paramsMap)){
    $ENV{"QUERY_PARAM_$paramKey"} = $paramValue;
}

# 解析 header. 这里替换 header 的开头, 是为了兼容历史版本
my %envTmp = %ENV; # map 不能一边赋值一边遍历
while(my ($envKey, $envValue) = each(%envTmp)){
    # 若是 HTTP_ 打头的字符串, 则认为是 nginx 切割好的 header 内容
    if($envKey =~ /^HTTP_/){
        $envKey =~ s/^HTTP_/HEADER_/;
        $ENV{$envKey} = $envValue;
    }
}
# 文件用于接收返回的状态码
my $headerFile = "/var/run/http_cron/add_header_$$";
my $statusFile = "/var/run/http_cron/status_$$";
$ENV{'RESP_HEADER_FILE'} = $headerFile;
$ENV{'RESP_STATUS_FILE'} = $statusFile;

# 若请求提文件存在, 则读取其内容并放入环境变量中
if($ENV{'REQUEST_BODY_FILE'} ne '' && $ENV{'FORM_CONTENT'} eq '' && $ENV{'INIT_FORM_CONTENT'} eq '1'){
    # 获取文件大小
    my @fileStat = stat($ENV{'REQUEST_BODY_FILE'});
    my $fileStatLen = @fileStat;
    if($fileStatLen >= 7){
        my $fileSize = $fileStat[7];
        # 若内容过大, 即使要求读入也不行
        if($fileSize < 1024*64){
            open(REQUEST_BODY_FILE, "<$ENV{'REQUEST_BODY_FILE'}");
            my @string = <REQUEST_BODY_FILE>;
            $ENV{'FORM_CONTENT'} = join('',@string);;
        }else{
            print STDERR "Request body too big, size: $fileSize. Please read content from file. The file name in env REQUEST_BODY_FILE.";
        }
    }else{
        print STDERR "get file size error";
    }
}

#==============================================================调用脚本获取返回

# 根据访问路径调用不同的脚本
# 将最前面的 / 去掉
my $cronName = substr($requestPath, 1);

my $workspace = $ENV{'WORKSPACE'};
my $cronPath = "$workspace/$cronName";
my $respContent = "";

# 脚本可识别多种脚本
my @suffixList = ('pl', 'sh', 'bash', 'py', 'php', 'rb');
`set-status 404`; # 先将状态码设置为404
for my $suffix (@suffixList){
    my $fileName = "$cronPath.$suffix";
    if(-e $fileName){
        if(-x $fileName){
            `set-status 200`; # 找到文件了, 默认返回200
            $respContent = `$fileName`;
        }else{
            # 文件没有执行权限
            `set-status 500`;
            # 向异常输出, 文件没有执行权限
            print STDERR "Can't exec $fileName (Permission denied)";
        }
        last;
    }
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
print("Status: $respStatus$statusMsg\r\n");
while(my ($headerKey, $headerValue) = each(%respHeaderMap)){
    print("$headerKey: $headerValue\r\n");
}
print("\r\n");
print($respContent);

unlink $headerFile;
unlink $statusFile;