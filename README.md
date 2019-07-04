1、克隆代码
   ```
   git clone https://github.com/baosong818/Gerrit-Gitlab-Jenkins-SonarQube.git
   ```
2、进入代码目录
   ```
   cd Gerrit-Gitlab-Jenkins-SonarQube
   ```

3、目录结构
   ```
   .
   ├── docker-compose.yaml
   ├── init_devops_system_centos7.sh
   ├── nginx
   │   ├── nginx.conf
   │   └── passwords
   └── README.md
   ```

4、按所需修改docker-compose.yaml
   ```
   vi docker-compose.yaml
   ```


5、运行命令，即可初始化环境
   ```
   ./init_devops_system_centos7.sh
   ```

6、请将初始化时弹出来的两个id_rsa.pub内容复制粘贴到相应系统中，举例以下内容
   ```
   ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDflsu2hgrwKugpmyXrMpIlc7FMUrrvuJmByygTKRZVYpOoznoXJWWZY2sbx2gznDlxom9vGxBdtg9N6RUFqEg14S1tsyC5exWaXM6Mnhfj57l02W9Oamq2x/JpqsPBpaiurCg9PhcVQbm6ljM7MVAK5hl8FjWArd44VXxFKXLoFdmeSkGHUJ6kQCSgIuN/Hi0ZD/BdOnjwevLrypCYxTf+/+ivMoL+Lj7pCJXpc5hF1LLebjzhrLTDDyKC3i1OacsTL86+/h386FmURyS/wZoxxVEY8G0uqm0uBrrGlE/0h5Ht94ssTQUyLvrcgTYSGQAWBEk/7nqAK6PK+rEYIwR9 jenkins@bochtec.com
   ```
   ```
   ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDc78FQEE8j0K77IpdqyZU5rLw6/5cL43gkZqjexXg6Kr8/j8h6gCaX3rciYng9ocEfWSVI93ONEkihcGrb1/8h2AS9reT+dTnAg2ffdXKkoY7sOc5HehRmIlM+w5SSOOUKhBjU+rqKlzyjirDZJ7Sf9MzwtmYWcCd3g8f/S99wFFEcVR9jwVbaox7JTX923QSCtzq7PYTPwRYTjmb4RNn1BsCG6FMBif6JDk1wgVnt1BOQ9CU9mPgA6uxtC9ShX8U7RYytBHerbbNMCtmarfIbNgUW7vcSWPAVnZIAAkT6AadynaqYJrW++8Z5FWNzK+KEz9Bgkr6rACnx1eoEDjy1 gerrit@bochtec.com
   ```

7、nginx目录下有nginx.conf配置文件，还有passwords页面认证密码库
   ```
   passwords:gerrit/gerrit
   ```
 
8、Domain URL
   ```
   http://gitlab.demo.com
   http://jenkins.demo.com
   http://gerrit.demo.com
   http://sonarqube.demo.com
   ```

9、一切docker镜像均采用互联网docker.io中的镜像

10、第一次运行后需要配置gerrit的同步信息，gerrit.config中的canonicalWebUrl信息，需要重启gerrit服务，将同步信息生效，每个项目独立一个remote，并非使用all模式，这样更针对性。

   A、页面初始化gitlab用户密码，登陆，创建bc/test库，首次提交.gitreview文件。将gerrit公钥部署上

   cat .gitreview
   ```
   [gerrit]
   host=gerrit.demo.com
   port=29418
   project=test.git
   ```

   B、页面登陆gerrit，创建test项目，将gerrit公钥部署上

   C、进入docker后重新clone库
   ```
   docker exec -it gerrit /bin/bash
   cd /var/gerrit/review_site/git
   rm -rf test.git
   git clone --bare git@gitlab:/bc/test.git
   ```
   
   D、测试gerrit上传、审核、同步
   ```
   cd /tmp
   git clone "ssh://gerrit@gerrit:29418/test"
   cp -p -P 29418 gerrit@gerrit:hooks/commit-msg "test/.git/hooks/"
   cd test
   touch README.md
   git add .
   git commit -m 'add README.md'
   git review
   ```
   
   E、gerrit同步配置
   
   cat replication.config
   ```
   [remote "test"]
   projects = test
      url = git@gitlab:bc/test.git
      push = +refs/heads/*:refs/heads/*
      push = +refs/tags/*:refs/tags/*
      push = +refs/changes/*:refs/changes/*
      timtout = 30
      threads = 3
   ```

11、后续启动服务
   ```
   docker-compose up -d
   ```

12、创建Gerrit系统的其他用户
   ```
   htpasswd ./nginx/passwords user1
   ```
