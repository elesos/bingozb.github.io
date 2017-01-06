---
title: MySQL支持emoji字符的插入
date: 2016-12-30 02:30:37
categories: 解决方案
tags: [MySQL, J2EE]
---

#### 插入emoji表情报错

一般情况下，往数据库插入emoji字符，会报类似如下的错误:
```
Error 1366: Incorrect string value: '\xF0\x9F\x91\xBD\xF0\x9F...' for column 'xxx'
```
Google说MySQL的utf8不是真正的UTF8，只能包含3个字节的unicode，4个字节就会报错。解决这个问题要使用`utf8mb4`这个编码。

* mysql 5.5.3 版本之前，utf8编码最多支持3个字节，也就是BMP这部分的编码区，范围0000～FFFF这一部分。
* mysql 5.5.3 之后的版本，增加utf8mb4，官方介绍它是向下兼容utf8字符集，比utf8能标示更多的字符。
<!--more-->

#### 解决方法
- 检查MySQL版本，如果版本低于5.5.3,请先升级数据库。

- 以linux服务器为例，找到数据库配置文件`my.cnf`，编辑在对应标签下添加参数。
  ```
  vim /etc/my.cnf
  
  [client]
  default-character-set = utf8mb4
  
  [mysql]
  default-character-set = utf8mb4
  
  [mysqld]
  character-set-client-handshake = FALSE
  character-set-server = utf8mb4
  collation-server = utf8mb4_unicode_ci
  init_connect = 'SET NAMES utf8mb4'
  ```
- 修改 database、table 和 column字符集 （根据情况决定）
  ```
  $ ALTER DATABASE database_name CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
  
  $ ALTER TABLE table_name CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  
  $ ALTER TABLE table_name CHANGE column_name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  ```
- 重启服务
  ```
  $ sudo /etc/init.d/mysql restart
  ```
- 检查字符集
  ```
  mysql> SHOW VARIABLES WHERE Variable_name LIKE 'character\_set\_%' OR Variable_name LIKE 'collation%';
  +--------------------------+--------------------+
  | Variable_name            | Value              |
  +--------------------------+--------------------+
  | character_set_client     | utf8mb4            |
  | character_set_connection | utf8mb4            |
  | character_set_database   | utf8mb4            |
  | character_set_filesystem | binary             |
  | character_set_results    | utf8mb4            |
  | character_set_server     | utf8mb4            |
  | character_set_system     | utf8               |
  | collation_connection     | utf8mb4_unicode_ci |
  | collation_database       | utf8mb4_unicode_ci |
  | collation_server         | utf8mb4_unicode_ci |
  +--------------------------+--------------------+
  10 rows in set (0.01 sec)
  ```
  必须要保证 `character_set_client`、`character_set_connection`、`character_set_database`、`character_set_results`、`character_set_server` 这五个的值为`utf8mb4`。
  
#### 额外补充
- 如果使用`jdbc-url`进行连接，characterEncoding不支持写utf8mb4，写法不变。`characterEncoding=utf8`可以被自动被识别为`utf8mb4`，兼容原来的`utf8`。
```
jdbc:mysql://localhost:3306/database?useUnicode=true&characterEncoding=utf8
```
- 如果是新建的数据库，一般不会有什么问题，如果是从utf8改成utf8mb4的旧数据库，可能会出现插入依然报错的情况。这时候只需要把url中的`characterEncoding=utf8`去掉。
```
jdbc:mysql://localhost:3306/database?useUnicode=true
```
- 如果还有其他诸如中文插入乱码的问题，提供一种可行性很高的解决方法，即更新数据库连接驱动包，附上官网下载链接 [mysql-connector-java-5.1.35.zip](http://dev.mysql.com/downloads/file/?id=456317)；再不行就把url中`characterEncoding=utf8`的`utf8`改为`gbk`。
