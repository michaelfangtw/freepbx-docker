# FreePBX Docker 架構分析

## 📋 概述

本文件詳細分析 Dockerfile 和 docker-compose.yml 的設計、問題和改進建議。

---

## 🏗️ Dockerfile 分析

### 1. 基礎映像 (Line 1)
```dockerfile
FROM debian:12
```

**分析：**
- ✅ 使用 Debian 12（穩定版）
- ✅ 輕量級 Linux 發行版
- ⚠️ 安全建議：應明確指定 digest 以確保供應鏈安全

**改進建議：**
```dockerfile
FROM debian:12@sha256:<hash>  # Pin to specific version
```

---

### 2. 依賴安裝 (Lines 3-20)

#### 問題 1️⃣：多個 RUN 指令 (Lines 3, 9, 13)
```dockerfile
RUN apt-get update && ...      # Line 3
RUN apt -y install ...         # Line 9
RUN apt -y install ...         # Line 13
```

**問題：**
- ❌ 每個 RUN 都建立新層，增加映像大小
- ❌ 重複安裝相同套件（git, curl, wget, libssl-dev 等）
- ❌ apt-get update 分離導致快取失效

**改進建議：**
```dockerfile
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
      build-essential git curl wget libnewt-dev libssl-dev \
      libncurses5-dev subversion libsqlite3-dev libjansson-dev libxml2-dev uuid-dev \
      default-libmysqlclient-dev htop sngrep lame ffmpeg mpg123 \
      vim openssh-server apache2 cron \
      mariadb-client bison flex php8.2 php8.2-curl php8.2-cli php8.2-common php8.2-mysql php8.2-gd \
      php8.2-mbstring php8.2-intl php8.2-xml php-pear sox \
      sqlite3 pkg-config automake libtool autoconf \
      unixodbc-dev libasound2-dev libogg-dev libvorbis-dev libicu-dev libcurl4-openssl-dev \
      odbc-mariadb libical-dev libneon27-dev libsrtp2-dev libspandsp-dev sudo \
      libtool-bin python-dev-is-python3 software-properties-common nodejs npm ipset iptables fail2ban php-soap \
      expect && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

#### 問題 2️⃣：重複套件安裝
- git, curl, wget, libssl-dev, libncurses5-dev, subversion, libsqlite3-dev, libjansson-dev, libxml2-dev, uuid-dev 在多個 RUN 中重複出現

---

### 3. Asterisk 編譯 (Lines 22-36)

**分析：**
```dockerfile
wget -O /usr/src/asterisk-20-current.tar.gz ... && \
tar xvf ... && \
cd /usr/src/asterisk-20*/ && \
contrib/scripts/get_mp3_source.sh && \
contrib/scripts/install_prereq install && \
./configure --libdir=/usr/lib64 --with-pjproject-bundled --with-jansson-bundled && \
make menuselect.makeopts && \
menuselect/menuselect --enable app_macro menuselect.makeopts && \
make && \
make install && \
make samples && \
make config && \
ldconfig
```

**優點：**
- ✅ 使用最新 Asterisk 20
- ✅ 捆綁 PJProject 和 Jansson（依賴項自管理）
- ✅ 啟用 app_macro 模組
- ✅ 執行 ldconfig 更新連結庫快取

**問題：**
- ⚠️ 沒有清理編譯臨時檔案（/usr/src/asterisk-20*）
- ⚠️ 編譯耗時，可能導致層快取失效
- ⚠️ 未驗證下載檔案完整性（無 checksum）

**改進建議：**
```dockerfile
RUN wget -O /usr/src/asterisk-20-current.tar.gz ... && \
    echo "<checksum>  asterisk-20-current.tar.gz" | sha256sum -c - && \
    tar xzf /usr/src/asterisk-20-current.tar.gz -C /usr/src/ && \
    cd /usr/src/asterisk-20*/ && \
    ... (編譯步驟) ... && \
    cd / && \
    rm -rf /usr/src/asterisk-20* /usr/src/asterisk-20-current.tar.gz
