---
categories:
- 通用开发知识
date: 2026-02-18T15:52:30+08:00
slug: git-installation-and-configuration
tags:
- Git
title: Git (2)：安装并配置好 Git
---
## 在 Windows 上安装 Git

对于 Git for Windows，从 [Git](https://git-scm.com/ "Git") 官网下载 Git 的 Windows 安装器，然后根据下面的参考文本按步骤走完安装流程。

> macOS 和 Linux 上的 Git 一般通过包管理器安装，具体步骤可以问 LLM，这里只给出 Windows 上安装过程。

1. Git Bash 是 Git 提供的 Shell，与 Git 配合得最融洽。你可以在安装时勾选 `Add a Git Bash Profile to Windows Terminal`，为 Windows 终端添加 Git Bash 配置，这样你就可以使用 Windows 终端快捷启动并使用 Git Bash。之后你可以配置环境变量，让别的客户端也可以使用 Git。

2. Git 的一些操作需要用到文本编辑器，安装时你可以指定 Git 默认使用的文本编辑器，默认是 Vim，但是 Vim 对终端新手不友好，你可以换成 Notepad（Windows 记事本）、VSCode 或其他你用得最顺手的文本编辑器。

3. **分支**（**branch**）是 Git 保存代码的标准位置，旨在更好地管理不同开发线路的版本。你可以为分支取名，主分支的默认名称一般是 `master`，但是受西方“黑命贵”运动（Black Lives Matter）的影响，有些人认为 `master` 会让人联想到“奴隶主”，所以他们呼吁改用 `main` 作为默认的主分支名。你可以在安装 Git 时自定义默认的主分支名。

4. Git 的 PATH 环境变量配置决定了你能以何种方式访问 Git，有三个选项：只使用 Git Bash 程序；既使用命令行也使用第三方客户端；使用命令提示符上的 Git 和可选的 Unix 工具（如 `find` 和 `sort`，这会覆盖 Windows 自带的 `find` 和 `sort` 工具，你必须“知道你在做什么”）。推荐“既使用命令行也使用第三方客户端”，它给你最多的选择，最灵活又不给 Windows 造成负面影响。

5. Git 配置 OpenSSH 工具：使用与 Git 捆绑的 `ssh.exe` 程序；使用外部 OpenSSH（在 Windows 环境变量中添加）。这看你的使用哲学，不希望自己的设备有多份 Chrome 内核的“复用至上”主义者可以选后者；更注重可携带性的可以选前者。

6. Git 配置 HTTPS 的 SSL/TLS 证书库：使用 OpenSSL 库；使用原生的“Windows 安全通道”库。建议选前者，表现更佳。

7. Git 配置行尾符转换：签出为 Windows 样式（CRLF），提交为 Unix 样式（LF）；签出为原样，提交为 Unix 样式；签出为原样，提交为原样。Windows 和 Unix 的默认行尾符不一样，建议选第一个，保证服务器的文本是跨平台的。

8. Git 配置运行 Git Bash 的终端模拟器：使用 MinTTY（MSYS2 默认终端）；使用 Windows 默认控制台窗口。推荐选前者，后者有一些限制，表现不佳。

9. Git 配置 `git pull` 的默认行为：快进或合并（fast-forward or merge，默认）；变基（rebase）；任何时候都只快进。默认是对的，大部分情况都选第一个。

10. Git 配置凭据帮手（credential helper）：使用 Git 凭据管理器；不使用凭据帮手。凭据帮手用于处理用户登录凭据，提供对服务器的身份认证服务，选第一个。

11. Git 配置额外选项：

	- 启用文件系统缓存：推荐选中，有显著性能提升。

	- 启用符号链接：默认留空，不推荐选中。

12. Git 实验性选项：这些是给愿意帮官方 debug 的人设立的选项，我们不希望引入不确定性因素，除非你“知道你在做什么”，否则不推荐选中。

安装完成后，随便在一个常规目录中右键选择 `Git Bash Here`，打开 Git Bash 窗口；你也可以打开 Windows 终端，点开标题栏的下箭头选择 Git Bash 配置文件，打开一个 Git Bash 标签页，然后输入：

```sh
git --version
```

如果返回 Git 版本信息，说明安装成功。你也可以在 Windows 命令提示符（Command Prompt）或 Windows PowerShell 里输入同样的命令，它们是等效的。如果后者不行，那么倒回去第 4 步检查你的 PATH 环境变量配置。

## Git 列出和修改配置项

接下来我们要使用 Git Bash 配置 Git。下面的命令用于列出 Git 的所有配置项：

```sh
git config --list
```

我用的是 macOS 所以输出是这样：

```
credential.helper=osxkeychain
core.autocrlf=input
safe.directory=*
```

这些都是 Git 的全局配置，对所有 Git 仓库生效。要修改它们，使用 `--global` 选项，比如把默认文本编辑器改成 Microsoft Visual Studio Code（“微软大战代码”），确保你的 PATH 环境变量中有包含 `notepad.exe` 的目录：

```sh
git config --global core.editor notepad
```

如果想要知道每项配置来源的配置文件，在 `--list` 的基础上加上 `--show-origin` 选项：

```sh
git config --list --show-origin
```

```
file:/opt/homebrew/etc/gitconfig	credential.helper=osxkeychain
file:/Users/your-username/.gitconfig	core.autocrlf=input
file:/Users/your-username/.gitconfig	core.editor=notepad
file:/Users/your-username/.gitconfig	safe.directory=*
```

结果包含两个配置文件，其中一个带 `etc/` 目录的是整个系统的配置，另一个带 `Users/` 或 `home/` 目录的是用户配置（用户配置文件内容见下面代码块）。普通用户登录时，用户配置会覆盖系统配置。Windows 上的结果与这个类似，也是同理。

```
[core]
	autocrlf = input
	editor = notepad
[safe]
	directory = *
```

## Git 删除配置项

`git config` 提供了 `--unset` 和 `--unset-all` 选项来删除配置项。`--unset` 一次只能删除一个配置项。一般建议只动用户配置文件，不要动系统配置文件。

```sh
git	config --global --unset core.editor
```

## Git 配置用户名和邮箱

一开始最基础两个配置是用户名和用户邮箱，这样别人才知道是你写的代码，以及有事该如何联系你，没有这两个配置，Git 不会让你提交代码：

```sh
git config --global user.name "Your Name"
```

```sh
git config --gobal user.email "you@example.com"
```

## 更新 Git

对于 Windows 上通过安装器安装的 Git，使用下面的命令；对于 macOS 和 Linux 上的 Git，使用当时安装 Git 的包管理器更新。

```sh
git update-git-for-windows
```

## Git 的 GUI 客户端

Git 在 Windows、macOS、Linux、Android 和 iOS 都有 GUI 客户端，详见 [Git - GUI Clients](https://git-scm.com/tools/guis "Git - GUI Clients")。然而，你不应该跳过命令行直接去使用 GUI 客户端。虽然 Git 的 GUI 客户端琳琅满目，但是它们都是第三方提供的，官方一般不参与维护，今天好使明天可能就不好使了；如果你不了解 Git 的命令行用法，那么这些 GUI 客户端往往会令你十分困惑；有些开发环境比较恶劣，不能使用 GUI 客户端，而在几乎任何情况下，命令行总是能奏效。
