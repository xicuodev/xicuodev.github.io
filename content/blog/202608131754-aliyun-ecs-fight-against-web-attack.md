---
date: 2026-08-13T17:54:00+08:00
slug: aliyun-ecs-fight-against-web-attack
title: 记一次阿里云ECS弹性云服务器遭遇攻击并解决的全过程
---

> 8 月 13 日下午，我的服务器彻底失联了。起因只是一个放在 web 根目录下的 .git 目录。在之前的 4 天里，它被爬走了 11.25GB 流量，遭遇了 3 万次 SSH 爆破，最后因内存耗尽而宕机。

事情的开端是本周一（2026年8月10号）我收到阿里云的短信，提示我：“您正在使用的产品cdt_DataTransfer_public_cn当前周期免费额度已使用80%。”我不以为意。结果次日我又收到一封阿里云的短信，提示我“免费额度已耗尽”。我甚至不知道CDT是什么，但至少“超出免费额度的额度是需要收费的”这点我还是懂的，但当时我正忙于自己的Java微服务项目，只是从手机上的阿里云APP简单扫了一眼——好吧，起码我知道CDT是Cloud Data Transfer“云数据传输”了。

从开始搭建那基于MediaWiki的wiki站点以来，我看文档、试方案、问LLM，前前后后研究了一两周，总算是把它托管到阿里云服务器并上线了。之后我忙于别的项目，就没怎么打理过它了，到现在已经闲置了几周时间。我这个名不见经传的小网站平时能有多少访问量，怎会闹出这般动静出来？想到这里，我才开始隐约察觉。

直到周四，也就是今天，我才终于把这件事提上日程，打开阿里云控制台一看，竟发现我那2核2G的实例的公网流量变成了这般模样：