```

---

### 4. Asterisk 使用者和權限設定 (Lines 37-52)

**分析：**
```dockerfile
groupadd asterisk && \
useradd -r -d /var/lib/asterisk -g asterisk asterisk && \
usermod -aG audio,dialout asterisk && \
chown -R asterisk:asterisk /etc/asterisk && \
chown -R asterisk:asterisk /var/lib/asterisk && \
chown -R asterisk:asterisk /var/log/asterisk && \
chown -R asterisk:asterisk /var/spool/asterisk && \
chown -R asterisk:asterisk /usr/lib64/asterisk && \
sed -i 's|#AST_USER|AST_USER|' /etc/default/asterisk && \
sed -i 's|#AST_GROUP|AST_GROUP|' /etc/default/asterisk && \
sed -i 's|;runuser|runuser|' /etc/asterisk/asterisk.conf && \
sed -i 's|;rungroup|rungroup|' /etc/asterisk/asterisk.conf && \
echo "/usr/lib64" >> /etc/ld.so.conf.d/x86_64-linux-gnu.conf && \
ldconfig
```

**優點：**
- ✅ 以非 root 使用者執行 Asterisk（安全性最佳實踐）
- ✅ 設定正確的群組權限（audio, dialout）
- ✅ 將 /usr/lib64 加入 LD_LIBRARY_PATH

**問題：**
- ⚠️ sed -i 使用可能失敗但未檢查狀態
- ⚠️ 如果目錄不存在，chown 不會失敗但可能不如預期

**改進建議：**
```dockerfile
RUN groupadd asterisk && \
    useradd -r -d /var/lib/asterisk -g asterisk asterisk && \
    usermod -aG audio,dialout asterisk && \
    # 確保目錄存在
    mkdir -p /etc/asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk && \
    chown -R asterisk:asterisk /etc/asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk /usr/lib64/asterisk && \
    # 配置
    sed -i 's/#AST_USER/AST_USER/' /etc/default/asterisk && \
    sed -i 's/#AST_GROUP/AST_GROUP/' /etc/default/asterisk && \
    sed -i 's/;runuser/runuser/' /etc/asterisk/asterisk.conf && \
    sed -i 's/;rungroup/rungroup/' /etc/asterisk/asterisk.conf && \
    echo "/usr/lib64" >> /etc/ld.so.conf.d/x86_64-linux-gnu.conf && \
    ldconfig
```

---

### 5. Apache 配置 (Lines 54-60)

**分析：**
```dockerfile
sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php/8.2/apache2/php.ini && \
sed -i 's/\(^memory_limit = \).*/\1256M/' /etc/php/8.2/apache2/php.ini && \
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf && \
sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf && \
a2enmod rewrite && \
rm /var/www/html/index.html
```

**優點：**
- ✅ 設定 PHP 上傳限制（20M）
- ✅ 設定 PHP 記憶體限制（256M）
- ✅ Apache 以 asterisk 使用者執行
- ✅ 啟用 mod_rewrite

**潛在問題：**
- ⚠️ php.ini 路徑應根據 PHP 版本驗證
- ⚠️ AllowOverride All 可能影響安全性（允許 .htaccess 覆蓋）

---

### 6. ODBC 配置 (Lines 61-63)

**分析：**
```dockerfile
COPY odbc.ini /etc/odbc.ini
COPY odbcinst.ini /etc/odbcinst.ini
```

**優點：**
- ✅ 預先配置 ODBC

**問題：**
- ⚠️ 檔案權限未明確設定
- ⚠️ 未驗證檔案存在

**改進建議：**
```dockerfile
COPY odbc.ini /etc/odbc.ini
COPY odbcinst.ini /etc/odbcinst.ini
RUN chmod 644 /etc/odbc.ini /etc/odbcinst.ini && \
    chown root:root /etc/odbc.ini /etc/odbcinst.ini
```

---

### 7. SSL 配置 (Lines 64-68)

**分析：**
```dockerfile
COPY ./default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
RUN a2ensite default-ssl && \
    a2enmod ssl
