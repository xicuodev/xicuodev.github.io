---
date: 2026-08-13T13:37:00+08:00
slug: mysql-in-docker-grant-privileges-to-host-user
title: docker容器内的mysql给宿主用户授权
---

我的wiki站点的mysql数据库部署在docker容器中，虽然可以通过 `docker exec -it xw-mysql /bin/bash` 在容器内访问，但是在宿主机外访问要更为方便，于是引出本篇博文的问题：docker容器内的mysql如何给宿主用户授权。

## mysql授权指定ip的指定用户访问

先看mysql是如何给指定ip的指定用户授权的。

mysql 8.0 写法：

```sql
CREATE USER 'xw'@'172.18.0.1' IDENTIFIED BY 'xw';

GRANT ALL PRIVILEGES ON xicwitki.* TO 'xw'@'172.18.0.1';
```

mysql 5.7 以及更低版本写法：(这种写法已在 8.0 移除)

```sql
GRANT ALL PRIVILEGES ON xicwitki.* TO 'xw'@'172.18.0.1' IDENTIFIED BY 'xw';
```

可通过以下sql语句查看所有用户:

```sql
select user, host from mysql.user;
```

```
+------------------+------------+
| user             | host       |
+------------------+------------+
| xw               | 172.18.0.1 |
| mysql.infoschema | localhost  |
| mysql.session    | localhost  |
| mysql.sys        | localhost  |
| root             | localhost  |
| xw               | localhost  |
+------------------+------------+
```

查看用户权限:

```sql
SHOW GRANTS FOR 'xw'@'172.18.0.1';
```

```
+-----------------------------------------------------------+
| Grants for xw@172.18.0.1                                  |
+-----------------------------------------------------------+
| GRANT USAGE ON *.* TO `xw`@`172.18.0.1`                   |
| GRANT ALL PRIVILEGES ON `xicwitki`.* TO `xw`@`172.18.0.1` |
+-----------------------------------------------------------+
```

## docker容器内的mysql给宿主用户授权

宿主机通过mysql命令行客户端访问docker容器内的mysql服务器：

```sh
mysql -h127.0.0.1 -P3306 -uroot -p
```

如果写 `-h localhost`，mysql客户端会走 Unix socket，这是访问本机的mysql服务器用的，在当前docker场景下无效。

这会走TCP访问，请求经过docker的nat到达目标容器，容器内看到的ip是docker网桥网关ip。mysql默认没有docker网关ip的授权，所以会得到类似以下输出：

```
ERROR 1130 (HY000): Host '172.18.0.1' is not allowed to connect to this MySQL server
```

下面是解决方案。确认容器所在网络的subnet网段和gateway网关ip：

```sh
docker network inspect xwnet --format '{{range .IPAM.Config}}subnet={{.Subnet}} gateway={{.Gateway}}{{end}}'
```

```
subnet=172.18.0.0/16 gateway=172.18.0.1
```

可以发现，容器内看到的宿主请求ip就是虚拟网络的网关ip。最终写法参考上一个小节。

## 根据docker虚拟网络的运行机制，它所在的网段和网关ip会改变吗？

docker的**虚拟网络删除后重建**时，它的网段和网关ip可能改变。若想要固定网段和网关ip，应当在 Docker Compose 中配置:

```yml
networks:
  xwnet:
    ipam:
      config:
        - subnet: 172.18.0.0/16
          gateway: 172.18.0.1
```

显式指定ipam后，如果虚拟网络删除重建时网段和网关ip已经被占用了，那么docker会直接报错，这正是我们想要的效果，我们方可处理。

或者，另一种方案是预建 external 网络。先手动创建外部网络，然后在 compose 里面引用它，这样外部网络不会因为 compose 的重建而重建，也就不会改变它的网段和网关ip了。

```sh
docker network create \
  --driver bridge \
  --subnet=172.18.0.0/16 \
  --gateway=172.18.0.1 \
  xwnet
```

```yml
networks:
  xwnet:
    external: true
```