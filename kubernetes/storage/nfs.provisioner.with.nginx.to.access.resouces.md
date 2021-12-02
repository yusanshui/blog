### nfs provisioner with nginx to access resouces

#### prepare

* knowledge about nfs
* k8s cluster
* nfs docker image

#### Usage

1. [create local cluster for testing](../basic/local.cluster.for.testing.md)

2. create nfs4 server
    * ```
      mkdir -p $(pwd)/data/nfs/data
      echo '/data *(rw,fsid=0,no_subtree_check,insecure,no_root_squash)' > $(pwd)/data/nfs/exports
      modprobe nfs && modprobe nfsd
      docker run \
          --name nfs4 \
          --rm \
          --privileged \
          -p 2049:2049 \
          -v $(pwd)/data/nfs/data:/data \
          -v $(pwd)/data/nfs/exports:/etc/exports:ro \
          -d erichough/nfs-server:2.2.1
      ```
      
3. test you nfs4 server
    * ```
      # you may need nfs-utils
      # for centos:
      # yum install nfs-utils
      # for ubuntu:
      # apt-get install nfs-common
      mkdir -p $(pwd)/mnt/nfs \
          && mount -t nfs4 -v localhost:/ $(pwd)/mnt/nfs
      ```

4. install ingress nginx
    * prepare [ingress.nginx.yaml](resources/nfs/ingress.nginx.yaml.md)
    * prepare images
        * ```shell
          for IMAGE in "k8s.gcr.io/ingress-nginx/controller:v1.0.3" \
              "k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.0" \
              "k8s.gcr.io/defaultbackend-amd64:1.5" 
          do
              LOCAL_IMAGE="localhost:5000/$IMAGE"
              docker pull $IMAGE
              docker image tag $IMAGE $LOCAL_IMAGE
              docker push $LOCAL_IMAGE
          done
          ```
    * ```
      ./bin/helm install \
          --create-namespace --namespace basic-components \
          my-ingress-nginx \
          ingress-nginx \
          --version 4.0.5 \
          --repo https://kubernetes.github.io/ingress-nginx \
          --values ingress.nginx.yaml \
          --atomic
      ```

6. use provisioner to provide nfs storage class, `<IP>` is your nfs4 server address, `<path>` is your path exported
     * prepare [nfs.yaml](resources/nfs/nfs.yaml.md)
     * prepare images
         * ```shell
           for IMAGE in "k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2"
           do
               LOCAL_IMAGE="localhost:5000/$IMAGE"
               docker pull $IMAGE
               docker image tag $IMAGE $LOCAL_IMAGE
               docker push $LOCAL_IMAGE
           done
           ```
     * ```
       ./bin/helm install \
           --create-namespace --namespace storage \
           mynfs  nfs-subdir-external-provisioner \
           --set nfs.server=<IP> \
           --set nfs.path=<path> \
           --repo https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ \
           --version 4.0.14 \
           --values nfs.yaml \
           --atomic
       ```
     * you can see nfs-client storage
         ```
         ./bin/kubectl get sc
         ```

5. create pvc
    * [pvc.yaml](resources/nfs/pvc.yaml.md)
    * ```
      ./bin/kubectl get namespace application \
          || ./bin/kubectl create namespace application
      ```
    * see pvc
       + ```
         kubectl get pvc -n nfs
         ```
    * add rescources in the directory
       + ```
         cd /root/data/nfs/data/nfs-nfs-pvc-pvc-e5dd0b8d-5b16-408d-96ec-caac4c3df367
         echo zjvis > yumiao
         ```
      
6. create nginx service to access your resouces under nfs server exported path
    * prepare [nginx.values.yaml](resources/nfs/nginx.values.yaml.md)
    * prepare images
        * ```shell
          for IMAGE in "busybox:latest" \
              "docker.io/bitnami/nginx:1.21.3-debian-10-r29"
          do
              LOCAL_IMAGE="localhost:5000/$IMAGE"
              docker pull $IMAGE
              docker image tag $IMAGE $LOCAL_IMAGE
              docker push $LOCAL_IMAGE
          done
          ```
    * ```
      ./bin/helm install \
          --create-namespace --namespace nfs \
          my-nginx nginx \
          --version 9.5.15 \
          --repo https://charts.bitnami.com/bitnami \
          --values nginx.values.yaml \
          --atomic
      ```
    * then you can access resources 
        + ```
          export POD_NAME=$(./bin/kubectl -n nfs get pod -l "app.kubernetes.io/instance=my-nginx " -o jsonpath="{.items[0].metadata.name}")
          ./bin/kubectl -n nfs exec -it $POD_NAME -c busybox -- sh -c 'echo this is a test > /root/data/file-created-by-busybox'
          curl localhost:8080/resources
          ```