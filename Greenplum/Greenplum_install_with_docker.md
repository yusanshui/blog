#### 1. 配置slave节点
1. 创建network
* ```
  docker network create my-net
  ``` 
2. 启动两个slave节点 slave01，slave02
* ```
  docker run --rm -tdi --privileged --network my-net --name slave01 -d centos:centos7.9.2009 init sleep 3d
  ```
3. 进入slave容器内部
* ```
  winpty docker exec -it  slave01 bash
  ```
4. 安装及下载软件
* ```
  yum -y install vim
  yum -y install wget
  yum -y install openssh-server openssh-clients
  yum -y install java-1.8.0-openjdk
  yum -y install net-tools
  ```
5. 启动sshd服务
* ```
  systemctl start sshd
  ```
6. 创建gpadmin用户和用户组
* ```
  groupadd gpadmin
  useradd  gpadmin -g gpadmin -d /home/gpadmin
  echo "gpadmin" | passwd --stdin gpadmin
  ```
7. 配置内核参数
* ```
  vim /etc/sysctl.conf
  ```
* ```
  kernel.pid_max = 65536
  kernel.shmmax = 500000000
  kernel.shmmni = 4096
  kernel.shmall = 4000000000
  kernel.sem = 250 512000 100 2048
  kernel.sysrq = 1
  kernel.core_uses_pid = 1
  kernel.msgmnb = 65536
  kernel.msgmax = 65536
  kernel.msgmni = 2048
  net.ipv4.tcp_syncookies = 1
  net.ipv4.conf.default.accept_source_route = 0
  net.ipv4.tcp_tw_recycle = 1
  net.ipv4.tcp_max_syn_backlog = 4096
  net.ipv4.conf.all.arp_filter = 1
  net.ipv4.ip_local_port_range = 10000 65535
  net.core.somaxconn=1024
  net.core.netdev_max_backlog = 10000
  net.core.rmem_max = 2097152
  net.core.wmem_max = 2097152

  vm.dirty_background_ratio = 0
  vm.dirty_ratio = 0
  vm.dirty_background_bytes = 1610612736 # 1.5GB
  vm.dirty_bytes = 4294967296 # 4GB
  vm.swappiness = 10
  vm.overcommit_memory = 2
  vm.overcommit_ratio = 95
  ```
* ```
  sysctl -p
  ```
8. 修改limit.config,新增内容
* ```
  vim /etc/security/limits.conf
  ```
* ```
  *soft nofile 524288
  *hard nofile 524288
  *soft nproc 131072
  *hard nproc 131072
  ```
9. 下载并安装GreePlum
* ```
  wget https://github.com/greenplum-db/gpdb/releases/download/6.8.1/greenplum-db-6.8.1-rhel7-x86_64.rpm
  yum -y install  greenplum-db-6.8.1-rhel7-x86_64.rpm
  ```
10. 授权gpadmin
* ```
  chown -R gpadmin:gpadmin  /usr/local/greenplum*
  ```
11. 使环境变量生效
* ```
  source /usr/local/greenplum-db/greenplum_path.sh
  ```
12. 创建instance需要的目录
* ```
  mkdir -p /opt/greenplum/data/primary
  ```
* ```
  chown -R gpadmin:gpadmin /opt/greenplum
  ```
#### 2. 配置Master节点
1. 运行master节点，--add-host slave01name:slave01IP --add-host slave02name:slave02IP
* ```
   docker run --rm -tdi --privileged --network my-net --name master -d centos:centos7.9.2009 init sleep 3d --add-host b8be789cb6fb:172.20.0.2 --add-host a0cc62c478ab:172.20.0.3
  ```
2. 进入master容器内部
* ```
  winpty docker exec -it  master bash
  ```
4. 安装及下载软件
* ```
  yum -y install vim
  yum -y install wget
  yum -y install openssh-sever openssh-clients
  yum -y install java-1.8.0-openjdk
  yum -y install net-tools
  ```
5. 启动sshd服务
* ```
  systemctl start sshd
  ```
6. 创建gpadmin用户和用户组
* ```
  groupadd gpadmin
  useradd  gpadmin -g gpadmin -d /home/gpadmin
  echo "gpadmin" | passwd --stdin gpadmin
  ```
7. 配置内核参数
* ```
  vim /etc/sysctl.conf
  ```
