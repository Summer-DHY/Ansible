#!/bin/bash
#设置服务开机自启动


for i in `chkconfig --list|grep 3:on|grep -vE "crond|network|ntpd|rsyslog|sshd"|gawk '{print $1}'`;
do 
	chkconfig $i off
done 