```

**優點：**
- ✅ 啟用 HTTPS

**問題：**
- ⚠️ default-ssl.conf 檔案應該預先提供
- ⚠️ 自簽名憑證應在執行時生成（不應在映像中）

---

### 8. FreePBX 安裝 (Lines 70-75)

**分析：**
```dockerfile
wget -O /usr/local/src/freepbx-17.0-latest-EDGE.tgz ... && \
tar zxvf /usr/local/src/freepbx-17.0-latest-EDGE.tgz -C /usr/local/src && \
rm /usr/src/asterisk-20-current.tar.gz && \
rm /usr/local/src/freepbx-17.0-latest-EDGE.tgz && \
apt-get clean
```

**優點：**
- ✅ 清理臨時檔案（節省層大小）
- ✅ apt-get clean 清理套件快取

**問題：**
- ⚠️ 使用 LATEST-EDGE 版本不穩定
- ⚠️ 沒有解壓後的檔案清理
- ⚠️ 未驗證下載完整性

**改進建議：**
```dockerfile
RUN wget -O /usr/local/src/freepbx-17.0.tar.gz http://mirror.freepbx.org/modules/packages/freepbx/freepbx-17.0.tar.gz && \
    echo "<checksum>  freepbx-17.0.tar.gz" | sha256sum -c - && \
    tar xzf /usr/local/src/freepbx-17.0.tar.gz -C /usr/local/src && \
    rm /usr/src/asterisk-20-current.tar.gz /usr/local/src/freepbx-17.0.tar.gz && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
```

---

### 9. 啟動腳本和 EXPOSE (Lines 76-84)

**分析：**
```dockerfile
ADD run-httpd.sh /run-httpd.sh
RUN chmod -v +x /run-httpd.sh

# 取消VOLUME 自行mount
# VOLUME [ "/var/lib/asterisk", "/etc/asterisk", "/usr/lib64/asterisk", "/var/www/html", "/var/log/asterisk" ]

EXPOSE 443 4569 4445 5060 5060/udp 5160/udp 18000-18100/udp

CMD ["/run-httpd.sh"]
```

**優點：**
- ✅ 移除 VOLUME 指令（讓 docker-compose.yml 管理）
- ✅ 公開必要埠號

**問題：**
- ⚠️ EXPOSE 缺少埠 80（HTTP）
- ⚠️ run-httpd.sh 未驗證

---

## 🔧 docker-compose.yml 分析

### 1. 版本和服務定義 (Lines 1-15)

**分析：**
```yaml
version: '2'

services:
  server:
    container_name: freepbx_server
    image: freepbx-docker:20.17
    ports:
      - 80:80
      - 443:443
      - 4445:4445
      - 4569:4569/udp
      - 5060
      - 5060:5060/udp
      - 5160:5160/udp
      - 18000-18100:18000-18100/udp
```

**問題：**

#### ⚠️ 版本 2 已棄用
- Docker Compose v2 已被淘汰，應使用 v3.8+

#### ⚠️ 埠號配置混亂
```yaml
- 5060           # ❌ 不清楚協議，應避免
- 5060:5060/udp  # ✅ 明確 UDP
```

**改進建議：**
```yaml
version: '3.8'

services:
  freepbx:
    container_name: freepbx_server
    image: freepbx-docker:20.17
    ports:
      - "80:80"         # HTTP
      - "443:443"       # HTTPS
      - "4445:4445"     # Alternative HTTPS
      - "4569:4569/udp" # IAX2
      - "5060:5060"     # SIP TCP
      - "5060:5060/udp" # SIP UDP
      - "5160:5160/udp" # IAX2 RTP
      - "18000-18100:18000-18100/udp" # RTP stream
```

---

### 2. 環境變數 (Lines 16-39)

**分析：**
```yaml
environment:
  - TZ=Asia/Taipei
  - DB_USER=asterisk
  - DB_PASS=asteriskpass      # ❌ 硬編碼密碼
  - DBENGINE=mysql
  - DBNAME=asterisk
  - DBHOST=192.168.0.2        # ❌ 硬編碼 IP
  - DBPORT=3306
  - CDRDBNAME=asteriskcdrdb
  - DBUSER=asterisk
  - DBPASS=asterisk           # ❌ 硬編碼密碼
  - USER=asterisk
  - GROUP=asterisk
  - WEBROOT=/var/www/html
  - ASTETCDIR=/etc/asterisk
  - ASTMODDIR=/usr/lib64/asterisk/modules
  - ASTVARLIBDIR=/var/lib/asterisk
  - ASTAGIDIR=/var/lib/asterisk/agi-bin
  - ASTSPOOLDIR=/var/spool/asterisk
  - ASTRUNDIR=/var/run/asterisk
  - AMPBIN=/var/lib/asterisk/bin
  - AMPSBIN=/usr/sbin
  - AMPCGIBIN=/var/www/cgi-bin
  - AMPPLAYBACK=/var/lib/asterisk/playback
