1. nfs
    1. /etc/export
        * /ifs/kubernetes  *(rw,sync,no_root_squash)
    2. exportfs -a
2. deployment.yaml 
   ```
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nfs-client-provisioner
     labels:
       app: nfs-client-provisioner
     # replace with namespace where provisioner is deployed
     namespace: default
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
             image: k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
             volumeMounts:
               - name: nfs-client-root
                 mountPath: /persistentvolumes
             env:
               - name: PROVISIONER_NAME
                 value: k8s-sigs.io/nfs-subdir-external-provisioner
               - name: NFS_SERVER
                 value: 192.168.123.54
               - name: NFS_PATH
                 value: /ifs/kubernetes
         volumes:
           - name: nfs-client-root
             nfs:
               server: 192.168.123.54
               path: /ifs/kubernetes
   ``` 
3. rbac.yaml
   ```
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: nfs-client-provisioner
     # replace with namespace where provisioner is deployed
     namespace: default
   ---
   kind: ClusterRole
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: nfs-client-provisioner-runner
   rules:
     - apiGroups: [""]
       resources: ["nodes"]
       verbs: ["get", "list", "watch"]
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
       namespace: default
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
     namespace: default
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
     namespace: default
   subjects:
     - kind: ServiceAccount
       name: nfs-client-provisioner
       # replace with namespace where provisioner is deployed
       namespace: default
   roleRef:
     kind: Role
     name: leader-locking-nfs-client-provisioner
     apiGroup: rbac.authorization.k8s.io
   ```
4. class.yaml
   ```
   apiVersion: storage.k8s.io/v1
   kind: StorageClass
   metadata:
     name: managed-nfs-storage
   provisioner: k8s-sigs.io/nfs-subdir-external-provisioner # or choose another 
               name, must match deployment's env PROVISIONER_NAME'
   parameters:
     archiveOnDelete: "false"
   ```
5. test-claim.yaml
   ```
   kind: PersistentVolumeClaim
   apiVersion: v1
   metadata:
     name: test-claim
   spec:
     storageClassName: managed-nfs-storage
     accessModes:
       - ReadWriteMany
     resources:
       requests:
         storage: 1Mi
   ```
6. test-pod.yaml
   ```
   kind: Pod
   apiVersion: v1
   metadata:
     name: test-pod
   spec:
     containers:
     - name: test-pod
       image: busybox:stable
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