#!/usr/bin/perl

# cpan install YAML 
# cpan install YAML::Syck
# cpan install RRD::Simple
# cpan install Sys::Statistics::Linux

use strict;
use warnings;
use Smart::Comments;
use RRD::Simple qw(:all);
use YAML;
use Sys::Statistics::Linux;
my $home;
chomp($home = `pwd`);
## $home
my $rrdfile = $home . '/myfile.rrd';
## $rrdfile
my $rrdfile_tmp = $home . '/myfile_tmp.rrd';
## $rrdfile_tmp
my $rrd = RRD::Simple->new( file => "$rrdfile" );
my $rrd_tmp = RRD::Simple->new( file => "$rrdfile_tmp"); #建立一个临时rrd用于计算5分钟内变化的差值

unless(-e $rrdfile){
 $rrd->create(                                         #如果没有rrd则进行建立一个rrd
             bytesIn => "GAUGE",                       #定义数值源类型
             bytesOut => "GAUGE",      
         );
 $rrd_tmp->create(
             bytesIn => "GAUGE",
             bytesOut => "GAUGE",
         );
}

my ($now_input,$now_output,$input,$output);

my $lxs = Sys::Statistics::Linux->new(    # 这里进行获取网卡的流量（这个模块可以获取多个系统参数，
                                          # 如cpu,process,磁盘IO）
                                          # 可以根据这些可以绘制这种图形。
    netstats => {
            init     => 1,
            initfile => '/tmp/netstats.yml',  #数据存入yml文件
        },
);
   
my $stat = $lxs->get;
my $config = YAML::LoadFile('/tmp/netstats.yml');#解析yml文件
$now_input = $config->{eth0}->{rxbyt};  
$now_output = $config->{eth0}->{txbyt};
my $info = $rrd->info("$rrdfile_tmp");  #获取tmp的数据
my $before_input_5=$info->{ds}->{bytesIn}->{last_ds};   #获取5分钟之前的数据
my $before_output_5=$info->{ds}->{bytesOut}->{last_ds};
if ($before_input_5  eq 'U' || $before_output_5 eq 'U'){
    $before_input_5 = $now_input;
    $before_output_5 = $now_output;
}

$input = $now_input - $before_input_5;   #5分钟变化的数据
$output = $now_output - $before_output_5;

$rrd->update(
             bytesIn => "$input",
             bytesOut => "$output",
         );

$rrd_tmp->update(
             bytesIn => "$now_input",
             bytesOut => "$now_output",
         );

my $starttime = time;                #获取当前unix时间戳
my $endtime = $starttime - 7200;   #2个小时之前的unix时间戳
my %rtn = $rrd->graph(  #这里是定义每周，每月，每年的图形。
            timestamp => "both", 
            periods => [ qw{    weekly monthly annual}  ],  #定义所需的周期文件
            title => "Network Interface eth0",
            vertical_label => "Bytes/sec",
            line_thickness => 2,      #画线的像素
            extended_legend => 1,     #打开详细信息
         );

 %rtn = $rrd->graph(               #这里是定义一个2小时的图形，去掉下面的end,start为一天的图
            destination => "$home",
            timestamp => "both",
            periods => [ qw{ daily  }  ],
            title => "Network Interface eth0",
            vertical_label => "Bytes/sec",
            line_thickness => 2,
            extended_legend => 2,
            end => $starttime,
            start =>$endtime,
            "COMMENT:                                              " => "",
       #此处的COMMENT是有空格的，尼玛真是一个一个空格来对齐下面的格式，靠O__O"…
       "GPRINT:bytesOut:AVERAGE: bytesOut平均值%8.2lf%s"=> "",
       "COMMENT:            " => "",
       "GPRINT:bytesIn:AVERAGE: bytesIn平均值%8.2lf%s"=> "",      
         );

my $lastUpdated = $rrd->last;
 print "myfile.rrd was last updated at " .
       scalar(localtime($lastUpdated)) . "\n";

