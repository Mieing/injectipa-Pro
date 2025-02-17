### 使用NewTerm或ssh连接进入/var/mobile/Documents或当前目录。
```
cd /var/mobile/Documents
```

### 克隆仓库
```
git clone https://github.com/Mieing/injectipa-Pro.git
```
### 赋予执行权限
```
chmod +x ./injectipa.sh
```

### 运行脚本
```
./injectipa.sh
```

- 运行```./injectipa.sh```自动创建injectipa文件夹

- 将需注入dylib文件放入```./dylib```文件夹

- 将需注入ipa文件放入```./ipa```文件夹，再次运行```./injectipa.sh```

- 批量解压提取dylib： [MDeb](https://github.com/Mieing/MDeb)
