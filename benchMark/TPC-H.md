### TPC-H

TPC-H 一个决策支持基准，由一套面向业务的临时查询和并发数据修改组成
* 评价指标 Query-per-Hour Performance Metric 
This benchmark illustrates decision support systems that examine large volumes of data, execute queries with a high degree of complexity, and give answers to critical business questions. 
* aspects of the capability of the system
    + the selected database size against which the queries are executed
      (执行查询所针对的选定数据库大小)
    + the query processing power when queries are submitted by a single stream
    + the query throughput when queries are submitted by multiple concurrent users

1. [Create a mysql application in k8s](../kubernetes/production/mysql.slow.log.md)
    * ```
      echo $MYSQL_ROOT_PASSWORD
      ```

2. export mysql service
    * kubectl port-forward -n database  svc/maria-db-test-mariadb 3306:3306

3. install mysql-client 
     * on ubuntu
         + ```
           apt-get -y install mysql-client
           ```
4. Download TCP-H tools
http://www.tpc.org/tpc_documents_current_versions/current_specifications5.asp

5. 解压文件到tpc-h文件夹下，进入到dbgen目录下，修改makefile
    * ```
      cd ./tpc-h/TPC-H_Tools_v3.0.0/dbgen
      cp makefile.suite makerfile
      vi makefile
      ```
    * ```
      CC      = gcc
      # Current values for DATABASE are: INFORMIX, DB2, TDAT (Teradata)
      #                                  SQLSERVER, SYBASE, ORACLE, VECTORWISE
      # Current values for MACHINE are:  ATT, DOS, HP, IBM, ICL, MVS,
      #                                  SGI, SUN, U2200, VMS, LINUX, WIN32
      # Current values for WORKLOAD are:  TPCH
      DATABASE = MYSQL
      MACHINE  = LINUX
      WORKLOAD = TPCH
      #
      ```
6. 修改tpcd.h, 在文件最上方添加
    * ```
      #ifdef MYSQL
      #define GEN_QUERY_PLAN ""
      #define START_TRAN "START TRANSACTION"
      #define END_TRAN "COMMIT"
      #define SET_OUTPUT ""
      #define SET_ROWCOUNT "limit %d;\n"
      #define SET_DBASE "use %s;\n"
      #endif
      ```
7. 编译，生成dbgen文件
    * ```
      make
      ```
8. 生成.tpl数据文件,一共会生成8个表（.tbl）。生成1G数据。其中1表示生成1G数据。如果你想生成10G，将1改为10。
    * ```
      ./dbgen -s 1
      ```
