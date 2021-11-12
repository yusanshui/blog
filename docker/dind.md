### docker in docker

reference: https://github.com/jpetazzo/dind

#### use centos8 image to create docker in docker 

#### use docker container


1. run centos8 cotainer

    * ```shell script
      docker run --rm -d --name dind-test centos:centos8.3.2011 bash -c "sleep 3d"
      ```

2. enter shell

    * ```
      docker exec -it dind-test bash
      ```

3. Install the magic wraper.
    
    * [/var/local/bin/wrapdocker](resources/wrapdocker.md)
    * ```
      chmod +x /usr/local/bin/wrapdocker
      ```

4. Install Docker and dependencies

    * ```shell script
      cat > /etc/yum.repos.d/docker-ce.repo <<EOF
      [docker-ce-stable]
      name=Docker CE Stable - $basearch
      baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/\$releasever/\$basearch/stable
      enabled=1
      gpgcheck=1
      gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
      EOF
      dnf install -y yum-utils device-mapper-persistent-data lvm2 docker-ce
      ```
5. Define additional metadata for our image.

   * ```
     mkdir /var/lib/docker
     ```

6. run wrapdocker script
   
   * ```
     /usr/local/bin/wrapdocker
     ```

#### dockerfile

```shell script
FROM alpine:3.3
MAINTAINER yusanshui1234@gmail.com

# Install the magic wrapper.
ADD ./wrapdocker /usr/local/bin/wrapdocker

# Install Docker and dependencies
RUN apk --update add \
  bash \
  iptables \
  ca-certificates \
  e2fsprogs \
  docker \
  && chmod +x /usr/local/bin/wrapdocker \
  && rm -rf /var/cache/apk/*

# Define additional metadata for our image.
VOLUME /var/lib/docker
CMD ["wrapdocker"]
```
