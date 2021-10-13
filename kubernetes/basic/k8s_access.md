#### 1. External access internal
1. NodePort(kind create cluster --config bin/kind-example-config.yaml)
    * 在kind-example-config.yaml里配置port-mapping，设置host port与containerPort（NodePort）的映射关系
        + ```
          kind: Cluster
          apiVersion: kind.x-k8s.io/v1alpha4
          nodes:
          - role: control-plane
            extraPortMappings:
            - containerPort: 32767
              hostPort: 8080
              listenAddress: "127.0.0.1" # Optional, defaults to "0.0.0.0"
              protocol: tcp # Optional, defaults to tcp                                 
          ```
    * 利用deployment.yaml启动pod，其中containerPort是Pod对外开放的端口，即service 
      中的targetPort
        + ```
           apiVersion: apps/v1
           kind: Deployment
           metadata:
             name: nginx-deployment
             labels:
               app: nginx
           spec:
             replicas: 3
             selector:
               matchLabels:
                 app: nginx
             template:
               metadata:
                 labels:
                   app: nginx
               spec:
                 containers:
                 - name: nginx
                   image: nginx:1.14.2
                   ports:
                   - containerPort: 80
          ```
        + ```
          kubectl apply -f deployment.yaml
          ```
    * 用nginx-svc.yaml来配置service Port与NodePort,Port与TargetPort的映射， 
      TargetPort是Pod对外开放的端口。
        + ```
          apiVersion: v1
          kind: Service
          metadata:
            name: nginx-deployment
            labels:
              app: nginx
          spec:
            type: NodePort
            ports:
            - port: 80
              protocol: TCP
              nodePort: 32767
            selector:
              app: nginx
          ```
        + ```
          kubectl create -f nginx-svc.yaml
          ```
    * 在host主机进行访问,<HostPort>为port-mapping中配置的主机端口号
        + ```
          curl localhost:<HostPort>
          ```
    * 映射关系图
        + ![image](uploads/46bfd6e18bd1103f63e2c916325e178b/image.png)

2. kubectl port-forward
    * command
        + ```
          kubectl port-forward TYPE/NAME [options] [LOCAL_PORT:]REMOTE_PORT 
          [...[LOCAL_PORT_N:]REMOTE_PORT_N]
          ```
    * Usages
        + ```
          kubectl port-forward service/myservice 8443:5000
          ```
        + ```
          kubectl port-forward pod/mypod 8888:5000
          ```
        + ```
          kubectl port-forward deployment/mydeployment 5000 6000
          ```
        + ```
          kubectl port-forward --address 0.0.0.0 pod/mypod 8888:5000
          ```
    * annotation
        + ```
          1. kubectl port-forward是一个block进程，需要重新启动一个会话连接来进行访 
             问，也可以command命令之前添加nohup指令。
          2. --address 可以指定ip，如果参数是0.0.0.0，则可以对所有ip进行转发
          3. type为pod或development时，REMOTE_PORT指的是pod对外开放的端口，type 
             为service时REMOTE_PORT为Service对外暴露的端口
          4. 我们一般采用type为service，因为type为pod，指定的pod失效，port- 
             forward进程会自己终止，sevice类型在replicas>1的情况下，port-forward 
             进程一般可以一直运行。
          5. kubectl port-forward 是在host启动一个使用8888端口的进程，当进程 
             接收到来自某个ip的请求，会判断这个ip是否符合要求，符合则将请求转发到合适的 
             pod的端口。这里的host是指kubectl程序所在的host，而不是集群所在的host， 
             我们的操作都是用kubectl的操作。
          ```
#### 2. Internal access internal 
 * 创建服务
    + ```
      kubectl expose deployment/nginx
      ```
 * 查看服务
    + ```
      kubectl describe svc nginx
      ```
    + ```
      Name:              nginx-deployment
      Namespace:         default
      Labels:            app=nginx
      Annotations:       <none>
      Selector:          app=nginx
      Type:              ClusterIP
      IP Family Policy:  SingleStack
      IP Families:       IPv4
      IP:                10.96.132.28
      IPs:               10.96.132.28
      Port:              <unset>  80/TCP
      TargetPort:        80/TCP
      Endpoints:         10.244.0.5:80,10.244.0.6:80,10.244.0.7:80
      Session Affinity:  None
      Events:            <none>
      ```
    + ```
      type为ClusterIp，说明现在只能从集群内部访问这个服务
      ```
* 访问服务
    + ```
      kubectl run curl --image=radial/busyboxplus:curl -i --tty
      ```
    + ```
      nslookup nginx
      ```
#### 3. Internal access external
* 启动一个curl Pod访问百度
    + ```
      kubectl run curl --image=radial/busyboxplus:curl -i --tty
      ```
    + ```
      curl www.baidu.com
      ```
#### 4. KeyPoint
1. 如果一个application需要调用集群内部资源的话，尽量将application放在集群内部，可以提高传输速度。
2. 物理层的概念：host机器是指kubectl程序所在的机器，k8s集群物理机可以部署再任意位置，Node也是物理层的概念，指的是集群里的每台机器。我们访问k8s集群，不需要关心k8s在物理层的使用，只需要关心逻辑层，比如我们对k8s集群操作，采用的是kubectl命令直接与集群进行交互，没有指定某台物理机的地址，也就是说用户直接与kubectl交互，kubectl与集群交互。但我们之前用的NodePort来访问k8s集群，在kind-example-config是利用docker 容器模拟了物理层配置。