9. 修改初始化脚本
    * dss.ddl：用来建表,在dss.ddl文件开头加入如下内容
        + ```
          DROP DATABASE tpch;
          CREATE DATABASE tpch;
          USE tpch;
          ```
    * 将dss.ddl中表名变成小写
        + ```
          vi dss.ddl
          :%s/TABLE\(.*\)/TABLE\L\1
          ```
    * dss.ri：关联表中primary key和foreign key。
    * ```
      -- Sccsid:     @(#)dss.ri   2.1.8.1
      -- tpch Benchmark Version 8.0
      
      USE tpch;
      
      -- ALTER TABLE tpch.region DROP PRIMARY KEY;
      -- ALTER TABLE tpch.nation DROP PRIMARY KEY;
      -- ALTER TABLE tpch.part DROP PRIMARY KEY;
      -- ALTER TABLE tpch.supplier DROP PRIMARY KEY;
      -- ALTER TABLE tpch.partsupp DROP PRIMARY KEY;
      -- ALTER TABLE tpch.orders DROP PRIMARY KEY;
      -- ALTER TABLE tpch.lineitem DROP PRIMARY KEY;
      -- ALTER TABLE tpch.customer DROP PRIMARY KEY;
      
      -- For table region
      ALTER TABLE tpch.region
      ADD PRIMARY KEY (R_REGIONKEY);
      
      -- For table nation
      ALTER TABLE tpch.nation
      ADD PRIMARY KEY (N_NATIONKEY);
      
      ALTER TABLE tpch.nation
      ADD FOREIGN KEY NATION_FK1 (N_REGIONKEY) references
      tpch.region(R_REGIONKEY);
      
      COMMIT WORK;
      
      -- For table part
      ALTER TABLE tpch.part
      ADD PRIMARY KEY (P_PARTKEY);
      
      COMMIT WORK;
      
      -- For table supplier
      ALTER TABLE tpch.supplier
      ADD PRIMARY KEY (S_SUPPKEY);
      ALTER TABLE tpch.supplier
      ADD FOREIGN KEY SUPPLIER_FK1 (S_NATIONKEY) references
      tpch.nation(N_NATIONKEY);
      
      COMMIT WORK;
      
      -- For table partsupp
      ALTER TABLE tpch.partsupp
      ADD PRIMARY KEY (PS_PARTKEY,PS_SUPPKEY);
      
      COMMIT WORK;
      
      -- For table customer
      ALTER TABLE tpch.customer
      ADD PRIMARY KEY (C_CUSTKEY);
      
      ALTER TABLE tpch.customer
      ADD FOREIGN KEY CUSTOMER_FK1 (C_NATIONKEY) references
      tpch.nation(N_NATIONKEY);
      
      COMMIT WORK;
      
      -- For table lineitem
      ALTER TABLE tpch.lineitem
      ADD PRIMARY KEY (L_ORDERKEY,L_LINENUMBER);
      
      COMMIT WORK;
      
      -- For table orders
      ALTER TABLE tpch.orders
      ADD PRIMARY KEY (O_ORDERKEY);
      
      COMMIT WORK;
      
      -- For table partsupp
      ALTER TABLE tpch.partsupp
      ADD FOREIGN KEY PARTSUPP_FK1 (PS_SUPPKEY) references
      tpch.supplier(S_SUPPKEY);
      COMMIT WORK;
      
      ALTER TABLE tpch.partsupp
      ADD FOREIGN KEY PARTSUPP_FK2 (PS_PARTKEY) references
      tpch.part(P_PARTKEY);
      
      COMMIT WORK;
      
      -- For table orders
      ALTER TABLE tpch.orders
      ADD FOREIGN KEY ORDERS_FK1 (O_CUSTKEY) references
      tpch.customer(C_CUSTKEY);
      
      COMMIT WORK;
      
      -- For table lineitem
      ALTER TABLE tpch.lineitem
      ADD FOREIGN KEY LINEITEM_FK1 (L_ORDERKEY) references
      tpch.orders(O_ORDERKEY);
      
      COMMIT WORK;
      
      ALTER TABLE tpch.lineitem
      ADD FOREIGN KEY LINEITEM_FK2 (L_PARTKEY,L_SUPPKEY) references
      tpch.partsupp(PS_PARTKEY,PS_SUPPKEY);
      
      COMMIT WORK;
      ```
    
    * 初始化
        + ```
          mysql -hlocalhost -uroot -p$MYSQL_ROOT_PASSWORD < dss.ddl
          mysql -hlocalhost -uroot -p$MYSQL_ROOT_PASSWORD < dss.ri
          ```
 
 10. 导入数据
    * ```
      vi load.sh
      ```
        + ```
          #!/bin/bash
          
          write_to_file()
          {
          file="loaddata.sql"
          
          if [ ! -f "$file" ] ; then
          touch "$file"
          fi
          
          echo 'USE tpch;' >> $file
          echo 'SET FOREIGN_KEY_CHECKS=0;' >> $file
          
          DIR=`pwd`
          for tbl in `ls *.tbl`; do
          table=$(echo "${tbl%.*}")
          echo "LOAD DATA LOCAL INFILE '$DIR/$tbl' INTO TABLE $table" >> $file
          echo "FIELDS TERMINATED BY '|' LINES TERMINATED BY '|\n';" >> $file
          done
          echo 'SET FOREIGN_KEY_CHECKS=1;' >> $file
          }
          
          write_to_file
          ```
     * run
         + ```
           sh load.sh
           ```
     * 导入数据
         + 登录数据库，修改global参数
             * ```
               mysql -hlocalhost -uroot -p$MYSQL_ROOT_PASSWORD
               SET GLOBAL local_infile = 'ON';
               exit;
               ```
         + ```
            mysql -hlocalhost -uroot -p$MYSQL_ROOT_PASSWORD < loaddata.sql --local-infile
           ```
11. 生成SQL语句
    * ```
      cp qgen dists.dss queries/
      ```

12. 创建saveSql文件夹（在dbgen目录下执行）
    * ```
      mkdir ../saveSql
      ```
13. 进入queries目录,生成SQL语句
    * ```
      cd queries
      ./qgen -d 1 > ../../saveSql/1.sql
      ./qgen -d 2 > ../../saveSql/2.sql
      ./qgen -d 3 > ../../saveSql/3.sql
      ······
      ./qgen -d 22 > ../../saveSql/22.sql
      ```
    * 修改saveSql文件夹下的sql文件
        + ```
          1.sql 删除 day后面的 (3)
          ```
        + ```
          1.sql、4.sql、5.sql、6.sql、7.sql、8.sql、9.sql、11.sql、12.sql、13.sql、14.sql、15.sql、16.sql、17.sql、19.sql、20.sql、22.sql、
          删除最后一行的 limit -1;
          可以在savaSql目录下快速删除，输入命令：
          sed -i "s/limit\ -1;//g" *.sql
          ```
        + ```
          2.sql、3.sql、10.sql、18.sql、21.sql
          删除倒数第二行的分号
          ```
14. 使用SQL进行测试
[TPC-H语句](https://www.cnblogs.com/zhjh256/p/15008420.html)