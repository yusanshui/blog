### install kubernetes on metal machine

#### prepare package

[kubectl-kadalu](resources/install/kubectl-kadalu)
[helm](resources/install/helm)
[calico.yaml](resources/install/calico.yaml.md)

1. 在每个节点都运行 [baseInstall.sh](resources/install/baseInstall.sh)
2. 将helm, kubectl-kadalu放到/usr/bin/目录下，calico.yaml放到/tmp/blackhole/k8s/目录下
3. Master 节点
```shell script
    ### Master
    yum -y install python3
    chmod u+x /usr/bin/helm
    chmod u+x /usr/bin/kubectl-kadalu
    
    sed -i -Ee 's/^(ExecStart.*containerd.sock)$/\1 --exec-opt native.cgroupdriver=systemd/'  /usr/lib/systemd/system/docker.service
    systemctl daemon-reload
    systemctl restart docker
    systemctl restart kubelet
    
    rm -f /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-controller-manager.yaml /etc/kubernetes/manifests/kube-scheduler.yaml  /etc/kubernetes/manifests/etcd.yaml
    kubeadm init --kubernetes-version=v1.22.1 --pod-network-cidr=172.21.0.0/20 --image-repository registry.aliyuncs.com/google_containers
    sed -i -Ee "s/^([^#].*--port=0.*)/#\1/g" /etc/kubernetes/manifests/kube-scheduler.yaml
    sed -i -Ee "s/^([^#].*--port=0.*)/#\1/g" /etc/kubernetes/manifests/kube-controller-manager.yaml
    systemctl restart kubelet
    mkdir -p $HOME/.kube
    cp /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl apply -f /tmp/blackhole/k8s/calico.yaml
```
4. 在主节点获取令牌
```
kubeadm token create --print-join-command
```
5. Slave 节点 执行令牌加入集群