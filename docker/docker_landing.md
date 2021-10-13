1. ### quick start

   * play with windows

     1. [安装docker](/docker_installation)

     2. 在git bash里使用

        + ```
          docker run hello-world
          ```

     3. 检查输出结果判断docker 是否能正常使用

        + 输出含有 "Hello from Docker!" 等字样

   ### get hand dirty

   1. 查看本地已有镜像

      * ```
        docker images
        ```

   2. 拉取（下载）镜像到本地

      * Usage: docker pull [OPTIONS] NAME[:TAG|@DIGEST]

      * ```
        docker pull busybox
        ```

      * ```
        docker pull busybox:1.33.1-glibc
        ```

   3. 利用容器运行镜像

      * Usage:  docker run [OPTIONS] IMAGE [COMMAND] [ARG...]

      * ```
        docker run --rm busybox:1.33.1-glibc echo "hello from busybox"
        ```

      * 上面的命令

        1. 使用 busybox:1.33.1-glibc 这个镜像，启动了一个容器
        2. 在这个容器中启动了一个进程 ``` echo "hello from busybox" ```
        3. --rm 能够让这个容器执行结束（fail 或 complete）后销毁
        4. 一定要养成习惯，尽量使用带版本号的镜像；如果你觉得镜像特别不稳定，还需要带上 @DIGEST
        5. 使用容器来执行程序的好处是 “无论何处，环境都相同”

   4. 显示 containers

      * Usage:  docker ps [OPTIONS]

      * ```
        docker ps
        ```

      ```
      * 经常会使用-a 参数来显示所有的镜像（包括已经运行结束但未销毁的镜像）
      * ```
        docker ps -a
      ```

   5. 停止 container

      * Usage:  docker stop [OPTIONS] CONTAINER [CONTAINER...]
      * Usage:  docker kill [OPTIONS] CONTAINER [CONTAINER...]
      * 多使用help 命令来理解命令: ``` docker $command --help ```
      * 使用docker kill 的频率会更大一些，同时，kill 的能力也更强一些

   6. 销毁（删除）容器

      * Usage:  docker rm [OPTIONS] CONTAINER [CONTAINER...]

      * Usage:  docker container prune [OPTIONS]

      * 常用命令

        + ```
          docker container prune #清楚所有不运行的containers
          ```

        + ```
          docker rm $(docker ps -a -q -f status=exited)
          
          ```

   7. 重启容器

      * Usage:  docker restart [OPTIONS] CONTAINER [CONTAINER...]

   8. 查看镜像

      * Usage:  docker image ls [OPTIONS] [REPOSITORY[:TAG]]

      * ```
        docker image ls
        
        ```

   9. 删除镜像

      * Usage:  docker image rm [OPTIONS] IMAGE [IMAGE...]

      * ```
        docker image rm busybox:1.33.1-glibc
        
        ```

      * ```
        docker image rm hello-world:latest
        
        ```

      * ```
        docker image rm bc11b176a293
        
        ```

   10. Docker Network

       - Usage：docker network ls [OPTIONS]

       - ```
         docker network ls
         
         ```

   11. inspect

       - Usage： docker network inspect [OPTIONS] NETWORK [NETWORK...]

       - ```
         docker network inspect bridge
         
         ```

   12. create our own network

       - Usage：docker network create [OPTIONS] NETWORK

       - ```
         docker network create yumiao-bridge
         
         ```

   13. tag images

       - Usage：docker tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]

   14. log

       - Usage：docker logs [OPTIONS] CONTAINER

       - ```
         docker logs -f --until=2s test
         
         ```

   

   ## WebApps example

   1. more for docker run

      *   -d, --detach                         Run container in background and print container ID
      *   -p, --publish list                   Publish a container's port(s) to the host
      *   --rm                             Automatically remove the container when it exits

   2. 启动一个 WordPress

      * ```
        docker run --rm -p 8080:80 wordpress:5.7.2-php7.4-apache
        
        ```

      * 打开 localhost:8080 就能看到 wordpress 已正常工作

      * 没有加 -d 参数的情况下，使用 Ctrl+C 就可以结束container（当然也能使用 docker kill 命令）

   3. 查看容器的基本信息

      * ```
        docker ps
        
        ```

   ### how to build our own docker image

   1. 目录结构

      * ```
        flask
        ├── docker
        │   └── Dockerfile
        ├── requirements.txt
        └── src
            └── app.py
        
        ```

   2. app.py

      * ```
        from flask import Flask
        import os
        
        app = Flask(__name__)
        
        @app.route('/')
        def hello_world():
           return 'Hello World'
        
        if __name__ == "__main__":
           app.run(host="0.0.0.0",port=int(os.environ.get("PORT",5000)))
        
        
        ```

   3. requirements.txt

      * ```
        Flask==1.1.2
        Flask-Cors==3.0.10
        requests==2.25.1
        
        ```

   4. Dockerfile

      * ```
        From python:3.9.6-slim-buster
        
        COPY requirements.txt /tmp/requirements.txt
        RUN pip3 install -i http://mirrors.aliyun.com/pypi/simple -r /tmp/requirements.txt --trusted-host mirrors.aliyun.com
        
        COPY src/ /app/flask/
        
        CMD ["python", "/app/flask/app.py"]
        
        ```

      * 对于python镜像，alpine 是快速发布版本，我们一般使用类似于3.9.6-slim-buster标识的版本镜像

   5. build and run

      * Usage:  docker build [OPTIONS] PATH | URL | -

      * ```
        docker build . -f docker/Dockerfile -t hello-flask:1.0.0
        
        ```

      * ```
        docker image ls
        
        ```

      * docker run --rm -p 8080:5000 -it hello-flask:1.0.0

      * curl http://localhost:8080

   6. summary

      * 需要编译的代码文件放在src文件夹下
      * Dockerfile放在docker文件夹下
      * From 后面的镜像要制定具体版本，选择最详细最稳定的版本，防止每次新建版本不同，可以利用缓存
      * 将最不可能进行改动的文件和命令放在dockerfile的前面，比如将copy requirements和install的命令放在copy src命令之前,最大程度利用缓存
      * copy的命令尽量对文件夹进行copy
      * 有可能需要添加 WORKDIR 路径
      * CMD 参数里尽量使用绝对路径
      * dokcer build 命令中指定使用 . 指定context，使用-f 指定build所要用的Dockerfile

   ### how to build Node image

   1. files

      * structure 

        + ```
          .
          ├── Dockerfile
          ├── package.json
          └── src
              └── server.js
          
          ```

      * src/server.js

        + ```
          const ronin     = require( 'ronin-server' )
          const mocks     = require( 'ronin-mocks' )
          const server = ronin.server()
          server.use( '/', mocks.server( server.Router(), false, true ) )
          server.start()
          
          ```

      * package.json

        + ```
          {
            "name": "node-docker",
            "version": "1.0.0",
            "main": "index.js",
            "scripts": {
              "test": "echo \"Error: no test specified\" && exit 1"
            },
            "keywords": [],
            "author": "",
            "license": "ISC",
            "description": "",
            "dependencies": {
              "ronin-mocks": "^0.1.6",
              "ronin-server": "^0.1.3"
            }
          }
          
          ```

      * Dockerfile

        + ```
          FROM node:16.5.0-stretch-slim
          
          ENV NODE_ENV=production
          WORKDIR /app
          COPY package.json /app
          RUN npm install --production
          COPY src /app/src
          
          CMD [ "node", "src/server.js" ]
          
          ```

      * .Dockerignore

        + ```
          node_modules/
          Dockerfile
          
          ```

   2. build image

      * ```
        docker build . -f Dockerfile -t my-node-server:1.0.0
        
        ```

   3. run 

      * ```
        docker run --rm -p 8888:8000 my-node-server:1.0.0
        
        ```

   4. test

      * ```
        curl --request POST --data '{"msg": "testing"}' http://localhost:8888/test
        
        ```

   #### How to use Nginx Image

   1. pull imgage

      * ```
        docker pull nginx
        
        ```

   2. create configurations
      * host.docker.internal 代表host主机
      * nginx.conf

        + ```
          worker_processes  1;
          
          events {
              worker_connections  1024;
          }
          
          http {
              include       mime.types;
              default_type  application/octet-stream;
          
          
              sendfile        on;
          
              keepalive_timeout  65;
          
              server {
                  listen       8080;
                  server_name  localhost;
          
                  location / {
                      root   html;
                      index  index.html index.htm;
                  }
          
                  location /hello {
                      return 200 'hello world';
                  }
          
                  location /hello1 {
                       proxy_pass http://host.docker.internal:8081;
                  }
          
                  location /hello2 {
                       proxy_pass http://host.docker.internal:8082;
                  }
          
                  error_page   500 502 503 504  /50x.html;
                  location = /50x.html {
                      root   html;
                  }
              }
          }
          
          ```

      * nginxhello1.conf

        + ```
          worker_processes  1;
          
          events {
              worker_connections  1024;
          }
          
          http {
              include       mime.types;
              default_type  application/octet-stream;
          
              sendfile        on;
          
              keepalive_timeout  65;
          
              server {
                  listen       8081;
                  server_name  localhost;
          
                  location / {
                      return 200 'hello1';
                  }
          
                  error_page   500 502 503 504  /50x.html;
                  location = /50x.html {
                      root   html;
                  }
              }
          }
          
          ```

      * nginxhello2.conf

        + ```
          worker_processes  1;
          
          events {
              worker_connections  1024;
          }
          
          http {
              include       mime.types;
              default_type  application/octet-stream;
          
              sendfile        on;
              
              keepalive_timeout  65;
          
              server {
                  listen       8082;
                  server_name  sjm;
          
                  location / {
                      return 200 'hello2';
                  }
          
                  error_page   500 502 503 504  /50x.html;
                  location = /50x.html {
                      root   html;
                  }
              }
          }
          
          
          ```

   3. run

      * ```
        docker run -v F:/nginx/nginxhello.conf:/etc/nginx/nginx.conf -p 8080:8080 --name hello nginx
        docker run -v F:/nginx/nginxhello1.conf:/etc/nginx/nginx.conf -p 8081:8081 --name hello1 nginx
        docker run -v F:/nginx/nginxhello2.conf:/etc/nginx/nginx.conf -p 8082:8082 --name hello2 nginx
        ```

   4. test

      * ```
        localhost:8080/hello
        localhost:8080/hello1
        localhost:8080/hello2
        ```

