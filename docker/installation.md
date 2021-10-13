## docker installation

### install with CentOS 8

* ```shell
  cat > /etc/yum.repos.d/docker-ce.repo <<EOF
  [docker-ce-stable]
  name=Docker CE Stable - $basearch
  baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/\$releasever/\$basearch/stable
  enabled=1
  gpgcheck=1
  gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
  EOF
  dnf install -y yum-utils device-mapper-persistent-data lvm2 docker-ce \
      && systemctl enable docker \
      && systemctl start docker
  ```

### install with Ubuntu 20.04.2 LTS (x86_64)

* ```shell
  apt-get install apt-transport-https ca-certificates curl gnupg lsb-release
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo \
      "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get install docker-ce docker-ce-cli containerd.io
  ```
* reference to https://docs.docker.com/engine/install/ubuntu/ for other arch

### install docker Desktop with mac

* reference to https://www.docker.com/products/docker-desktop for mac

### install docker Desktop with windows
### windows
1. install docker desktop for windows
    * 下载docker-desktop.exe for windows https://docs.docker.com/docker-for-windows/install/
2. 启用Hyper-V功能
    * 启用或禁止windows功能中选中Hyper-V功能
    * windows 10 家庭版需要安装Hyper-V，参考 https://zhuanlan.zhihu.com/p/51939654
        1. 在记事本上添加以下代码
            * ```
              pushd "%~dp0"
              dir /b %SystemRoot%\servicing\Packages\*Hyper-V*.mum >hyper-v.txt
              for /f %%i in ('findstr /i . hyper-v.txt 2^>nul') do dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i"
              del hyper-v.txt
              Dism /online /enable-feature /featurename:Microsoft-Hyper-V-All /LimitAccess /ALL
              ```
        2. 把文件保存为Hyper-V.cmd
        3. 右键该文件以管理员身份运行
        4. 启用Hyper-V功能
        5. 采用命令行形式操作Hyper-V，比较彻底
            * ```
              bcdedit /set hypervisorlaunchtype auto
              ```
            * ```
              bcdedit /set hypervisorlaunchtype off
              ```
3. Verify that the installation is successful
   * ```
     docker run hello-world
     ```
   * ```
     Hello from Docker!
     ```
* reference to https://docs.docker.com/desktop/windows/install/ for windows