```

**問題：**

#### 🔴 安全性問題：硬編碼敏感資訊
- DB_PASS 和 DBPASS 硬編碼在檔案中
- 應使用 `.env` 檔案或 secrets 管理

**改進建議：**
```yaml
environment:
  - TZ=Asia/Taipei
  - DB_USER=${DB_USER:-asterisk}
  - DB_PASS=${DB_PASS}              # 從 .env 讀取
  - DBENGINE=mysql
  - DBNAME=${DBNAME:-asterisk}
  - DBHOST=mariadb                  # 使用服務名稱（自動解析）
  - DBPORT=3306
  - CDRDBNAME=${CDRDBNAME:-asteriskcdrdb}
  - DBUSER=${DB_USER:-asterisk}
  - DBPASS=${DB_PASS}
  - USER=asterisk
  - GROUP=asterisk
  - WEBROOT=/var/www/html
  - ASTETCDIR=/etc/asterisk
  - ASTMODDIR=/usr/lib64/asterisk/modules
  - ASTVARLIBDIR=/var/lib/asterisk
```

#### ⚠️ 環境變數冗餘
- DBHOST 應設定為 `mariadb`（服務名稱），而不是硬編碼 IP
- DBUSER 和 DB_USER 重複

---

### 3. 卷宗配置 (Lines 40-46)

**分析：**
```yaml
volumes:
  - ./certs:/etc/apache2/certs    # ✅ Bind mount (本地)
  - wwwvol:/var/www/html          # ❌ Named volume
  - varvol:/var/lib/asterisk      # ❌ Named volume
  - etcvol:/etc/asterisk          # ❌ Named volume
  - usrvol:/usr/lib64/asterisk    # ❌ Named volume
  - logvol:/var/log/asterisk      # ❌ Named volume
```

**問題：**

#### 🔴 使用 Named Volumes 不適合持久化
- Named volumes 不易備份和遷移
- 無法輕鬆存取主機上的檔案
- 應使用 bind mounts（本地目錄）

**改進建議：**
```yaml
volumes:
  - ./data/certs:/etc/apache2/certs           # SSL 憑證
  - ./data/var/lib:/var/lib/asterisk          # Asterisk 資料
  - ./data/etc/asterisk:/etc/asterisk         # Asterisk 配置
  - ./data/usr/lib64:/usr/lib64/asterisk      # Asterisk 模組
  - ./data/log:/var/log/asterisk              # 日誌
  - ./data/www:/var/www/html                  # 網頁內容
```

---

### 4. MariaDB 服務 (Lines 52-64)

**分析：**
```yaml
mariadb:
  container_name: freepbx_mariadb
  image: mariadb:latest           # ❌ 使用 latest
  restart: always
  volumes:
    - ./datadb:/var/lib/mysql
    - ./sql:/docker-entrypoint-initdb.d
  environment:
    - TZ=Asis/Taipei              # ❌ 拼寫錯誤
    - MYSQL_ROOT_PASSWORD=asterisk # ❌ 硬編碼密碼
  networks:
    asterisk:
      ipv4_address: 192.168.0.2
```

**問題：**

#### 🔴 使用 `latest` 標籤
- `mariadb:latest` 不確定版本
- 應指定特定版本（e.g., `mariadb:10.11`）

#### 🔴 拼寫錯誤
```yaml
TZ=Asis/Taipei    # ❌ 應為 Asia/Taipei
```

#### 🔴 硬編碼密碼
- MYSQL_ROOT_PASSWORD 應來自環境或 .env

**改進建議：**
```yaml
mariadb:
  container_name: freepbx_mariadb
  image: mariadb:10.11             # 明確版本
  restart: always
  volumes:
    - ./datadb:/var/lib/mysql
    - ./sql:/docker-entrypoint-initdb.d
  environment:
    - TZ=Asia/Taipei               # 修正拼寫
    - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
    - MYSQL_DATABASE=${DBNAME:-asterisk}
    - MYSQL_USER=${DB_USER:-asterisk}
    - MYSQL_PASSWORD=${DB_PASS}
  networks:
    asterisk:
      ipv4_address: 192.168.0.2
  healthcheck:
    test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
    interval: 10s
    timeout: 5s
    retries: 5
