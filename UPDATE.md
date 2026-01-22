# 开发更新说明

## 1# BUG修复

- vue默认12000ms超时问题

```
在vue前端代码axios中设置了12000ms的默认超时，导致超大数据前端超时返回，由于没有前端源码，直接修改混淆后的代码
相关代码在：https://github.com/SurrealSky/ARL/blob/main/docker/frontend/js/app~d0ae3f07.210036a0.js 中
如下：
l=o.a.create({baseURL:"/api",timeout:12e3});
修改为：
l=o.a.create({baseURL:"/api",timeout:30e3});
```

# 注意事项

## python环境

- 确保环境中存在 **python3.6 , pip3.6** 版本，并且命令可用。

