#!/bin/bash

#   Slick Progress Bar
#   Created by: Ian Brown (ijbrown@hotmail.com)
#   Please share with me your modifications
# Functions
PUT(){ echo -en "\033[${1};${2}H";}
DRAW(){ echo -en "\033%";echo -en "\033(0";}
WRITE(){ echo -en "\033(B";}
HIDECURSOR(){ echo -en "\033[?25l";}
NORM(){ echo -en "\033[?12l\033[?25h";}

function showBar {
    percDone=$(echo 'scale=2;'$1/$2*100 | bc)
    halfDone=$(echo $percDone/2 | bc) #I prefer a half sized bar graph
    barLen=$(echo ${percDone%'.00'})
    halfDone=`expr $halfDone + 6`
    tput bold
    PUT 7 28; printf "%4.4s  " $barLen%     #Print the percentage
    PUT 5 $halfDone;  echo -e "\033[7m \033[0m" #Draw the bar
    tput sgr0
}

# Start Script
clear
HIDECURSOR
echo -e ""
echo -e ""
DRAW    #magic starts here - must use caps in draw mode
echo -e "          PLEASE WAIT WHILE SCRIPT IS IN PROGRESS"
echo -e "    lqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqk"
echo -e "    x                                                   x"
echo -e "    mqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj"
WRITE
#
# Insert your script here
for (( i=0; i<=50; i++ ))
do
    showBar $i 50  #Call bar drawing function "showBar"
    sleep .2
done
# End of your script
# Clean up at end of script
PUT 10 12
echo -e ""
NORM

