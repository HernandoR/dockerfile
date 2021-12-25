#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

=pod
    用于接收请求内容并进行调用脚本
=cut

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
my ($methodType, $httpVersion, %paramsMap, $requestPath, $queryStr, %headerMap, $formContent);

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
    # 已经将头信息读取完毕, 读取剩余 content. 结束读取
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
            if($splitLine[0] eq 'content-length'){
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

# 根据访问路径调用不同的脚本
# 将最前面的 / 去掉
my $cronName = substr($requestPath, 1);
# 若访问跟路径, 直接返回
if($cronName eq ''){
    print(`response --status=404 ""`);
    exit(0);
}

my $workspace = $ENV{'WORKSPACE'};
my $cronPath = "$workspace/$cronName";

# 脚本可识别多种脚本
my @suffixList = ('pl', 'sh', 'bash', 'py', 'php', 'rb');
my $isFind = 0;
for my $suffix (@suffixList){
    my $fileName = "$cronPath.$suffix";
    if(-e $fileName){
        my $rep = `$fileName`;
        if($rep eq ''){ # 若没有返回, 默认200
            print(`response ""`);
        }else{
            print($rep);
        }
        $isFind = 1;
        last;
    }
}
if(!$isFind){
    print(`response --status=404 ""`);
}


