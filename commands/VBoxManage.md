### export virtual machine from .ovf file
```shell
VBoxManage export install-service --output packages/install-service/install-service.ovf
```
1、利用ova创建名为develop的虚拟机

VBoxManage import ~/package/centos-base.ova --vsys 0 --vmname develop --settingsfile "$Home/vms/develop/develop.vbox" --cpus 1 --memory 3072

2、设置develop要桥接的网卡, <your interface>为网卡

VBoxManage modifyvm develop --bridgeadapter1 <your interface>

3、查看develop的mac地址及对应的ip

VBoxManage showvminfo develop | grep -i mac

arp-scan -q -l --interface <your interface>

4、启动develop虚拟机

VBoxManage startvm develop --type headless

5、查看有多少台虚拟机

vboxmanage list vms

6、查看虚拟机develop的状态

VBoxManage showvminfo develop | grep -i mac

7、停止虚拟机

VBoxManage controlvm <虚拟机名> acpipowerbutton

8、删除虚拟机

VBoxManage unregistervm --delete <虚拟机名>

9、查看某台虚拟机的snapshot有哪些

vboxmanage snapshot <虚拟机名称> list 

10、给某台虚拟机做快照

vboxmanage snapshot <虚拟机名称> take <快照名称>

11、删除某台虚拟机的快照

vboxmanage snapshot<虚拟机名称> delete <快照名称/快照ID>

12、恢复快照

VBoxManage snapshot <虚拟机名称> restore <快照名称/快照ID>
4、在develop 中安装rsync
yum -y install rsync

5、同步代码到develop
将开发机器上的代码通过WinScp传到host machine的 /projects下，host machine上执行

rsync -e 'ssh -o "UserKnownHostsFile /dev/null"' --delete -av /root/projects/blackhole/ root@<your develop ip>:/root/blackhole/

yum -y install dos2unix

find /root/blackhole -type f -print0 | xargs -0 dos2unix --

将每台虚拟机进行时间上的同步

ssh -o "UserKnownHostsFile /dev/null" root@<虚拟机ip> 'yum -y install ntpdate && ntpdate ntp1.aliyun.com'
