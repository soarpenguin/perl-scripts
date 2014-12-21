#!/usr/bin/env bash

HOST=$1
USERNAME=$2
PASSWORD=$3

echo n | ssh-keygen -t dsa -f ~/.ssh/id_dsa -N '' > /dev/null
	
pass=`cat ~/.ssh/id_dsa.pub`

lftp -e "cd .ssh; get authorized_keys;quit" -u $USERNAME,$PASSWORD $HOST 1> /dev/null

grep "$USER@$HOST" authorized_keys
if [ $? -ne 0 ]
then
	echo $pass >> authorized_keys

	lftp -e "cd .ssh; put authorized_keys;chmod 600 authorized_keys;quit" -u $USERNAME,$PASSWORD $HOST 1> /dev/null

	rm authorized_keys

	grep $HOST ~/.ssh/known_hosts
	if [ $? -ne 0 ]
	then
		IP=`net lookup $HOST`
	
		lftp -e "cd /etc/ssh; get ssh_host_rsa_key.pub;quit" -u $USERNAME,$PASSWORD $HOST 1> /dev/null
		RSA=`cat ssh_host_rsa_key.pub`
		rm ssh_host_rsa_key.pub
	
		echo "$HOST,$IP $RSA" >> ~/.ssh/known_hosts
	fi
else
	rm authorized_keys
fi
