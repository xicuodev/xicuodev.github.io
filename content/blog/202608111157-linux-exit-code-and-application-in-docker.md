---
date: 2026-08-11T11:57:00+08:00
slug: linux-exit-code-and-application-in-docker
title: Linux程序退出码以及它在docker compose健康检查中的应用
---

程序退出码 (exit code，也称为返回码或状态码) 是命令、程序或脚本执行完毕后，向其父进程（通常是 shell 程序）返回的一个整数，用于标识程序执行的结果成功或失败，0 表示成功，非 0 值表示失败，具体数值对应不同的错误类型。

## 程序退出码在docker compose健康检查中的典型应用

在 Docker Compose 中，根据健康测试命令的程序退出码来检查容器的健康状态。如果test指定的命令退出码为 0，则代表本次健康测试通过，否则代表不通过。若连续失败达到 retries 次，容器状态变为 unhealthy；若在重试期间有一次成功，则失败计数清零，容器恢复或维持为 healthy。

```yml
services:
  mysql:
    #...existing entries...#
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 90s
  nacos:
    #...existing entries...#
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8848/nacos/v1/ns/operator/metrics"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 30s
```

## 参考资料

- [Linux 命令退出码（Exit Code）详解：从基础到高级实践-极客技术博客](https://geek-blogs.com/blog/linux-command-exit-code/)
