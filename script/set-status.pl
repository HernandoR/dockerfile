#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

# 设置返回响应码
my $argvLen = scalar(@ARGV);
if($argvLen < 1){
    die('参数数量不足');
}
`echo $ARGV[0] > $ENV{'RESP_STATUS_FILE'}`;
