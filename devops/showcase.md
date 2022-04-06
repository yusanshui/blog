### showcase

#### prepare

1. prepare devops(my-kafka)
    * ```
      git clone -c http.sslVerify=false --single-branch --branch dev \
          git@git.zjvis.org:bigdata/my-kafka.git /root/git_project/devops-mykafka
      ```

2. prepare to build springboot_build
    * ```
      chmod 744 /root/git_project/devops-mykafka/mvnw
      docker run \
          --name springboot_build \
          --rm \
          -v /root/git_project/devops-mykafka:/devops-mykafka \
          --workdir /devops-mykafka \
          openjdk:8u312-jdk-oraclelinux8 \
          sh -c "/devops-mykafka/mvnw clean package"
      ```
3. prepare to build vue_build
    * modify vue code. `/root/git_project/devops-mykafka/vue-manage-system/vite.config.js`
    * ```
      build: {
          chunkSizeWarningLimit: 1500
      }
      ```
    * ```
      docker run \
          --name vue_build \
          --rm \
          -v /root/git_project/devops-mykafka:/devops-mykafka \
          --workdir /devops-mykafka/vue-manage-system \
          node:14-alpine3.14  \
          sh -c "npm install && npm run build"
      ```

#### build image

1. prepare docker-registry
    * ```
      REGISTRY_NAME="docker-registry"
      running="$(docker inspect -f '{{.State.Running}}' ${REGISTRY_NAME} 2>/dev/null || true)"
      if [ "${running}" != 'true' ]; then
          DOCKER_REGISTRY_IMAGE=registry:2.7.1
          docker inspect $DOCKER_REGISTRY_IMAGE > /dev/null 2>&1 || docker pull $DOCKER_REGISTRY_IMAGE
          docker run --restart=always \
              -p "127.0.0.1:5000:5000" \
              --name "${REGISTRY_NAME}" \
              -d $DOCKER_REGISTRY_IMAGE
      fi
      ```
2. prepare images
    * ```
      for IMAGE in "nginx:1.19.9-alpine" \
          "openjdk:11.0.14.1-jdk-oraclelinux8"
      do
          LOCAL_IMAGE="localhost:5000/$IMAGE"
          docker image inspect $IMAGE || docker pull $IMAGE
          docker image tag $IMAGE $LOCAL_IMAGE
          docker push $LOCAL_IMAGE
      done
      ```
3. prepare devops
    * ```
      git clone --single-branch --branch feature/deploy \
          http://gitea-ops.lab.zjvis.net/libokang/devops.git /root/git_project/devops
      ```
4. prepare env for test
    * Have a jdk-11.0.13 in `/opt/` directory
    * ```
      SPRINGBOOT_PATH="/root/git_project/devops-mykafka/devops-web"
      VUE_PATH="/root/git_project/devops-mykafka/vue-manage-system"
      export JAVA_HOME=/opt/jdk-11.0.13 \
          && export DOCKER_REGISTRY="localhost:5000" \
          && export APPLICATION_VERSION="`date +%s`" \
          && export JAVA_PROJECT_PATH="${SPRINGBOOT_PATH}/target/devops-web-0.0.1-SNAPSHOT.jar" \
          && export NGINX_PROJECT_PATH="${VUE_PATH}/dist" 
      ```
5. prepare to build java_image
    * ```
      cd /root/git_project/devops \
          && chmod 744 gradlew \
          && ./gradlew :cicd:docker:javaRelease
      ```
6. prepare to build nginx_image
    * ```
      cd /root/git_project/devops \
          && chmod 744 gradlew \
          && ./gradlew :cicd:docker:nginxRelease
      ```
7. check images
    * ```
      docker images | grep 'devops.demo'
      ```
      
#### docker run

1. install `springboot` in docker
    * ```
      docker network create --subnet 172.18.0.0/16 devops
      docker run \
          --name demo_springboot \
          --rm \
          --network devops \
          --ip 172.18.0.10 \
          -p 8889:8889 \
          -v ${SPRINGBOOT_PATH}/target/classes/application.yml:/app/application.yaml \
          -d localhost:5000/devops.demo/java-springboot:${APPLICATION_VERSION}
      ```
2. install `vue` in docker
   * prepare `/root/git_project/nginx.conf`
       + ```
         user  nginx;
         worker_processes  auto;
         
         error_log  /var/log/nginx/error.log warn;
         pid        /var/run/nginx.pid;
         
         events {
             worker_connections  1024;
         }
         
         http {
             include       /etc/nginx/mime.types;
             default_type  application/octet-stream;
         
             log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                               '$status $body_bytes_sent "$http_referer" '
                               '"$http_user_agent" "$http_x_forwarded_for"';
         
             access_log  /var/log/nginx/access.log  main;
         
             sendfile        on;
             #tcp_nopush     on;
         
             keepalive_timeout  65;
         
             #gzip  on;
             server {
                 listen       80;
                 server_name  localhost;
                 client_max_body_size 1000m;
         
                 location / {
                     root   /usr/share/nginx/html;
                     try_files $uri $uri/ /index.html;
                 }
                 location ~ ^/api {
                     proxy_connect_timeout 600;
                     proxy_read_timeout 600;
                     proxy_send_timeout 600;
                     send_timeout 600;
                     client_body_timeout 300;
                     rewrite ^/api/(.*) /$1 break;
                     proxy_pass http://172.18.0.10:8889;
                 }
             }
         }
         ```
    * ```
      docker run \
          --name demo_vue \
          --rm \
          --network devops \
          -p 8080:80 \
          -v /root/git_project/nginx.conf:/etc/nginx/nginx.conf \
          -d localhost:5000/devops.demo/nginx-vue:${APPLICATION_VERSION}
      ```

#### test
    * ```
      curl http://localhost:8889/swagger-ui.html#/
      ```
    * ```
      curl http://localhost:8080/api/swagger-ui.html#
      ```