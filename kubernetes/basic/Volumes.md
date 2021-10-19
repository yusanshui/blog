### Volumes
#### [configMap](https://kubernetes.io/docs/concepts/configuration/configmap/)
1. Motivation
    * Use a ConfigMap for setting configuration data separately from application code. 
2. configmap-demo.yaml
    * ```
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: game-demo
      data:
        # 类属性键；每一个键都映射到一个简单的值
        player_initial_lives: "3"
        ui_properties_file_name: "user-interface.properties"
   
        # 类文件键
        game.properties: |
          enemy.types=aliens,monsters
          player.maximum-lives=111111
        user-interface.properties: |
          color.good=purple
          color.bad=yellow
          allow.textmode=true
      ```
    * ```
      kubectl apply -f  configmap-demo.yaml
      ```
3. configmap-demo-pod.yaml
    * ```
      apiVersion: v1
      kind: Pod
      metadata:
        name: configmap-demo-pod
      spec:
        containers:
          - name: demo
            image: k8s.gcr.io/busybox
            command: ["sleep", "3600"]
            env:
              # Define the environment variable
              - name: PLAYER_INITIAL_LIVES # Notice that the case is different 
                      here
                                           # from the key name in the ConfigMap.
                valueFrom:
                  configMapKeyRef:
                    name: game-demo           # The ConfigMap this value comes 
                                                from.
                    key: player_initial_lives # The key to fetch.
              - name: UI_PROPERTIES_FILE_NAME
                valueFrom:
                  configMapKeyRef:
                     name: game-demo
                     key: ui_properties_file_name
            volumeMounts:
              - name: config
                mountPath: "/config"
                readOnly: true
        volumes:
          # You set volumes at the Pod level, then mount them into containers 
          inside that Pod
          - name: config
            configMap:
              # Provide the name of the ConfigMap you want to mount.
              name: game-demo
              # An array of keys from the ConfigMap to create as files
              items:
                - key: "game.properties"
                  path: "game.properties"
                - key: "user-interface.properties"
                  path: "user-interface.properties"
      ```
4.  Get a shell into the Container that is running in your Pod:
    * ```
      kubectl exec -it configmap-demo-pod -- sh
      ```
    * ```
      echo $PLAYER_INITIAL_LIVES
      ```
    * ```
      echo $UI_PROPERTIES_FILE_NAME
      ```
    * ```
      cat /config/game.properties
      ```
    * ```
      cat /config/user-interface.properties
      ```
5. keyPoint
    *  different ways that you can use a ConfigMap to configure a container inside
 a Pod
        + Inside a container command and args
        + Environment variables for a container
        + Add a file in read-only volume, for the application to read
        + Write code to run inside the Pod that uses the Kubernetes API to read a 
          ConfigMap
    * update
        +  ConfigMaps consumed as environment variables are not updated
           automatically and require a pod restart
#### [Downward API](https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/)
1. Motivation
    * Expose Pod Information to Containers Through Files
    * ways to expose Pod and Container fields to a running Container
        + Environment variables
        + Volume Files
    * The Downward API allows containers to consume information about themselves or the cluster without using the 
      Kubernetes client or API server.
2. Store Pod fields 
    1. dapi-volume.yaml
       ``` 
       apiVersion: v1
       kind: Pod
       metadata:
         name: kubernetes-downwardapi-volume-example
         labels:
           zone: us-est-coast
           cluster: test-cluster1
           rack: rack-22
         annotations:
           build: two
           builder: john-doe
       spec:
         containers:
           - name: client-container
             image: k8s.gcr.io/busybox
             command: ["sh", "-c"]
             args:
             - while true; do
                 if [[ -e /etc/podinfo/labels ]]; then
                   echo -en '\n\n'; cat /etc/podinfo/labels; fi;
                 if [[ -e /etc/podinfo/annotations ]]; then
                   echo -en '\n\n'; cat /etc/podinfo/annotations; fi;
                 sleep 5;
               done;
             volumeMounts:
               - name: podinfo
                 mountPath: /etc/podinfo
         volumes:
           - name: podinfo
             downwardAPI:
               items:
                 - path: "labels"
                   fieldRef:
                     fieldPath: metadata.labels
                 - path: "annotations"
                   fieldRef:
                     fieldPath: metadata.annotations
       ```
    2. Create Pod and verify 
        * create pod
            + ```
              kubectl apply -f dapi-volume.yaml
              ```
        * view container logs
            + ```
              kubectl logs kubernetes-downwardapi-volume-example
              ```
        * The output shows the contents of the `labels` file and the `annotations` file: 
            + ```
              cluster="test-cluster1"
              rack="rack-22"
              zone="us-est-coast"
             
              build="two"
              builder="john-doe" 
              ```
        * Get a shell into the Container that is running in your Pod and view the files
            + ```
              kubectl exec -it kubernetes-downwardapi-volume-example -- sh
              ```
            + ```
              cat /etc/podinfo/labels
              ```
            + ```
              cat /etc/podinfo/annotations
              ```
