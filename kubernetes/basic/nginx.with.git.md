# nginx with git

## main usage

* Deploying your custom web application

## conceptions

* none

## practise

### pre-requirements

* none

### purpose

* create a kubernetes cluster by kind
* setup nginx
* install nginx service and access your github

### do it

1. create local cluster 
    * [download kubernetes binary tools](../download.kubernetes.binary.tools.md)
    * prepare [kind cluster yaml](resources/kind.cluster.yaml.md)
    * ```shell
      ./kind create cluster --image kindest/node:v1.22.1 --config=kind.cluster.yaml 
      ```
3. install nginx
    * prepare [nginx git values.yaml](resources/nginx.git.values.yaml.md)
    * ```shell
      ./helm install my-release -f values.yaml bitnami/nginx
      ```
4. access your github with nginx service
    + ```shell
      curl localhost:80
      ```
    + expected output is something like
        * ```html
          <!DOCTYPE html>
          <html lang="en">
          <head>
              <meta charset="UTF-8">
              <title>Yumiao's blog</title>
              <meta name="description" content="Description">
              <meta name="viewport"
                    content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
              <link rel="stylesheet" href="offline-docsify/docsify@4.11.4-vue.css">
          </head>
          <body>
          <div id="app"></div>
          </body>
          <script>
              window.$docsify = {
                  name: 'blog',
                  repo: 'https://github.com/yusanshui/blog',
                  loadSidebar: true,
                  subMaxLevel: 3,
                  loadNavbar: true,
                  mergeNavbar: true,
                  auto2top: true,
                  relativePath: true,
                  search: {
                      noData: {
                          '/': 'No results!',
                          '/zh-cn/': '没有结果!',
                      },
                      paths: 'auto',
                      placeholder: {
                          '/': 'Search',
                          '/zh-cn/': '搜索',
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
