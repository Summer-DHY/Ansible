#!/bin/sh
# deploy_manage.sh
# python2.6部署  licairong  2011-01-07
#set -x

DIR=`pwd`
URL="http://208.gyyx.cn/cairong/init"
LOG_FILE="install_log.txt"
OS=`awk '/Red Hat/{print $1"_"$2"_"$7}' /etc/issue`

# 日志函数
wr_log(){
	TIME=`date +"%Y-%m-%d %H:%M:%S"`
	if [ $1 -eq 0 ];then
		echo "[$TIME] $2 done" >> ${DIR}/${LOG_FILE}
	else
		echo "[$TIME] $2 failed"
		exit -1
	fi
}

# 添加manage用户
chk_user(){
	/usr/bin/id manage > /dev/null 2>&1
	if [ $? -ne 0 ];then
		/usr/sbin/useradd manage
		wr_log $? "add user manage"
	else
		if [ ! -d /home/manage ];then
			mkdir -p /home/manage
		fi
		wr_log $? "add user manage"
	fi
}

# 部署python2.6
deploy_python(){
	if [ "$OS" = "Red_Hat_6.2" ];then
		uname -a | grep x86_64 > /dev/null
		if [ $? -eq 0 ];then
			filename="mysql-python-1.0-1.x86_64.rpm"
		else
			filename="mysql-python-1.0-1.i386.rpm"
		fi
		wget ${URL}/${filename} -O ${DIR}/${filename} > /dev/null 2>&1
		wr_log $? "download ${URL}/${filename}"
		rpm -ivh ${DIR}/${filename}
		wr_log $? "install ${filename}"
		rm -f ${DIR}/${filename}
		return
	elif [ "$OS" = "Red_Hat_5.3" -o "$OS" = "Red_Hat_5" -o "$OS" = "Red_Hat_5.5" ];then
		tgz_name="py_install_as5.tgz"
	elif [ "$OS" = "Red_Hat_4" ];then
		tgz_name="py_install_as4.tgz"
	fi
	wget ${URL}/${tgz_name} -O ${DIR}/${tgz_name} > /dev/null 2>&1
	wr_log $? "download ${URL}/${tgz_name}"
	tar zxvf ${DIR}/${tgz_name} -C /usr > /dev/null 2>&1
	wr_log $? "unzip $tgz_name to /usr"
	rm -f ${DIR}/${tgz_name}
}

deploy_manage(){
	echo -e 'import sys\nprint sys.version[:3]' > ver.py
	py_ver=`python ver.py`
	if [ "$py_ver" = "2.4" ]; then
		tgz_file="manage_py24.tgz"
		wget http://208.gyyx.cn/cairong/init/rotor2_py24.pyc -O /usr/lib/python2.4/site-packages/rotor2.pyc > /dev/null 2>&1
		wr_log $? "download http://208.gyyx.cn/cairong/init/rotor2_py24.pyc"
		wget http://208.gyyx.cn/cairong/init/json.pyc -O /usr/lib/python2.4/site-packages/json.pyc > /dev/null 2>&1
		wr_log $? "download http://208.gyyx.cn/cairong/init/json.pyc"
	else
		tgz_file="manage.tgz"
	fi
	wget http://208.gyyx.cn/manage/${tgz_file} -O ${DIR}/manage.tgz > /dev/null 2>&1
	wr_log $? "download http://208.gyyx.cn/manage/${tgz_file}"
	tar -zxvf ${DIR}/manage.tgz -C /home/ > /dev/null 2>&1
	wr_log $? "unzip manage.tgz to /home"
	chown manage.manage /home/manage /home/manage/bin /home/manage/etc /home/manage/log /home/manage/script
	chmod 755 /home/manage /home/manage/bin /home/manage/etc /home/manage/log
	wr_log $? "change manage privileges"
	if [ ! -f /home/deploy/etc/deploy.conf ];then
		wget http://208.gyyx.cn/cairong/init/deploy.conf -O /home/deploy/etc/deploy.conf > /dev/null 2>&1
	fi
	md5=`/usr/bin/md5sum ${DIR}/manage.tgz | awk '{print $1}'`
	sed -i 's/md5 = .*/md5 = '${md5}'/' /home/manage/etc/manage.conf
	wr_log $? "change manage.conf"
	rm -f ${DIR}/manage.tgz
	
	sed -i '/127.0.0.1/d' /etc/hosts
	echo "127.0.0.1               localhost.localdomain localhost" >> /etc/hosts
	echo "127.0.0.1               `hostname`" >> /etc/hosts
	sed -i 's/^Defaults    requiretty/#&/' /etc/sudoers
	sed -i '/\/home\/manage/d' /etc/sudoers
	echo "manage  ALL=(root)      NOPASSWD:       /home/manage/bin/manage.py" >> /etc/sudoers
	echo "manage  ALL=(root)      NOPASSWD:       /home/manage/bin/update.py" >> /etc/sudoers
	wr_log $? "add manage to sudoers"
	
	sed -i '/su manage/d' /etc/rc.d/rc.local
	wget http://208.gyyx.cn/manage/managed -O /etc/init.d/managed > /dev/null 2>&1
	/sbin/chkconfig --add managed
	/sbin/chkconfig --level 2345 managed on
	chmod 755 /etc/init.d/managed
	/etc/init.d/managed restart > /dev/null 2>&1
	wr_log $? "start managed"
	
	# sed -i '/su manage/d' /etc/rc.d/rc.local
	# echo "su manage -c 'python /home/manage/bin/svr.pyc update'" >> /etc/rc.d/rc.local
	# echo "su manage -c 'python /home/manage/bin/svr.pyc'" >> /etc/rc.d/rc.local
	# wr_log $? "add manage to rc.local"
	# kill -9 `ps auxww | grep "svr.pyc" | grep -v grep | awk '{print $2}'` > /dev/null 2>&1
	# su manage -c 'python /home/manage/bin/svr.pyc update'
	# su manage -c 'python /home/manage/bin/svr.pyc'
	# wr_log $? "start svr.pyc"
}


# ===== run =====

wr_log 0 "script start..."

chk_user
#deploy_python
deploy_manage
