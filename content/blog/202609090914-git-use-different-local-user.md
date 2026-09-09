---
date: 2026-09-09T09:16:21+08:00
slug: git-use-different-local-user
title: Git在特定仓库使用特定提交用户
---

我一般都是用SSH方式提交远程仓库的，所以可以在`~/.ssh/config`设置一个Host别名，专门用于小号`xicuod`的提交。

```sh
# 大号对GitHub的身份凭证
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519

# 小号对GitHub的身份凭证
Host github.com-xicuod
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_xicuod
```

之后要使用特定用户的时候，可以直接把远程仓库的SSH地址中的主机名从`github.com`换成`github.com-xicuod`这个别名，即可应用小号的身份凭证。

```sh
# before
git@github.com:大号用户名/仓库.git
# after
git@github.com-xicuod:小号用户名/仓库.git
```

同时，把仓库本地的git用户改为小号的用户名和邮箱：

```sh
git config user.name xicuod
git config user.email xicuod@163.com
```

这样提交时用的就是小号的身份标识。