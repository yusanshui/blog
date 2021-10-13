1. 启动kind
    1. kind.cluster.yaml
       ```   
       kind: Cluster
       apiVersion: kind.x-k8s.io/v1alpha4
       featureGates:
         "RemoveSelfLink": false
       ```
    2. kind-linux-amd64 create cluster --config kind.cluster.yaml
2. nfs-client-provisioner.yaml 
   ```
   kind: Deployment
   apiVersion: apps/v1
   metadata:
     name: nfs-client-provisioner
     namespace: kube-system
   spec:
     replicas: 1
     strategy:
       type: Recreate
     selector:
       matchLabels:
         app: nfs-client-provisioner
     template:
       metadata:
         labels:
           app: nfs-client-provisioner
       spec:
         serviceAccountName: nfs-client-provisioner
         containers:
           - name: nfs-client-provisioner
             image: quay.io/external_storage/nfs-client-provisioner:latest
             volumeMounts:
               - name: nfs-client-root
                 mountPath: /persistentvolumes
             env:
               - name: PROVISIONER_NAME
                 value: mynfs                 # 根据自己的名称来修改，与 
                             storageclass.yaml 中的 provisioner 名字一致
               - name: NFS_SERVER
                 value: 192.168.123.54        # NFS服务器所在的 ip
               - name: NFS_PATH
                 value: /nfs                  # 共享存储目录
         volumes:
           - name: nfs-client-root
             nfs:
               server: 192.168.123.54         # NFS服务器所在的 ip
               path: /nfs                     # 共享存储目录
   ```
3. rbac.yaml
   ```
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: nfs-client-provisioner
     # replace with namespace where provisioner is deployed
     namespace: kube-system
   ---
   kind: ClusterRole
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: nfs-client-provisioner-runner
   rules:
     - apiGroups: [""]
       resources: ["persistentvolumes"]
       verbs: ["get", "list", "watch", "create", "delete"]
     - apiGroups: [""]
       resources: ["persistentvolumeclaims"]
       verbs: ["get", "list", "watch", "update"]
     - apiGroups: ["storage.k8s.io"]
       resources: ["storageclasses"]
       verbs: ["get", "list", "watch"]
     - apiGroups: [""]
       resources: ["events"]
       verbs: ["create", "update", "patch"]
   ---
   kind: ClusterRoleBinding
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: run-nfs-client-provisioner
   subjects:
     - kind: ServiceAccount
       name: nfs-client-provisioner
       # replace with namespace where provisioner is deployed
       namespace: kube-system
   roleRef:
     kind: ClusterRole
     name: nfs-client-provisioner-runner
     apiGroup: rbac.authorization.k8s.io
   ---
   kind: Role
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: leader-locking-nfs-client-provisioner
     # replace with namespace where provisioner is deployed
     namespace: kube-system
   rules:
     - apiGroups: [""]
       resources: ["endpoints"]
       verbs: ["get", "list", "watch", "create", "update", "patch"]
   ---
   kind: RoleBinding
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: leader-locking-nfs-client-provisioner
     # replace with namespace where provisioner is deployed
     namespace: kube-system
   subjects:
     - kind: ServiceAccount
       name: nfs-client-provisioner
       # replace with namespace where provisioner is deployed
       namespace: kube-system
   roleRef:
     kind: Role
     name: leader-locking-nfs-client-provisioner
     apiGroup: rbac.authorization.k8s.io
   ```
4. storageclass.yaml 
   ```
   apiVersion: storage.k8s.io/v1
   kind: StorageClass
   metadata:
     name: nfs
   provisioner: mynfs
   ```
5. test-pods.yaml
   ```
   kind: PersistentVolumeClaim
   apiVersion: v1
   metadata:
     name: test-claim
     annotations:
       volume.beta.kubernetes.io/storage-class: "nfs" # 与 storageclass.yaml 中的 
                                                      name 一致
   spec:
     accessModes:
       - ReadWriteMany
     resources:
       requests:
         storage: 1Mi

   ---

   kind: Pod
   apiVersion: v1
   metadata:
     name: test-pod
   spec:
     containers:
     - name: test-pod
       image: busybox:1.24
       command:
         - "/bin/sh"
       args:
         - "-c"
         - "touch /mnt/SUCCESS && exit 0 || exit 1"
       volumeMounts:
         - name: nfs-pvc
           mountPath: "/mnt"
     restartPolicy: "Never"
     volumes:
       - name: nfs-pvc
         persistentVolumeClaim:
           claimName: test-claim
   ```
