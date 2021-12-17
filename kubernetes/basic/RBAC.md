### use kubectl with ServiceAccount

1. create a serviceAccount
    * ```
      kubectl create -f - <<EOF
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: build-robot
      EOF
      ```

2. create service-account-token
    * ```
      kubectl create -f - <<EOF
      apiVersion: v1
      kind: Secret
      metadata:
        name: build-robot-secret
        annotations:
          kubernetes.io/service-account.name: build-robot
      type: kubernetes.io/service-account-token
      EOF
      ```
      
3. create role
    * ```
      # role.yaml
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        namespace: operator
        name: pod-reader
      rules:
      - apiGroups: [""] # "" 标明 core API 组
        resources: ["pods"]
        verbs: ["get", "watch", "list"]
      ```
    * ```
      kubectl apply -f role.yaml
      ```
      
4. create role binding ServiceAccount
    * ```
      # roleBinding.yaml
      apiVersion: rbac.authorization.k8s.io/v1
      # 此角色绑定允许 "jane" 读取 "default" 名字空间中的 Pods
      kind: RoleBinding
      metadata:
        name: read-pods
        namespace: operator
      subjects:
      # 你可以指定不止一个“subject（主体）”
      - kind: ServiceAccount
        name: docs-nginx-operator  # "name" 是区分大小写的
        namespace: operator
      roleRef:
        # "roleRef" 指定与某 Role 或 ClusterRole 的绑定关系
        kind: Role # 此字段必须是 Role 或 ClusterRole
        name: pod-reader     # 此字段必须与你要绑定的 Role 或 ClusterRole 的名称匹配
        apiGroup: rbac.authorization.k8s.io
      ```
    * ```
      kubectl apply -f roleBinding.yaml
      ```
   
5. kubectl config
    * ```
      # kubectl get secret docs-nginx-operator-token-hmr4p -n operator -o yaml |grep ca.crt:|awk '{print $2}' |base64 -d > /root/ca.crt
      # kubectl config set-cluster test-kind --server=https://192.168.123.54:6443 --certificate-authority=/root/ca.crt --embed-certs=true --kubeconfig=/root/test.config
      kubectl config set-cluster test-kind --server=https://192.168.123.54:6443  --kubeconfig=/root/test.config --insecure-skip-tls-verify=true
      token=$(kubectl describe secret docs-nginx-operator-token-hmr4p -n operator | awk '/token:/{print $2}') 
      #如果是get获取需要base64 -d解码 /root/bin/kubectl get  secret docs-nginx-operator-token-hmr4p -n operator -o yaml | awk '/token:/{print $2}' | base64 -d
      kubectl config set-credentials test-admin --token=$token --kubeconfig=/root/test.config
      kubectl config set-context test-admin@test --cluster=test-kind --user=test-admin --kubeconfig=/root/test.config
      kubectl config use-context test-admin@test --kubeconfig=/root/test.config 
      ```
      