![](https://img.xicuodev.top/2026/08/d53f953d7ac32b344b70ac6703a3aa62.webp)

从8月7日开始，公网流出带宽突然暴增，且居高不下，一直保持在1Mbps左右。要不是我的公网带宽只设置了1Mbps，还不知道要跑掉多少流量。阿里云CDT控制台显示我这台实例已经跑了36GB流量，而这些流量完全是这几天被恶意刷出来的。

LLM提示我用iftop查看出站流量，一看，原来是一个[跑在Google Cloud上的爬虫](https://www.pdflibr.com/blog/googleusercontent-is-not-a-google-crawler)。我在阿里云安全组中把这个爬虫的IP封了之后，以为万事大吉，结果事情并没有我想的那么简单：公网流出带宽并没有降下来，我又打开iftop看，原来封了那个IP之后，立马就有两三个同一网段的IP接续上来。

直到看到Apache日志中.git目录文件的200请求，我才切实地体会到网络攻击最真实的相貌。

```
34.96.41.75 - - [13/Aug/2026:09:54:44 +0800] "HEAD /w/.git/objects/pack/pack-9d86cd7e8518022d8097c202e6a30e96a1771842.pack HTTP/1.1" 200 269 "-" "Mozilla/5.0"
```

我的.git目录全然暴露在公网上了！爬虫正在疯狂地爬取.git目录下的大文件，占满了我的带宽。我应该是犯了一个愚蠢的错误，Apache默认会为网站根目录下的所有文件提供访问，而我并没有配置任何黑白名单规则，我应该只放行入口文件的。还好我没有提交当前的工作区，当前工作区的MediaWiki的配置文件LocalSettings.php中几乎包含了项目的所有敏感信息。好在LocalSettings.php是PHP文件，Apache只会执行它而不会直接返回源码，且日志显示它从未被请求过，否则就不只是爬取大文件这么简单了。

我立马在服务器上安装了Pi Coding Agent，配置了OpenCode Go的API密钥，请Agent把这些僵尸主机的IP段全部拦截，并把包含extensions/目录下的submodule子模块在内的.git目录彻底删除了。

结果攻击方应该是打算通过ssh暴力破解（我是根据具体表现猜测的，结果Agent的发现证实了这一猜想），导致内存动不动就溢出，我一度用任何手段都连不上实例。

然后，我把阿里云安全组的ssh端口彻底拦截，不让任何人访问，并只开放阿里云Workbench的内网IP。我想终于表面上是告一段落了，但是不知道背地里怎么样，于是我又请Agent为我的服务器做一次全面排查，看看有没有破坏性痕迹、敏感信息泄露、恶意软件植入等安全问题。

结果LLM运行的途中，仍两次遭遇内存泄漏，终端卡死。VNC是最后的稻草，从它那只见系统已经报了一堆因内存不足导致“屠杀”（kill）进程的消息。于是又数次重启，而每次重启时停止实例花费的时间都相当长，我想是僵尸们过于顽固了。

接着，我想我终于找到了内存泄漏的罪魁祸首，我在btop中看到数十个apache进程，每个都占用了数十MiB。我认为这很有可能是人为制造的PHP处理风暴，但不管怎么认为，我都必须停止apache2服务了。

```sh
systemctl stop apache2
```

这个命令是在VNC里面敲的，ssh和基于它的Workbench已经彻底沦陷了。接下来，我终于能顺利地让Agent帮我全面排查并解决安全问题了。下面是Agent的分析和动作：

## 我犯的错误

1. Apache 默认 Require all granted + Options Indexes，我没加任何拒绝规则，隐藏文件全放行。
2. 默认 MPM 配置没为小内存调优——150 个 worker × mod_php 每个几十 MB，爬虫一并发就必然 OOM。

“不幸中的万幸”：敏感配置从未 commit 进 .git。攻击者只拿到了 MediaWiki 官方仓库的元数据（可以从日志里证明：0 次 loose object 请求、0 次 LocalSettings.php 请求），否则就是数据库密码和云密钥泄露。

## Agent的排查过程

排查按"从外到内"分四层推进：网络与进程现状 → 登录痕迹 → 持久化与恶意软件 → Web 泄露面。每一层都追求落到具体证据上。

### 第一层：网络与进程

系统刚重启 53 分钟，load average 仍在 7~12 高位徘徊；1.6G 可用内存只剩几百 MB，swap 用掉了 675MB；数十个 apache2 进程监听 80/443。当前已建立的连接里除了阿里云内网会话，没有任何异常外连——爬虫确实已经被挡在安全组外面了。

### 第二层：登录痕迹

/var/log/auth.log 是这轮排查最有说服力的证据：

- Failed password 共 30,265 次，时间跨度 8/9 00:48 至 8/13 11:13——安全组封禁 SSH 后戛然而止；
- 爆破来源 TOP：

| 来源 IP                  | 尝试次数 |
| ------------------------ | -------- |
| 51.222.47.156            | 6,594    |
| 192.253.248.216          | 2,006    |
| 144.225.6.182            | 1,326    |
| 91.92.47.x / 45.156.87.x | 各 700+  |

- Accepted 共 43 次，全部是公钥认证，密码登录成功 0 次；
- 用 ssh-keygen -lf 核对登录指纹，所有公网来源的成功登录均使用我自己的 ED25519 密钥。

结论：爆破者四天里始终没能拿到 shell，SSH 未被攻破。

### 第三层：持久化与恶意软件

这一层把常见的植入手法过了一遍，全部干净：

- 所有用户的 crontab、/etc/cron.*——只有我自己的数据库备份和 sitemap 任务；
- systemd 自启服务与 timer——无异常条目；
- /etc/ld.so.preload 不存在（rootkit 最常用的劫持点）；
- /tmp、/var/tmp、/dev/shm 无可疑可执行文件；
- /etc/passwd 无新增用户；authorized_keys 只有我自己的两把公钥；
- 全盘搜索 .git：仅剩 ~/clash-for-linux-install/.git，不在 web 目录下；
- webshell 特征扫描（eval/base64_decode/shell_exec 等）零命中，上传目录无 PHP 文件；
- 近期安装的软件包只有 iftop 和 iptables-persistent——都是我自己的防御工具。

### 第四层：泄露面评估（最重要的一层）

Apache 访问日志完整还原了攻击全貌：

- 98,275 条 .git 请求，其中 97,406 条返回 200；
- 来源 IP 全部属于 34.96.0.0/16（Google Cloud 段）；
- 总流出 11.25GB，最大单文件是 vendor 子模块的 165MB pack，被反复下载（DiscussionTools 51MB、VisualEditor 49MB 次之）；
- 攻击脚本用 git-dumper 的方式完整枚举了 config、HEAD、index、logs、hooks、packed-refs 等所有结构，UA 为 python-requests/2.34.2；
- 决定性证据：loose object 请求为 0。如果我曾对 LocalSettings.php 执行过 git add（哪怕从未 commit），攻击者必然会按 index 中的哈希去拉取对应 object —— 0 次请求意味着我的 .git 里只有 MediaWiki 官方仓库的数据，不含任何我自己的文件；
- 对 .env、credentials、sqlite 等敏感路径的探测全部 404；对 LocalSettings.php 的请求记录为 0；
- 各类 POST 漏洞探测（cgi-bin 路径穿越、PHP auto_prepend 注入、xmlrpc）全部被 400/404 挡下。

结论：攻击者搬走的只有开源代码，没有任何一份我的数据。

### OOM 的真相

error.log 里躺着 2,600 多条 Allocation of JIT memory failed, PCRE JIT will be disabled——这是内存耗尽时 PHP 的典型表现。结合 mpm_prefork + MaxRequestWorkers 150 + mod_php 的配置就能还原全貌：150 个 worker 进程，每个加载完整 PHP 解释器吃掉几十 MB，2G 内存的小实例根本承受不住；爬虫并发拉取大文件时，内存被瞬间打爆，OOM killer 开始"屠杀"进程，最终表现为失联。

所以严格来说，压垮服务器的不全是攻击，更多是我自己的默认配置。

## Agent的解决方案

### 1. Apache 拒绝规则

新建 /etc/apache2/conf-available/security-hardening.conf：

```conf
# 拒绝一切点文件（.gitignore、.env 等）
<FilesMatch "^\.">
    Require all denied
</FilesMatch>

# 拒绝 VCS / secret 目录路径
<DirectoryMatch "/\.(git|svn|hg|env)(/|$)">
    Require all denied
</DirectoryMatch>

# 拒绝敏感备份与凭证类扩展
<FilesMatch "\.(sql|dump|bak|old|swp|swo|key|pem|crt|csr|p12|pfx|der|sqlite|db)$">
    Require all denied
</FilesMatch>
```

启用后实测：.git/HEAD → 404、.fresnel.yml → 403、任意 .sql → 403，首页与静态资源不受影响。它与此前我手写的（笔者注：其实是前两次Agent做的工作）RedirectMatch 404 规则互补——404 隐藏文件存在性，403 兜底其余点文件。若追求极致，还可改为"默认拒绝 + 白名单放行入口文件和静态扩展"的严格模式。

### 2. MPM 调优


| 参数                   | 默认 | 调优后 |
| ---------------------- | ---- | ------ |
| StartServers           | 5    | 3      |
| MinSpareServers        | 5    | 3      |
| MaxSpareServers        | 10   | 6      |
| MaxRequestWorkers      | 150  | 20     |
| MaxConnectionsPerChild | 0    | 1000   |

重启 Apache 后内存可用量回到 1G，负载归零。今后即使爬虫再来，20 个 worker 也压不垮这台机器——而且 .git 已经 404，不再存在 165MB 级别的响应。

### 3. fail2ban 三监狱

- sshd：SSH 爆破自动封禁；
- apache-auth：反复触发拒绝路径（AH01630）的客户端自动封禁；
- apache-git-crawler：自定义过滤器，任何请求 .git 路径的 IP 触发 3 次即封 1 天。

自定义过滤器只有一行正则：

```
# /etc/fail2ban/filter.d/apache-git-crawler.conf
[Definition]
failregex = ^<HOST> .*"(?:GET|POST|HEAD|PUT) [^"]*\.git(?:[/?"\s]|$)
ignoreregex =
```

用 fail2ban-regex 对历史日志回放验证，命中 71,499 条攻击记录。Cloudflare 回源段与内网 IP 加入白名单防止误封。

### 4. SSH 加固确认

检查发现 sshd_config 早已是 PasswordAuthentication no + PermitRootLogin prohibit-password，叠加安全组的端口级封锁，形成双层保险。

## 总结和教训

- .git 永不进 web 根；发布用 archive 导出而非 git clone
- Apache 默认全放行 → 默认拒绝、白名单放行
- 小内存机器必须调 MPM/换 php-fpm
- 敏感配置不进 git，进 git 的东西视同已公开
- 出事后先封网再排查，日志是最诚实的目击者
- 纵深防御：安全组 + iptables + fail2ban 每一层都算数
