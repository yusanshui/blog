### use kubectl with ServiceAccount

#### create a pod under the specified namespace(operator) but only have read-only access to other resources in the cluster scope

1. create namespace
    * ```
      kubectl get namespace operator \
          || kubectl create namespace operator
      ```
2. create a serviceAccount
    * ```
      kubectl create -f - <<EOF
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: docs-nginx-operator
        namespace: operator
      automountServiceAccountToken: false
      EOF
      ```

3. create role
    * ```
      # role.yaml
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: pod-reader
      rules:
      - apiGroups: [""] # "" 标明 core API 组
        resources: ["pods"]
        verbs: ["get", "watch", "list", "create"]
      ```
    * ```
      kubectl apply -n operator -f role.yaml
      ```
4. create cluster role
    * ```
      kubectl create -f - <<EOF
      apiVersion: rbac.authorization.k8s.io/v1
      kind: ClusterRole
      metadata:
        name: read
      rules:
        - apiGroups: [""]
          resources: ["nodes", "namespaces", "configmaps", "endpoints", "persistentvolumes", "persistentvolumeclaims", "secrets", "services", "pods"]
          verbs: ["get", "list", "watch"]
        - apiGroups: ["apps"]
          resources: ["statefulsets", "replicasets", "deployments", "daemonsets"]
          verbs: ["get", "list", "watch"]
        - apiGroups: ["batch"]
          resources: ["cronjobs", "jobs"]
          verbs: ["get", "list", "watch"]
        - apiGroups: ["storage.k8s.io"]
          resources: ["storageclasses"]
          verbs: ["get", "list", "watch"]
      EOF
      ```
5. create role_binding
    * ```
      # role_binding.yaml
      apiVersion: rbac.authorization.k8s.io/v1
      kind: RoleBinding
      metadata:
        name: read-pods
        namespace: operator
      subjects:
        - kind: ServiceAccount
          name: docs-nginx-operator
          namespace: operator
      roleRef:
        kind: Role
        name: pod-reader
        apiGroup: "rbac.authorization.k8s.io"
      ---
      apiVersion: rbac.authorization.k8s.io/v1
      kind: ClusterRoleBinding
      metadata:
        name: read
        namespace: operator
      subjects:
        - kind: ServiceAccount
          name: docs-nginx-operator
          namespace: operator
      roleRef:
        kind: ClusterRole
        name: read
        apiGroup: "rbac.authorization.k8s.io"
      ```
    * ```
       kubectl apply -n operator -f roleBinding.yaml
      ```
6. kube config
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
7. test
    * failed in namespace default
        + ```
          # test pod yaml
          apiVersion: v1
          kind: Pod
          metadata:
            name: nginx
          spec:
            containers:
            - name: nginx
              image: nginx:1.14.2
              ports:
              - containerPort: 80
          ``` 
        + ```
          kubectl apply -f test.pod.yaml --kubeconfig=/root/test.config
          ```
    * successed in namespace operator
        + ```
          # test pod yaml
          apiVersion: v1
          kind: Pod
          metadata:
            name: nginx
          spec:
            containers:
            - name: nginx
              image: nginx:1.14.2
              ports:
              - containerPort: 80
          ``` 
        + ```
          kubectl -n operator apply -f test.pod.yaml --kubeconfig=/root/test.config
          ```
        + ```
          # get pod in default namespace
          kubectl get pod --kubeconfig=/root/test.config
          ```
      