#!/bin/bash
rpm -ivh https://mirrors.ustc.edu.cn/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm 
yum install -y expect httpd-tools

curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

yum install -y docker
systemctl enable docker
systemctl start docker

echo "vm.max_map_count = 655360" >> /etc/sysctl.conf

echo `pwd`
docker-compose down

#清空目录
mkdir gerrit gitlab jenkins mysql
chown 1000:1000 ./*

#创建jenkins用户的公钥、秘钥
rm -rf `pwd`/jenkins/.ssh

cat > ./build_key.exp <<EOF
#!/usr/bin/expect
set timeout 5

spawn ssh-keygen -t rsa -C jenkins@bochtec.com
expect "*(/root/.ssh/id_rsa):"
send "`pwd`/jenkins/.ssh/id_rsa\r"
expect "*(empty for no passphrase):"
send "\r"
expect "*passphrase again:"
send "\r"
expect eof

EOF

chmod +x ./build_key.exp

if [ ! -d "`pwd`/jenkins/.ssh" ];then
    mkdir `pwd`/jenkins/.ssh
    chmod 700 `pwd`/jenkins/.ssh
fi

./build_key.exp
chown 1000:1000 -R `pwd`/jenkins/.ssh

J_RSA_DIR="`pwd`/jenkins/.ssh/id_rsa.pub"
J_RSA_PUB=`cat ${J_RSA_DIR}`

#创建gerrit用户的公钥、秘钥
rm -rf `pwd`/gerrit/.ssh

cat > ./build_key.exp <<EOF
#!/usr/bin/expect
set timeout 5

spawn ssh-keygen -t rsa -C gerrit@bochtec.com
expect "*(/root/.ssh/id_rsa):"
send "`pwd`/gerrit/.ssh/id_rsa\r"
expect "*(empty for no passphrase):"
send "\r"
expect "*passphrase again:"
send "\r"
expect eof

EOF

chmod +x ./build_key.exp

if [ ! -d "`pwd`/gerrit/.ssh" ];then
    mkdir `pwd`/gerrit/.ssh
    chmod 700 `pwd`/gerrit/.ssh
fi

./build_key.exp
chown 1000:1000 -R `pwd`/gerrit/.ssh

G_RSA_DIR="`pwd`/gerrit/.ssh/id_rsa.pub"
G_RSA_PUB=`cat ${G_RSA_DIR}`

#使用docker-compose命令启动服务镜像
docker-compose up -d

rm -f ./build_key.exp

cat > gerrit/.ssh/config << EOF
Host gitlab
    User git
    IdentityFile /var/gerrit/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
chmod 600 gerrit/.ssh/config
chown 1000:1000 gerrit/.ssh/config

cat > ./gerrit_ssh_known.exp <<EOF
#!/usr/bin/expect
set timeout 5

spawn docker exec -it gerrit /bin/bash
expect "bash-4.4# "
send "ssh-keyscan -t rsa gitlab > /var/gerrit/.ssh/known_hosts\r"
expect "bash-4.4# "
send "chmod 600 /var/gerrit/.ssh/known_hosts\r"
expect "bash-4.4# "
send "mkdir /root/.ssh\r"
expect "bash-4.4# "
send "chmod 700 /root/.ssh\r"
expect "bash-4.4# "
send "/bin/cp /var/gerrit/.ssh/id_rsa /root/.ssh/\r"
expect eof

EOF

chmod +x ./gerrit_ssh_known.exp
./gerrit_ssh_known.exp
sleep 5
rm -f ./gerrit_ssh_known.exp

cat > gerrit/review_site/etc/replication.config << EOF
[remote "test"]
        projects = test
        url = git@gitlab:bc/test.git        
        push = +refs/heads/*:refs/heads/*
        push = +refs/tags/*:refs/tags/*
        push = +refs/changes/*:refs/changes/*
        timtout = 30
        threads = 3
EOF

chown 1000:1000 gerrit/review_site/etc/replication.config

echo ' '
echo ' '
echo ' '
echo -e "\033[41;37m需要将以下jenkins用户的id_rsa.pub内容粘贴到gitlab、gerrit的公钥框中\033[0m"
echo -e "\033[41;37m${J_RSA_PUB}\033[0m"
echo ' '
echo ' '
echo -e "\033[42;34m需要将以下gerrit用户的id_rsa.pub内容粘贴到gitlab的公钥框中\033[0m"
echo -e "\033[42;34m${G_RSA_PUB}\033[0m"
