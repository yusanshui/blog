### completion for bash

```shell
source<(kubectl completionbash)
```

### port forwarding

```shell
kubectl port-forward --address 0.0.0.0 8080:80 # local:pod
```

### update certs

```shell
kubeadm alpha certs renew all
docker ps | grep -v pause | grep -E "etcd|scheduler|controller|apiserver" | awk '{print $1}' | awk '{print "docker","restart",$1}' | bash
cp /etc/kubernetes/admin.conf ~/.kube/config
```

### get pvc name
```shell script
/root/bin/kubectl get pvc -n graph-analysis -o yaml
export PVC_NAME=$(/root/bin/kubectl get pod -n graph-analysis -l "app.kubernetes.io/instance=graph-analysis-cassandra,app.kubernetes.io/name=cassandra" -o jsonpath="{.items[0].metadata.name}")
```