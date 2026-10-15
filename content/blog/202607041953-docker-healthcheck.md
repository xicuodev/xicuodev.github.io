---
date: 2026-07-04T19:53:52+08:00
slug: docker-healthcheck
title: Docker Compose常用容器健康检查的写法集锦
tags: [Docker]
---

Redis:

```yaml
healthcheck:
  test: ["CMD", "redis-cli", "ping"]
  interval: 10s
  timeout: 5s
  retries: 3
  start_period: 30s
```

MySQL:

```yaml
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
  interval: 30s
  timeout: 5s
  retries: 3
  start_period: 90s
```

Nginx:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost/"]
  interval: 10s
  timeout: 5s
  retries: 3
  start_period: 10s
```

OpenResty:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8081/50x.html"]
  interval: 10s
  timeout: 5s
  retries: 3
  start_period: 30s
```

Nacos:

```yaml
healthcheck:
  test:
    ["CMD", "curl", "-f", "http://localhost:8848/nacos/v1/ns/operator/metrics"]
  interval: 30s
  timeout: 5s
  retries: 3
  start_period: 30s
```
