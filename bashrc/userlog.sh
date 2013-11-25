# usage: install this file to /etc/profile.d/ or add to /etc/profile
export HISTTIMEFORMAT="%y-%m-%d %H:%M:%S "
PS1="`whoami`@`hostname`:"'[$PWD]'

history
USER_IP=`who -u am i 2>/dev/null | awk '{print $NF}' | sed -e 's/[()]//g'`

if [ "X$USER_IP" == "X:0" ]; then
    USER_IP=`hostname`
elif [ "X$USER_IP" == "X" ]; then
    USER_IP=`hostname`
fi

if [ ! -d "/tmp/history" ]; then
    mkdir /tmp/history
    chmod 777 /tmp/history
fi

if [ ! -d /tmp/history/${LOGNAME} ]; then
    mkdir /tmp/history/${LOGNAME}
    chmod 300 /tmp/history/${LOGNAME}
fi

export HISTSIZE=4096
DT=$(date +"%Y%m%d_%H%M%S")
export HISTFILE="/tmp/history/${LOGNAME}/${USER_IP}_history.$DT"
chmod 600 /tmp/history/${LOGNAME}/*history* 2>/dev/null
