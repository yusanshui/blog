### clean files 3 days ago

```shell
find /root/database/backup/db.sql.*.gz -mtime +3 -exec rm {} \;
```

### ssh without affect $HOME/.ssh/known_hosts

```shell
ssh -o "UserKnownHostsFile /dev/null" root@aliyun.geekcity.tech
```

### scp file

```shell
scp -o "UserKnownHostsFile /dev/null" \
    /root/package/centos-base.ova \
    root@<develop_ip>:/root/blackhole/application/flint/build/runtime/download/

```

### rsync file to remote

```shell
rsync -av --delete \
    -e 'ssh -o "UserKnownHostsFile /dev/null" -p 22' \
    --exclude build/ \
    $HOME/git_projects/blog root@aliyun.geekcity.tech:/root/develop/blog
```

### looking for network connections

* all connections
    + ```shell
      lsof -i -P -n
      ```
* specific port
    + ```shell
      lsof -i:8083
      ```

### sync clock

```shell
yum install -y chrony \
    && systemctl enable chronyd \
    && systemctl is-active chronyd \
    && chronyc sources \
    && chronyc tracking \
    && timedatectl set-timezone 'Asia/Shanghai'
```

### settings for screen

```shell
cat > $HOME/.screenrc <<EOF
startup_message off
caption always "%{.bW}%-w%{.rW}%n %t%{-}%+w %=%H %Y/%m/%d "
escape ^Jj #Instead of control-a

shell -$SHELL
EOF
```

### count code lines

```shell
find . -name "*.java" | xargs cat | grep -v ^$ | wc -l
git ls-files | while read f; do git blame --line-porcelain $f | grep '^author '; done | sort -f | uniq -ic | sort -n
git log --author="ben.wangz" --pretty=tformat: --numstat | awk '{ add += $1; subs += $2; loc += $1 - $2 } END { printf "added lines: %s removed lines: %s total lines: %s\n", add, subs, loc }' -
```

### check sha256

```shell
echo "1984c349d5d6b74279402325b6985587d1d32c01695f2946819ce25b638baa0e *ubuntu-20.04.3-preinstalled-server-armhf+raspi.img.xz" | shasum -a 256 --check
```

### check command existence

```shell
if type firewall-cmd > /dev/null 2>&1; then 
    firewall-cmd --permanent --add-port=%s/tcp; 
fi
```

### set hostname

```shell
hostnamectl set-hostname develop
```

### add remote key

```shell
ssh -o "UserKnownHostsFile /dev/null" root@aliyun.geekcity.tech "mkdir -p /root/.ssh && chmod 700 /root/.ssh && echo '$SOME_PUBLIC_KEY' >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys"
```

### generate ssh key

```shell script
ssh-keygen -t rsa -b 4096 -N "" -f E:/projects/greenplum-docker/build/runtime/keys/id_rsa
```


### check service logs with journalctl

```shell
journalctl -u docker
```

### script path

```shell
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
```
### docstounix
```shell script
find /root/blackhole -type f -print0 | xargs -0 dos2unix --
```

### shutdown
```
shutdown -h now
shutdown -h 10
shutdown -h 20:25
init 0
halt
poweroff
```

### reboot
```
reboot 
shutdown -r now
shutdown -r 10
init 6
```

### forget root password  进入紧急模式
```
ro -> rw init=/sysroot/bin/sh
按住 ctrl+x 进入紧急模式
chroot /sysroot # chroot用来切换系统 /sysroot就是原始系统
passwd
LANG=en # 乱码切换
passwd
touch /.autorelabl # 让SELinux生效
按住ctrl+D 输入reboot重启
```

### grup损坏，使用rescue模式
```
使用iso镜像进入
Troubleshooting
Rescue a Centos Linux system
```
### 虚拟机网络模式
```
桥接模式：虚拟机和物理机连一个网络，如手机和计算机连一个wifi
NAT模式：物理机相当于路由器，兼容性好，物理机的网络环境发生变化时，虚拟机的网络不受影响
仅主机模式：相当于一根网线连接物理机和虚拟机
```

### 网卡和地址设置
```
ip add # 查看ip地址
vi /etc/sysconfig/net-scripts/ifcfg-ens33
nmcli c reload ens33
nmcli d reapply ens33
```

### 退出终端
```
exit
ctrl + D
```

### 暂停当前进程
```
ctrl + z
fg # 恢复
```

### swap 作用和大小设置
```
功能就是在内存不够的情况下，操作系统先把内存中暂时不用的数据，存到硬盘的交换空间，腾出内存来让别的程序运行，和Windows的虚拟内存（pagefile.sys）的作用是一样的。
swap 大小为为内存的两倍
```

### 关闭SELinux
```
# 暂时关闭
setenforce 0
# 永久关闭
vi /etc/selinux/config
SELINUX=disabled
重启
```

### 远程登录条件
```
/root/.ssh 权限为700
SELinux 要关闭
/root/.ssh/authorized_keys
yum -y install openssh-clients
ssh-copy-id # 完成密钥认证，下次不要输入密码
```

### 查看当前用户
```
who # 查看所有用户
who am i # 复杂显示
whoami # 正常显示
```

### umask
```
可以在/etc/bashrc 中修改umask的值，root默认022，一般使用者002  0022中第一个零表示八进制
```

### 文件的特殊属性
```
chattr
lsattr
```