```

---

### 5. 卷宗定義 (Lines 66-71)

**分析：**
```yaml
volumes:
  varvol:
  etcvol:
  usrvol:
  wwwvol:
  logvol:
```

**問題：**
- ❌ 使用 named volumes（不適合持久化重要資料）
- ❌ 無法版本控制或備份
- ❌ 無法輕鬆將資料轉移到其他主機

**改進建議：**
```yaml
# 刪除這個部分，改用 bind mounts（在 services > volumes 中定義）
```

---

### 6. 網路定義 (Lines 73-82)

**分析：**
```yaml
networks:
 asterisk:                    # ⚠️ 縮排不一致
    driver: bridge
    driver_opts:
      com.docker.network.enable_ipv6: "false"
    ipam:
      driver: default
      config:
      - subnet: 192.168.0.0/24
        gateway: 192.168.0.1
```

**優點：**
- ✅ 自訂橋接網路
- ✅ 固定 IP 位址
- ✅ 禁用 IPv6

**問題：**
- ⚠️ YAML 縮排錯誤（asterisk 不對齊）
- ⚠️ 固定 IP 可能與主機網路衝突

**改進建議：**
```yaml
networks:
  asterisk:
    driver: bridge
    driver_opts:
      com.docker.network.enable_ipv6: "false"
    ipam:
      driver: default
      config:
        - subnet: 192.168.0.0/24
          gateway: 192.168.0.1
```

---

## 📊 問題摘要

### 🔴 關鍵問題
| 項目 | 問題 | 影響 | 優先級 |
| --- | --- | --- | --- |
| 硬編碼密碼 | DB_PASS、MYSQL_ROOT_PASSWORD 硬編碼 | 安全漏洞 | 🔴 高 |
| Named Volumes | 使用 named volumes 而非 bind mounts | 難以備份/遷移 | 🔴 高 |
| Compose 版本 | 使用已棄用的 v2 | 未來不相容 | 🟠 中 |
| MariaDB 版本 | 使用 `latest` 標籤 | 版本不可預測 | 🟠 中 |

### 🟠 中等問題
| 項目 | 問題 | 影響 | 優先級 |
| --- | --- | --- | --- |
| 多個 RUN 指令 | 映像層過多 | 映像大小、構建快取 | 🟠 中 |
| Asterisk 編譯清理 | 沒有完全清理臨時檔案 | 映像大小 | 🟠 中 |
| 拼寫錯誤 | TZ=Asis/Taipei | 時區設定失效 | 🟠 中 |
| 埠號配置 | 5060 不清楚協議 | 混淆 | 🟠 中 |

### 🟡 低優先級
| 項目 | 問題 | 影響 | 優先級 |
| --- | --- | --- | --- |
| Checksum 驗證 | 沒有驗證下載 | 安全性 | 🟡 低 |
| YAML 縮排 | 網路定義縮排不一致 | 可讀性 | 🟡 低 |
| 檔案權限 | ODBC 配置未設定權限 | 潛在問題 | 🟡 低 |

---

## ✅ 改進檢查清單

### Dockerfile 改進
- [ ] 合併 RUN 指令以減少層
- [ ] 移除重複的套件安裝
- [ ] 新增 checksum 驗證
- [ ] 完整清理編譯臨時檔案
- [ ] 明確設定檔案權限
- [ ] 更新至特定版本而非 LATEST-EDGE

### docker-compose.yml 改進
- [ ] 升級至 v3.8+
- [ ] 從 .env 讀取敏感資訊
- [ ] 將 named volumes 改為 bind mounts
- [ ] 修正 MariaDB 版本標籤
- [ ] 修正 TZ 拼寫錯誤
- [ ] 新增 MariaDB healthcheck
- [ ] 整合 YAML 縮排
- [ ] 清理卷宗定義

### 配置管理
- [ ] 建立 `.env.example` 檔案
- [ ] 建立 `.env` 檔案（不版本控制）
- [ ] 使用環境變數替代硬編碼值

---

## 🔗 參考資源

- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Compose v3 Reference](https://docs.docker.com/compose/compose-file/compose-file-v3/)
- [Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
