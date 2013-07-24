#!/bin/bash
 
#sub process do something
function a_sub_process { 
    echo "processing in pid [$$]"
    sleep 1
}
 
#创建一个fifo文件
FIFO_FILE=/tmp/$$.fifo
mkfifo $FIFO_FILE
 
#关联fifo文件和fd6
exec 6<>$FIFO_FILE      # 将fd6指向fifo类型
rm $FIFO_FILE
 
#最大进程数
PROCESS_NUM=4
 
#向fd6中输入$PROCESS_NUM个回车
for ((idx=0;idx<$PROCESS_NUM;idx++));
do
    echo
done >&6 
 
#处理业务，可以使用while
for ((idx=0;idx<20;idx++));
do
    read -u6  #read -u6命令执行一次，相当于尝试从fd6中获取一行，如果获取不到，则阻塞
    #获取到了一行后，fd6就少了一行了，开始处理子进程，子进程放在后台执行
    {
      a_sub_process && { 
         echo "sub_process is finished"
      } || {
         echo "sub error"
      }
      #完成后再补充一个回车到fd6中，释放一个锁
      echo >&6 # 当进程结束以后，再向fd6中加上一个回车符，即补上了read -u6减去的那个
    } &
done
 
#关闭fd6
exec 6>&-
