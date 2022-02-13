#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

=pod
    用于输出页面返回值
    调用格式如下:
response --status=200 --header_key=value content
其中 status 默认为空
header 默认么有

在 1.1 版本已不再建议使用, 保留仅是为了向后兼容
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

`set-status $status`;
while(my ($headerKey, $headerValue) = each(%headerMap)){
    `add-header "$headerKey" "$headerValue"`;
}
print($content);

