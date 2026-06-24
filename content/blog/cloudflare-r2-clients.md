+++
title = "Cloudflare R2 对象存储客户端的几种方案"
slug = "cloudflare-r2-clients"
date = "2026-06-21T18:26:00+08:00"
tags = ["Cloudflare","图床"]
+++

1. [PicList](https://piclist.cn/)或[PicGo](https://docs.picgo.app/zh/gui/)：使用S3 API或[社区插件](https://github.com/JYbill/picgo-plugin-cloudflare-r2)上传图片 记得勾选“设置-上传-上传处理-相册内删除时同步删除云端文件” 参考[这篇文章](https://eastondev.com/blog/zh/posts/dev/20251130-r2-picgo-setup/#%E7%AC%AC%E4%BA%8C%E6%AD%A5%E9%85%8D%E7%BD%AE-s3-%E5%9B%BE%E5%BA%8A%E5%8F%82%E6%95%B0) 尤其关于文件路径 占位符参考S3插件的[README.md](https://github.com/wayjam/picgo-plugin-s3)：
   > 文件路径（Upload Path）推荐几种格式：
   > 
   > - `{year}/{month}/{md5}.{extName}` - 按年月分类，文件名用 MD5 避免重复
   > - `PicGo/{fullName}` - 全部放在 PicGo 文件夹下，保持原文件名
   > - `{year}/{month}/{fullName}` - 按年月分类，保持原文件名
   > 
   > 我个人用的是第一种，既避免了文件名重复，又方便按时间管理。
   > 
   > 重要提醒：路径开头不要加`/`！直接写 `{year}/{month}/...` 就行。如果加了 `/`，可能会导致上传失败或路径错误。
2. ~~[R2Client](https://r2client.com/)：桌面客户端 支持预览图片 看着应该是vide coding的产物 ui明暗主题有问题 好在功能较强 还有一些增强功能需要会员~~（三天试用说是 别用 纯圈钱玩意）
3. [R2Explorer](https://r2explorer.com/)：基于Cloudflare Workers的无服务器web应用 非常简陋的文件管理器 功能跟官网控制台基本没区别 不如用后者
4. [官网控制台](https://dash.cloudflare.com/)：构建-存储和数据库-R2对象存储-概述-存储桶 仅提供简单的文件管理功能