* ```
  kernel.pid_max = 65536
  kernel.shmmax = 500000000
  kernel.shmmni = 4096
  kernel.shmall = 4000000000
  kernel.sem = 250 512000 100 2048
  kernel.sysrq = 1
  kernel.core_uses_pid = 1
  kernel.msgmnb = 65536
  kernel.msgmax = 65536
  kernel.msgmni = 2048
  net.ipv4.tcp_syncookies = 1
  net.ipv4.conf.default.accept_source_route = 0
  net.ipv4.tcp_tw_recycle = 1
  net.ipv4.tcp_max_syn_backlog = 4096
  net.ipv4.conf.all.arp_filter = 1
  net.ipv4.ip_local_port_range = 10000 65535
  net.core.somaxconn=1024
  net.core.netdev_max_backlog = 10000
  net.core.rmem_max = 2097152
  net.core.wmem_max = 2097152

  vm.dirty_background_ratio = 0
  vm.dirty_ratio = 0
  vm.dirty_background_bytes = 1610612736 # 1.5GB
  vm.dirty_bytes = 4294967296 # 4GB
  vm.swappiness = 10
  vm.overcommit_memory = 2
  vm.overcommit_ratio = 95
  ```
* ```
  sysctl -p
  ```
8. 修改limit.config,新增内容
* ```
  vim /etc/security/limits.conf
  ```
* ```
  *soft nofile 524288
  *hard nofile 524288
  *soft nproc 131072
  *hard nproc 131072
  ```
9. 下载并安装GreePlum
* ```
  wget https://github.com/greenplum-db/gpdb/releases/download/6.8.1/greenplum-db-6.8.1-rhel7-x86_64.rpm
  yum -y install  greenplum-db-6.8.1-rhel7-x86_64.rpm
  ```
10. 授权gpadmin
* ```
  chown -R gpadmin:gpadmin  /usr/local/greenplum*
  ```
11. 使环境变量生效
* ```
  source /usr/local/greenplum-db/greenplum_path.sh
  ```
12. 创建instance需要的目录
* ```
  mkdir -p /opt/greenplum/data/master
  ```
* ```
  chown -R gpadmin:gpadmin /opt/greenplum
  ```
13. 切换到gpadmin用户，在gpadmin目录下创建bash_profile（接下来的操作都是使用gpadmin用户）
* ```
  su gpadmin
  vim bash_profile
  ```
* ```
  export PS1='[\u@\h \w]'
  ```
* ```
  source bash_porfile
  ```
14. 修改/home/gpadmin/.bash_profile，添加新内容
* ```
  vim /home/gpadmin/.bash_profile
  ```
* ```
  source /usr/local/greenplum-db-6.8.1/greenplum_path.sh
  export MASTER_DATA_DIRECTORY=/opt/greenplum/data/master/gpseg-1
  export PGPORT=5432
  export PGUSER=gpadmin
  export PGDATABASE=gpdb
  ```
* ```
  source /home/gpadmin/.bash_profile
  ```
15. 修改/home/gpadmin/.bashrc，添加新内容
* ```
  vim /home/gpadmin/.bashrc
  ```
* ```
  source /usr/local/greenplum-db-6.8.1/greenplum_path.sh
  export MASTER_DATA_DIRECTORY=/opt/greenplum/data/master/gpseg-1
  export PGPORT=5432
  export PGUSER=gpadmin
  export PGDATABASE=gpdb
  ```
* ```
  source /home/gpadmin/.bashrc
  ```
15. 在gpadmin目录下，添加hostlist文件，master表示主机名，slave01表示slave01的主机名，slave02表示slave02的主机名
* ```
  vim hostlist
  ```
* ```
  master
  slave01
  slave02
  ```
16. 在gpadmin目录下，添加seg_hosts文件,slave01表示slave01的主机名，slave02表示slave02的主机名
* ```
  vim seg_hosts
  ```
* ```
  slave01
  slave02
  ```
17. 权限互通，sever分别用slave01,slave02的主机名替代
* 生成公钥私钥对
* ```
  ssh-keygen
  ```
* 按三次回车
* ```
  ssh-copy-id -i ~/.ssh/id_rsa.pub gpadmin@server
  ```
18. 使用gpssh-exkeys验证
* ```
  gpssh-exkeys -f hostlist
  ```
19. 编辑gp初始化文件，masterName为master主机名
* ```
  vim initgp_config
  ```
* ```
  SEG_PREFIX=gpseg
  PORT_BASE=33000
  declare -a DATA_DIRECTORY=(/opt/greenplum/data/primary /opt/greenplum/data/primary)
  MASTER_HOSTNAME=masterName
  MASTER_PORT=5432
  MASTER_DIRECTORY=/opt/greenplum/data/master
  DATABASE_NAME=gpdb
  ```
20. 初始化gp
* ```
  gpinitsystem -c initgp_config -h seg_hosts
  ```
#### 3. gp的使用
1. gp常用命令
* ```
  gpstate #查看gp的状态
  gpstart #正常启动
  gpstop #正常关闭
  gpstop –r #重启
  ```