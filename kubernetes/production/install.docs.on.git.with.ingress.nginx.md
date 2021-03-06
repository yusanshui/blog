# install docs on git with ingress nginx

## main usage

* Deploying your custom web application

## conceptions

* none

## practise

### pre-requirements

* access docs on git with SSH
* known-hosts

### purpose

* create a kubernetes cluster by kind
* install ingress nginx service and pull your docs from git periodically

### do it

1. [create local cluster for testing](../basic/local.cluster.for.testing.md)
2. create ssh-key-secret
    * if you do not hava SSH Key Pair, you could use `ssh-keygen -t rsa` to get it.
        + ```
           mkdir -p ssh-keys/ \
               && ssh-keygen -t rsa -b 4096 -N "" -f ssh-keys/id_rsa
           kubectl create secret generic git-ssh-key-secret --from-file=ssh-keys/
          ```
    * generate ssh-key-secret, `/path/to/.ssh/id_rsa` and `/path/to/.ssh/id_rsa.pub` are your private key path and public key path 
        + ```shell
          ./kubectl create namespace test --dry-run=client -o yaml | kubectl apply -f -
          ./kubectl -n test create secret generic nebula-ce-privatekey-secret --from-file=ssh-privatekey=/path/to/.ssh/id_rsa
          ```
4. install ingress nginx
    * prepare [ingress.nginx.values.yaml](../basic/resources/ingress.nginx.values.yaml.md)
        * prepare images
            + ```shell
              for IMAGE in "k8s.gcr.io/ingress-nginx/controller:v1.0.3" "k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.0"
              do
                  LOCAL_IMAGE="localhost:5000/$IMAGE"
                  docker pull $IMAGE
                  docker image tag $IMAGE $LOCAL_IMAGE
                  docker push $LOCAL_IMAGE
              done
              ```
        * ```shell
          ./bin/helm install \
              --create-namespace --namespace basic-components \
              my-ingress-nginx \
              ingress-nginx \
              --version 4.0.5 \
              --repo https://kubernetes.github.io/ingress-nginx \
              --values $(pwd)/ingress.nginx.values.yaml \
              --atomic
          ```
3. install nginx service
    * prepare [nginx.access.docs.values.yaml](resources/nginx.access.docs.values.yaml.md)
    * prepare images
        + ```shell
          for IMAGE in "docker.io/bitnami/nginx:1.21.3-debian-10-r29" "docker.io/bitnami/git:2.33.0-debian-10-r53"
          do
              LOCAL_IMAGE="localhost:5000/$IMAGE"
              docker pull $IMAGE
              docker image tag $IMAGE $LOCAL_IMAGE
              docker push $LOCAL_IMAGE
          done
          ```
    * ```shell
      ./bin/helm install \
           --create-namespace --namespace test \
          my-nginx \
          nginx \
          --version 9.5.7 \
          --repo https://charts.bitnami.com/bitnami \
          --values $(pwd)/nginx.access.docs.values.yaml \
          --atomic
      ```
4. access docs with ingress nginx service
    + ```shell
      curl --header 'Host: my.nginx.tech' http://localhost/my-nginx-prefix/docs/
      ```
    + expected output is something like
        * ```html
          <!DOCTYPE html>
          <html lang="en">
          <head>
              <meta charset="UTF-8">
              <title>????????????</title>
              <meta name="description" content="Description">
              <meta name="viewport"
                    content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
              <link rel="stylesheet" href="offline-docsify/docsify@4.11.4-vue.css">
              <link rel="stylesheet" href="./index.css" type="text/css" >
          </head>
          <body>
          <div id="app"></div>
          <div><a href="https://beian.miit.gov.cn/">???ICP???2021024222???</a></div>
          </body>
          <script>
              window.$docsify = {
                  name: '????????????',
                  repo: 'https://github.com/ZJLabDubhe/nebula',
                  loadSidebar: true,
                  subMaxLevel: 3,
                  loadNavbar: true,
                  mergeNavbar: true,
                  auto2top: true,
                  relativePath: true,
                  search: {
                      noData: {
                          '/': 'No results!',
                          '/zh-cn/': '????????????!',
                      },
                      paths: 'auto',
                      placeholder: {
                          '/': 'Search',
                          '/zh-cn/': '??????',
                      }
                  },
              }
          </script>
          <script src="offline-docsify/docsify@4.11.4"></script>
          <script src="offline-docsify/search.min.js"></script>
          <script src="offline-docsify/zoom-image.min.js"></script>
          <script src="offline-docsify/prism-markdown.min.js"></script>
          <script src="offline-docsify/prism-bash.min.js"></script>
          <script src="offline-docsify/prism-ruby.min.js"></script>
          <script src="offline-docsify/prism-yaml.min.js"></script>
          <script src="offline-docsify/prism-less.min.js"></script>
          </html>
          ```
5. NOTES
    * `inginx` use `NodePort` as serviceType, whose nodePorts contains 32080(http) and 32443(https)
    * 32080(http) and 32443(https) mapped to 80 and 443 at localhost(the host machine of kind cluster) by kind
      configuration
    * therefore, access localhost:80 is equal to accessing `nginx` service
