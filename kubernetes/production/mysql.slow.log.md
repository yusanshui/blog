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

    * prepare [maria.db.values.yaml](resources/maria.db.values.yaml.md)

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
            set global slow_query_log=1;
            set global slow_query_log_file = "/tmp/slow_query.log"
            ```
        + set long query time
            ```shell
            set global long_query_time=2;
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
        + ```shell
          more /tmp/slow_query.log
          ```
        + output like this
          ```
          Tcp port: 3306  Unix socket: /opt/bitnami/mariadb/tmp/mysql.sock
          Time		    Id Command	Argument
          # Time: 211019  7:10:32
          # User@Host: root[root] @  [10.244.2.7]
          # Thread_id: 24  Schema: my_database  QC_hit: No
          # Query_time: 15.000489  Lock_time: 0.000000  Rows_sent: 1  Rows_examined: 0
          # Rows_affected: 0  Bytes_sent: 65
          use my_database;
          SET timestamp=1634627432;
          select sleep(15);
          ```

4. uninstall and clean up

    * uninstall maria-db by helm

      + ```shell
        ./helm -n database uninstall maria-db-test
        # pvc won't be deleted automatically
        ./kubectl -n database delete pvc data-maria-db-test-mariadb-0
        ```

#### open mysql slow query log with configuration file

1. install maria-db by helm
    
    * prepare [maria.db.values.with.slow.log.config.yaml](resources/maria.db.values.with.slow.log.config.yaml.md)

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
              | slow_query_log      | ON                               |
              | slow_query_log_file | /tmp/slow_query.log              |
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
        + ```shell
          more /tmp/slow_query.log
          ```
        + output like this
          ```
          Tcp port: 3306  Unix socket: /opt/bitnami/mariadb/tmp/mysql.sock
          Time		    Id Command	Argument
          # Time: 211019  7:10:32
          # User@Host: root[root] @  [10.244.2.7]
          # Thread_id: 24  Schema: my_database  QC_hit: No
          # Query_time: 15.000489  Lock_time: 0.000000  Rows_sent: 1  Rows_examined: 0
          # Rows_affected: 0  Bytes_sent: 65
          use my_database;
          SET timestamp=1634627432;
          select sleep(15);
          ```

4. uninstall and clean up

    * uninstall maria-db by helm

      + ```shell
        ./helm -n database uninstall maria-db-test
        # pvc won't be deleted automatically
        ./kubectl -n database delete pvc data-maria-db-test-mariadb-0
        ```