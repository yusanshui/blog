#! /bin/bash

set -x
set -e

firewall-cmd --permanent --add-port=179/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=4149/tcp
firewall-cmd --permanent --add-port=4789/udp
firewall-cmd --permanent --add-port=5473/tcp
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=9099/tcp
firewall-cmd --permanent --add-port=10250-10252/tcp
firewall-cmd --permanent --add-port=10255-10256/tcp
firewall-cmd --permanent --add-port=30000-32767/tcp
firewall-cmd --add-masquerade --permanent
firewall-cmd --reload

cat > /etc/modules-load.d/k8s.conf <<EOF
br_netfilter
EOF

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
EOF

yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce docker-ce-cli containerd.io
systemctl enable docker
systemctl start docker

docker pull coredns/coredns:1.8.4
docker tag coredns/coredns:1.8.4 registry.aliyuncs.com/google_containers/coredns:v1.8.4

sysctl --system
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sed -i -Ee 's/^(.*swap.*)$/#\1/' /etc/fstab
swapoff -a

systemctl enable kubelet
systemctl start kubelet

sed -i -Ee 's/^(ExecStart.*containerd.sock)$/\1 --exec-opt native.cgroupdriver=systemd/'  /usr/lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart docker
systemctl restart kubelet

yum -y install python3
chmod u+x /usr/bin/helm
chmod u+x /usr/bin/kubectl-kadalu

rm -f /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-controller-manager.yaml /etc/kubernetes/manifests/kube-scheduler.yaml  /etc/kubernetes/manifests/etcd.yaml
kubeadm init --kubernetes-version=v1.22.1 --pod-network-cidr=172.21.0.0/20 --image-repository registry.aliyuncs.com/google_containers
sed -i -Ee "s/^([^#].*--port=0.*)/#\1/g" /etc/kubernetes/manifests/kube-scheduler.yaml
sed -i -Ee "s/^([^#].*--port=0.*)/#\1/g" /etc/kubernetes/manifests/kube-controller-manager.yaml
systemctl restart kubelet
mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f /tmp/blackhole/k8s/calico.yaml