3. Store Container fields 
    1. dapi-volume-resources.yaml
       ```
       apiVersion: v1
       kind: Pod
       metadata:
         name: kubernetes-downwardapi-volume-example-2
       spec:
         containers:
           - name: client-container
             image: k8s.gcr.io/busybox:1.24
             command: ["sh", "-c"]
             args:
             - while true; do
                 echo -en '\n';
                 if [[ -e /etc/podinfo/cpu_limit ]]; then
                   echo -en '\n'; cat /etc/podinfo/cpu_limit; fi;
                 if [[ -e /etc/podinfo/cpu_request ]]; then
                   echo -en '\n'; cat /etc/podinfo/cpu_request; fi;
                 if [[ -e /etc/podinfo/mem_limit ]]; then
                   echo -en '\n'; cat /etc/podinfo/mem_limit; fi;
                 if [[ -e /etc/podinfo/mem_request ]]; then
                   echo -en '\n'; cat /etc/podinfo/mem_request; fi;
                 sleep 5;
               done;
             resources:
               requests:
                 memory: "32Mi"
                 cpu: "125m"
               limits:
                 memory: "64Mi"
                 cpu: "250m"
             volumeMounts:
               - name: podinfo
                 mountPath: /etc/podinfo
         volumes:
           - name: podinfo
             downwardAPI:
               items:
                 - path: "cpu_limit"
                   resourceFieldRef:
                     containerName: client-container
                     resource: limits.cpu
                     divisor: 1m
                 - path: "cpu_request"
                   resourceFieldRef:
                     containerName: client-container
                     resource: requests.cpu
                     divisor: 1m
                 - path: "mem_limit"
                   resourceFieldRef:
                     containerName: client-container
                     resource: limits.memory
                     divisor: 1Mi
                 - path: "mem_request"
                   resourceFieldRef:
                     containerName: client-container
                     resource: requests.memory
                     divisor: 1Mi
       ```
     2. create pod and view files
         * ```
           kubectl apply -f dapi-volume-resources
           ```
         * ```
           kubectl exec -it kubernetes-downwardapi-volume-example-2 -- sh
           ```
         * ```
           cat /etc/podinfo/cpu_limit
           ```
         * ```
           You can use similar commands to view the `cpu_request`, `mem_limit` and `mem_request` files. 
           ```
3. emptyDir
    1. Motivation
        * scratch space, such as for a disk-based merge sort
        * checkpointing a long computation for recovery from crashes
        * holding files that a content-manager container fetches while a webserver container serves 
          the data (类似于容器之间文件共享)
    2. emptyDir.yaml
       ```
       apiVersion: v1
       kind: Pod
       metadata:
         name: test-pd
       spec:
       containers:
       - image: k8s.gcr.io/test-webserver
         name: test-container
         volumeMounts:
       - mountPath: /cache
         name: cache-volume
       volumes:
       - name: cache-volume
         emptyDir: {}
       ```
#### hostPath
1. Motivation
    A hostPath volume mounts a file or directory from the host node's filesystem into your Pod. 
