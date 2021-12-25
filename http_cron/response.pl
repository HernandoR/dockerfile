#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

=pod
    用于输出页面返回值
    调用格式如下:
response --status=200 --header_key=value content
其中 status 默认为空
header 默认么有
=cut

my $status = 200;
my %headerMap = ();
my $content = '';

my $argvLen = scalar(@ARGV);
# 接收请求参数
my $index = 0;
while($index < $argvLen - 1){
    # 解析参数
    my @splitArg = split(/=/, $ARGV[$index], 2);
    # 格式错误
    if(scalar(@splitArg) < 2){
        next;
    }
    # 将前面的 -- 去掉
    my $argKey = substr($splitArg[0], 2);
    if($argKey eq 'status'){
        $status = $splitArg[1];
    }elsif($argKey =~ /^header_/){
        my $headerKey = substr($argKey, 7);
        $headerMap{$headerKey} = $splitArg[1];
    }
    $index++;
}
# 最后一个参数是 content
if($argvLen >= 1){
    $content = $ARGV[$argvLen - 1];
}


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

# 开始输出
my $httpVersion = $ENV{'HTTP_VERSION'};
my $statusMsg = '';
if(exists($statusMsgMap{$status})){
    $statusMsg = " $statusMsgMap{$status}";
}
print("$httpVersion $status$statusMsg\r\n");
while(my ($headerKey, $headerValue) = each(%headerMap)){
    print("$headerKey: $headerValue\r\n");
}
print("\r\n");
print($content);

