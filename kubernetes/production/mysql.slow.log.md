### mysql slow log

## main usage

* open mysql slow query log

## conceptions

* none

## practise

### pre-requirements

* [create local cluster for testing](../basic/local.cluster.for.testing.md)

### purpose

* open mysql slow query log with configuration file or set

### do it

#### open mysql slow query log with set

1. install maria-db by helm

    * prepare maria.db.values.yaml

    * helm install maria-db with default configuration
        + ```shell
            docker pull docker.io/bitnami/mariadb:10.5.12-debian-10-r32
            docker tag docker.io/bitnami/mariadb:10.5.12-debian-10-r32 localhost:5000/docker.io/bitnami/mariadb:10.5.12-debian-10-r32
            docker push localhost:5000/docker.io/bitnami/mariadb:10.5.12-debian-10-r32
            ./bin/helm install \
                --create-namespace --namespace database \
                maria-db-test \
                mariadb \
                --version 9.5.1 \
                --repo https://charts.bitnami.com/bitnami \
                --values maria.db.values.yaml \
                --atomic \
                --timeout 600s
        ```

2. Enter the maria-db pod and connect maria-db service
    
    * create a mysql client 
      + ```shell
        MYSQL_ROOT_PASSWORD=$(./kubectl get secret --namespace database maria-db-test-mariadb -o jsonpath="{.data.mariadb-root-password}" | base64 --decode)
        ./kubectl run maria-db-test-mariadb-client \
            --rm --tty -i \
            --restart='Never' \
            --image localhost:5000/docker.io/bitnami/mariadb:10.5.12-debian-10-r32 \
            --namespace database \
            --env MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
            --command -- bash
        ```

    * connect to maria-db with in the pod
        * ```shell 
          mysql -h maria-db-test-mariadb.database.svc.cluster.local -uroot -p$MYSQL_ROOT_PASSWORD my_database
          ```
   
    * Check if slow log query is turned on
        + ```shell 
          show variables like 'slow_query%'; 
          ```
        + output like this
            * ```shell
              MariaDB [my_database]> show variables like 'slow_query%';
              +---------------------+----------------------------------+
              | Variable_name       | Value                            |
              +---------------------+----------------------------------+
              | slow_query_log      | OFF                              |
              | slow_query_log_file | maria-db-test-mariadb-0-slow.log |
              +---------------------+----------------------------------+
              2 rows in set (0.004 sec)
            ```

    * use set command to turn on slow log query
        + open slow query log
            ```shell
            set global general_log=1; 
            set slow_query_log=1;
            
            ```
        + set long query time
            ```shell
            set long_query_time=2;
            
            ```
    
    * create a slow log
        ```shell
        select sleep(15);
        ```

3. Check if the slow log file exists in the maria-db pod
    
    * get a shell to maria-db container
        + ```shell
          ./kubectl -n database exec -it maria-db-test-mariadb-0 -- bash
          ```
    
    * View slow log content
        ```shell
        more maria-db-test-mariadb-0-slow.log
        ```
    it doesn't work here.

4. uninstall and clean up

    * uninstall maria-db by helm

      + ```shell
        ./helm -n database uninstall maria-db-test
        # pvc won't be deleted automatically
        ./kubectl -n database delete pvc data-maria-db-test-mariadb-0
        ```

#### open mysql slow query log with configuration file

1. install maria-db by helm
    
    * prepare maria.db.values.with.slow.log.config.yaml

    * helm install maria-db with  slow log query configuration
        + ```shell
            docker pull docker.io/bitnami/mariadb:10.5.12-debian-10-r32
            docker tag docker.io/bitnami/mariadb:10.5.12-debian-10-r32 localhost:5000/docker.io/bitnami/mariadb:10.5.12-debian-10-r32
            docker push localhost:5000/docker.io/bitnami/mariadb:10.5.12-debian-10-r32
            ./bin/helm install \
                --create-namespace --namespace database \
                maria-db-test \
                mariadb \
                --version 9.5.1 \
                --repo https://charts.bitnami.com/bitnami \
                --values maria.db.values.with.slow.log.config.yaml \
                --atomic \
                --timeout 600s
        ```

2. Enter the maria-db pod and connect maria-db service
    
    * create a mysql client 
      + ```shell
        MYSQL_ROOT_PASSWORD=$(./kubectl get secret --namespace database maria-db-test-mariadb -o jsonpath="{.data.mariadb-root-password}" | base64 --decode)
        ./kubectl run maria-db-test-mariadb-client \
            --rm --tty -i \
            --restart='Never' \
            --image localhost:5000/docker.io/bitnami/mariadb:10.5.12-debian-10-r32 \
            --namespace database \
            --env MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
            --command -- bash
        ```

    * connect to maria-db with in the pod
        * ```shell 
          mysql -h maria-db-test-mariadb.database.svc.cluster.local -uroot -p$MYSQL_ROOT_PASSWORD my_database
          ```
   
    * Check if slow log query is turned on
        + ```shell 
          show variables like 'slow_query%'; 
          ```
        + output like this
            * ```shell
              MariaDB [my_database]> show variables like 'slow_query%';
              +---------------------+----------------------------------+
              | Variable_name       | Value                            |
              +---------------------+----------------------------------+
              | slow_query_log      | ON                              |
              | slow_query_log_file | maria-db-test-mariadb-0-slow.log |
              +---------------------+----------------------------------+
              2 rows in set (0.004 sec)
            ```

    * check long_query_time
        + ```shell
          show variables like 'long_query%';
          ```
        + output like this
          ```shell
          +-----------------+----------+
          | Variable_name   | Value    |
          +-----------------+----------+
          | long_query_time | 2.000000 |
          +-----------------+----------+
          
          ```
    * create a slow log
        ```shell
        select sleep(15);
        ```

3. Check if the slow log file exists in the maria-db pod
    
    * get a shell to maria-db container
        + ```shell
          ./kubectl -n database exec -it maria-db-test-mariadb-0 -- bash
          ```
    
    * View slow log content
        ```shell
        more maria-db-test-mariadb-0-slow.log
        ```

    * output like this:
      ```shell

      
      ```

4. uninstall and clean up

    * uninstall maria-db by helm

      + ```shell
        ./helm -n database uninstall maria-db-test
        # pvc won't be deleted automatically
        ./kubectl -n database delete pvc data-maria-db-test-mariadb-0
        ```