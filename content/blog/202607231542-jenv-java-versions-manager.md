---
date: 2026-07-23T15:42:00+08:00
slug: jenv-java-versions-manager
title: jenv：java版本管理cli工具
---

macos 查看所有系统认可的 java 路径：

```
$ /usr/libexec/java_home -V
```

```
Matching Java Virtual Machines (3):
    17.0.19 (arm64) "Azul Systems, Inc." - "Zulu 17.66.19" /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
    1.8.0_492 (arm64) "Azul Systems, Inc." - "Zulu 8.94.0.17" /Users/xxx/Library/Java/JavaVirtualMachines/azul-1.8.0_492/Contents/Home
    1.8.0_482 (arm64) "Azul Systems, Inc." - "Zulu 8.92.0.21" /Users/xxx/Library/Java/JavaVirtualMachines/azul-1.8.0_482/Contents/Home
/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
```

jenv add 添加 java 路径：

```
$ jenv add /Users/xxx/Library/Java/JavaVirtualMachines/azul-1.8.0_482/Contents/Home
```

jenv 查看它管理的 java 版本：

```
$ jenv versions
```

```
  system
* 1.8 (set by /Users/xxx/.java-version)
  1.8.0.482
  17
  17.0
  17.0.19
  zulu64-1.8.0.482
  zulu64-17.0.19
```

jenv 支持三种类型的 JDK 配置：

1. 全局: 如果我们在计算机上的任何地方输入 java 命令，将使用此 JDK。
2. 本地: 仅为特定文件夹配置的 JDK。在该文件夹中输入 java 命令将使用本地 JDK 版本，而不是全局 JDK 版本。
3. Shell: 仅在当前 shell 实例中使用的 JDK。

具体怎么做：

- 全局：`jenv global 17` 会创建指向 jdk17 目录的符号链接  `~/.jenv/version/17` 并将其写入 `$JAVA_HOME` 环境变量。

  ```
  $ ls -la ~/.jenv/version/17
    /Users/xxx/.jenv/versions/17@ -> /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
  $ echo $JAVA_HOME
    /Users/xxx/.jenv/versions/17
  ```

- 本地：`jenv local 1.8` 执行后会在当前目录生成一个 `.java-version` 文件，内容就是你指定的 java 版本号 `1.8`。
- shell：`jenv shell 1.8` 设置环境变量 `JENV_VERSION`。