2. hostPath configuration example
    1. hostPath.yaml
       * ```
         apiVersion: v1
         kind: Pod
         metadata:
           name: test-pd
         spec:
           containers:
           - image: k8s.gcr.io/test-webserver
             name: test-container
             volumeMounts:
             - mountPath: /test-pd
               name: test-volume
         volumes:
         - name: test-volume
           hostPath:
             # directory location on host
             path: /data
             # this field is optional
             type: Directory
         ```
    2. type
        * Directory:A directory must exist at the given path 
        * DirectoryOrCreate:If nothing exists at the given path, an empty directory will be created there as needed 
          with permission set to 0755, having the same group and ownership with Kubelet. 
        * File:A file must exist at the given path 
        * FileOrCreate:If nothing exists at the given path, an empty file will be created there as needed with 
          permission set to 0644, having the same group and ownership with Kubelet. 
3. hostPath FileOrCreate configureation example
    1. hostPath-FileOrCreate.yaml
       ```
       apiVersion: v1
       kind: Pod
       metadata:
         name: test-webserver
       spec:
         containers:
         - name: test-webserver
           image: k8s.gcr.io/test-webserver:latest
           volumeMounts:
           - mountPath: /var/local/aaa
             name: mydir
           - mountPath: /var/local/aaa/1.txt
             name: myfile
         volumes:
         - name: mydir
           hostPath:
             # Ensure the file directory is created.
             path: /var/local/aaa
             type: DirectoryOrCreate
         - name: myfile
           hostPath:
             path: /var/local/aaa/1.txt
             type: FileOrCreate
       ```
    2. The `FileOrCreate` mode does not create the parent directory of the file. If the parent directory of the 
       mounted file does not exist, the pod fails to start. To ensure that this mode works, you can try to mount 
       directories and files separately
4. keyPoint
    * 使用Kind创建的k8s集群，主机指的是运行kind-control-panel,目录或者文件路径需要在kind-control-panel container中创建
#### local
1. Motivation
    * Local volumes can only be used as a statically created 
      PersistentVolume. Dynamic provisioning is not supported.
    * Local volumes 可以根据nodeAffinity来选择节点
2. Usage:
    1. local.yaml
        * ```
          apiVersion: v1
          kind: PersistentVolume
          metadata:
            name: example-pv
          spec:
            capacity:
              storage: 10Gi
            volumeMode: Filesystem
            accessModes:
            - ReadWriteOnce
            persistentVolumeReclaimPolicy: Delete
            storageClassName: local-storage
            local:
            path: /mnt/disks/ssd1
            nodeAffinity:
              required:
                nodeSelectorTerms:
                - matchExpressions:
                  - key: kubernetes.io/hostname
                    operator: In
                    values:
                    - kind-control-plane
          ```
    2. local-storageclass.yaml
       ```
       apiVersion: storage.k8s.io/v1
       kind: StorageClass
       metadata:
         name: local-storage
       provisioner: kubernetes.io/no-provisioner
       volumeBindingMode: WaitForFirstConsumer
       ```
    3. local-claim.yaml
       ```
       apiVersion: v1
       kind: PersistentVolumeClaim
       metadata:
         name: local-claim
       spec:
         storageClassName: local-storage
         accessModes:
           - ReadWriteOnce
         resources:
           requests:
             storage: 3Gi
       ```
    4. local-pod.yaml
       ```
       apiVersion: v1
       kind: Pod
       metadata:
         name: local-pod
       spec:
         volumes:
           - name: local-storageclass
             persistentVolumeClaim:
               claimName: local-claim
         containers:
           - name: local-container
             image: nginx
             ports:
               - containerPort: 80
                 name: "http-server"
         volumeMounts:
           - mountPath: "/usr/share/nginx/html"
             name: local-storageclass
       ```
    5. keyPoint
        * 获取节点
            + ```
              kubectl get nodes
              ```
        * 给node添加标签
            + ```
              kubectl label nodes <node-name> <label-key>=<label-value>
              ```
        * 查看当前node具有的标签
            + ```
              kubectl get nodes --show-label
              ```
        * 查看指定node内容
            + ```
              kubectl describe node "nodename"
              ```
        * 查看pod是否分配到了指定node
            + ```
              kubectl get pods -o wide
              ```