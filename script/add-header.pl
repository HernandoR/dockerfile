#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

# 向返回结果中添加 header
my $argvLen = scalar(@ARGV);
if($argvLen < 2){
    die('参数数量不足');
}
`echo $ARGV[0] >> $ENV{'RESP_HEADER_FILE'}`;
`echo $ARGV[1] >> $ENV{'RESP_HEADER_FILE'}`;
