1. [Prepare a local cluster](local.cluster.for.testing.md)
2. pull image
    * ```
      docker pull docker.io/bitnami/mariadb:10.5.12-debian-10-r32
      ```
3. tag image
    * ```
      docker tag  docker.io/bitnami/mariadb:10.5.12-debian-10-r32 localhost:5000/bitnami/mariadb:10.5.12-debian-10-r32
      ```
4. push image to local registry
    * ```    
      docker push localhost:5000/bitnami/mariadb:10.5.12-debian-10-r32
      ```
5. helm install 
    * maria.db.values.yaml
        + ```
          image:
            registry: localhost:5000
            repository: bitnami/mariadb
            tag: 10.5.12-debian-10-r32
          primary:
            persistence:
              storageClass: standard
          ```
    * install
        + ```
          ./helm install \
              --create-namespace --namespace database \
              maria-db-test \ 
              mariadb \     
              --version 9.5.1 \
              --repo https://charts.bitnami.com/bitnami \
              --atomic \    
              --timeout 600s
          ```
6. helm upgrade
    * maria.db.values.yaml
        + ```
          image:
            registry: localhost:5000
            repository: bitnami/mariadb
            tag: 10.5.12-debian-10-r32
          primary:
            persistence:
              storageClass: standard
            extraEnvVars:
              - name: TZ
                value: "Asia/Shanghai"
          ```
    * upgrade
        + ```
          ROOT_PASSWORD=$(kubectl get secret --namespace database 
              maria-db-test-mariadb \
              -o jsonpath="{.data.mariadb-root-password}" \
              | base64 --decode
          ) && ./helm upgrade \
              --namespace database \
              maria-db-test \
              mariadb \
              --version 9.5.1 \
              --repo https://charts.bitnami.com/bitnami \
              --values maria.db.values.yaml \
              --set auth.rootPassword=$ROOT_PASSWORD
          ```