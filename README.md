# ARL(Asset Reconnaissance Lighthouse)资产侦察灯塔系统
[![Python 3.6](https://img.shields.io/badge/python-3.6-yellow.svg)](https://www.python.org/)
[![Docker Images](https://img.shields.io/docker/pulls/tophant/arl.svg)](https://hub.docker.com/r/tophant/arl)
[![Github Issues](https://img.shields.io/github/issues/TophantTechnology/ARL.svg)](https://github.com/TophantTechnology/ARL/issues)
[![Github Stars](https://img.shields.io/github/stars/TophantTechnology/ARL.svg)](https://github.com/TophantTechnology/ARL/stargazers)

## 1# 介绍

### 1.1 说明

- **原始项目：[TophantTechnology/ARL](https://github.com/TophantTechnology/ARL)最新版本**
- **本项目来自于https://github.com/Aabyss-Team/ARL V2.6.3 版本进行的二次开发**
- **本项目目前去除了docker安装功能，仅支持源码安装**

### 1.2 安装ARL

**ARL安装命令如下**

```
wget https://raw.githubusercontent.com/Aabyss-Team/ARL/master/misc/setup-arl.sh
chmod +x setup-arl.sh
./setup-arl.sh
```

通过以下命令确认服务状态（如果全部运行正常那就没问题）：

```
systemctl status mongod
systemctl status rabbitmq-server
systemctl status arl-web
systemctl status arl-worker
systemctl status arl-worker-github
systemctl status arl-scheduler
systemctl status nginx
```

安装后，请前往ARL-Web页面：`https://IP:5003/`

账号密码为随机生成，会打印在控制台

### 1.3 安装问题

1.查看/opt/ARL/arl_worker.log文件，涉及执行权限问题，请使用命令 sudo chmod -R 777 /opt/ARL 解决。

## 3# 系统要求

目前暂不支持Windows，系统配置建议：CPU:4线程 内存:8G 带宽:10M。  
由于自动资产发现过程中会有大量的的发包，建议采用云服务器可以带来更好的体验。

## 4# 任务选项说明

| 编号 |      选项      |                                       说明                                        |
| --- | -------------- | -------------------------------------------------------------------------------- |
| 1    | 任务名称        | 任务名称                                                                          |
| 2    | 任务目标        | 任务目标，支持IP，IP段和域名。可一次性下发多个目标                                      |
| 3    | 域名爆破类型    | 对域名爆破字典大小, 大字典：常用2万字典大小。测试：少数几个字典，常用于测试功能是否正常        |
| 4    | 端口扫描类型    | ALL：全部端口，TOP1000：常用top 1000端口，TOP100：常用top 100端口，测试：少数几个端口 |
| 5    | 域名爆破        | 是否开启域名爆破                                                                   |
| 6    | DNS字典智能生成 | 根据已有的域名生成字典进行爆破                                                      |
| 7    | 域名查询插件    |  已支持的数据源为13个，`alienvault`, `certspotter`,`crtsh`,`fofa`,`hunter` 等        |
| 8    | ARL 历史查询    | 对arl历史任务结果进行查询用于本次任务                                                |
| 9    | 端口扫描        | 是否开启端口扫描，不开启站点会默认探测80,443                                         |
| 10   | 服务识别        | 是否进行服务识别，有可能会被防火墙拦截导致结果为空                                     |
| 11   | 操作系统识别    | 是否进行操作系统识别，有可能会被防火墙拦截导致结果为空                                 |
| 12   | SSL 证书获取    | 对端口进行SSL 证书获取                                                             |
| 13   | 跳过CDN       | 对判定为CDN的IP, 将不会扫描端口，并认为80，443是端口是开放的                             |
| 14   | 站点识别        | 对站点进行指纹识别                                                                 |
| 15   | 搜索引擎调用    | 利用搜索引擎搜索下发的目标爬取对应的URL和子域名                                                       |
| 16   | 站点爬虫        | 利用静态爬虫对站点进行爬取对应的URL                                                  |
| 17   | 站点截图        | 对站点首页进行截图                                                                 |
| 18   | 文件泄露        | 对站点进行文件泄露检测，会被WAF拦截                                                  |
| 19   | Host 碰撞        | 对vhost配置不当进行检测                                                |
| 20    | nuclei 调用    | 调用nuclei 默认PoC 对站点进行检测 ，会被WAF拦截，请谨慎使用该功能                |
| 21   | WIH 调用      | 调用 WebInfoHunter 工具在JS中收集域名,AK/SK等信息                     |
| 22   | WIH 监控任务   | 对资产分组中的站点周期性 调用 WebInfoHunter 工具在JS中域名等信息进行监控  |

## 5# 配置参数说明

Docker环境配置文件路径 `docker/config-docker.yaml`

|       配置        |                 说明                 |
| ----------------- | ------------------------------------ |
| CELERY.BROKER_URL | rabbitmq连接信息                      |
| MONGO             | mongo 连接信息                        |
| QUERY_PLUGIN      | 域名查询插件数据源Token 配置             |
| GEOIP             | GEOIP 数据库路径信息                  |
| FOFA              | FOFA API 配置信息                     |
| DINGDING          | 钉钉消息推送配置                     |
| EMAIL              | 邮箱发送配置                     |
| GITHUB.TOKEN      |  GITHUB 搜索 TOKEN                 |
| ARL.AUTH          | 是否开启认证，不开启有安全风险          |
| ARL.API_KEY       | arl后端API调用key，如果设置了请注意保密 |
| ARL.BLACK_IPS     | 为了防止SSRF，屏蔽的IP地址或者IP段      |
| ARL.PORT_TOP_10     | 自定义端口，对应前端端口测试选项      |
| ARL.DOMAIN_DICT     | 域名爆破字典，对应前端大字典选项      |
| ARL.FILE_LEAK_DICT     | 文件泄漏字典      |
| ARL.DOMAIN_BRUTE_CONCURRENT     | 域名爆破并发数配置      |
| ARL.ALT_DNS_CONCURRENT     | 组合生成的域名爆破并发数      |
| PROXY.HTTP_URL     | HTTP代理URL设置      |
| FEISHU | 飞书消息推送配置 |
| WXWORK | 企业微信消息推送 |


## 6# 忘记密码重置

当忘记了登录密码，可以执行下面的命令，然后使用 `admin/admin123` 就可以登录了。
```
#源码忘记密码
mongo
use arl
db.user.drop()
db.user.insert({ username: 'admin',  password: hex_md5('arlsalt!@#'+'admin123') })
```
