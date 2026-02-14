# FreePBX Docker

**[繁體中文](#中文版) | [English](#english-version)**

**📚 重要文件 | Important Files:**

- **[⚡ 快速開始](./SETUP.md)** ← 從這裡開始（3 分鐘）| **[Quick Start](./SETUP.md)** ← Start here (3 minutes)
- [🚀 使用指南](./USAGE_GUIDE.md) | [Usage Guide](./USAGE_GUIDE.md)
- [⚡ 快速參考](./QUICK_REFERENCE.md) | [Quick Reference](./QUICK_REFERENCE.md)
- [🔐 .env 配置指南](./ENV_GUIDE.md) | [.env Configuration Guide](./ENV_GUIDE.md)
- [🏗️ Dockerfile 分析](./ARCHITECTURE_ANALYSIS.md) | [Dockerfile Analysis](./ARCHITECTURE_ANALYSIS.md)
- [🔧 docker-compose 分析](./DOCKER_COMPOSE_ANALYSIS.md) | [docker-compose Analysis](./DOCKER_COMPOSE_ANALYSIS.md)
- [🎙️ UniMRCP 設置](./UNIMRCP_SETUP.md) | [UniMRCP Setup](./UNIMRCP_SETUP.md) - 語音辨識和 TTS | Speech recognition & TTS
- [📦 數據掛載 SOP](./MOUNT_SOP.md) | [Mount SOP](./MOUNT_SOP.md) - 完整遷移指南 | Complete migration guide
- [🧩 FreePBX 模塊](./FREEPBX_MODULES.md) | [FreePBX Modules](./FREEPBX_MODULES.md) - 已安裝模塊說明 | Installed modules guide

---

## 📋 Overview | 概覽

這是一個完整的 Docker 電話系統解決方案，整合了 Asterisk、FreePBX 和 MariaDB。
This is a complete Docker-based telephony solution integrating Asterisk, FreePBX, and MariaDB.

本專案提供了一個容器化的 PBX 系統，用於 VoIP 通訊並具有基於網頁的管理介面。
This project provides a containerized PBX system for VoIP communications with web-based management interface.

本儲存庫包含用於部署功能完整的 FreePBX 系統的 Docker 配置，包含以下元件：
This repository contains Docker configurations for deploying a fully functional FreePBX system with the following components:

### 🔧 系統元件 | System Components

- **Asterisk 20**：開源 PBX 軟體 | Open-source PBX software
- **FreePBX 17.0**：基於網頁的管理介面 | Web-based management interface
- **MariaDB 10.11**：PBX 設定和 CDR 記錄的資料庫伺服器 | Database server for PBX configuration and CDR storage
- **Apache 2.4**：支援 PHP 8.2 的網頁伺服器 | Web server with PHP 8.2 support
- **UniMRCP 1.8.0** ✨ NEW：語音辨識和文字轉語音支持 | Speech recognition and text-to-speech support

---

## 🚀 快速開始 | Quick Start

**👉 [從這裡開始：SETUP.md (3 分鐘)](./SETUP.md)** ← 新安裝或遷移請遵循此指南
**👉 [Start here: SETUP.md (3 minutes)](./SETUP.md)** ← Follow this for fresh install or migration

### 先決條件 | Prerequisites

- Docker 和 Docker Compose 已安裝 | Docker & Docker Compose installed
- 4GB+ RAM 可用 | 4GB+ RAM available
- SIP 協議的網路存取 | Network access for SIP protocols

### 前置作業 | Before You Start

在執行 `docker-compose up` 之前的必要設定步驟：
Essential setup steps before running `docker-compose up`:

**1. 複製儲存庫 | Clone the repository**

```bash
git clone <repository-url>
cd freepbx-docker
```

**2. 建立 .env 配置檔案 | Create .env configuration file** (CRITICAL - 不要跳過 / don't skip!)

```bash
cp .env.example .env
# 編輯 .env 並更改這些密碼 | Edit .env and change these passwords:
# - DB_PASS=<strong-password>
# - MYSQL_ROOT_PASSWORD=<strong-password>
```

**3. 選擇你的工作流程 | Choose your workflow:**

- **全新安裝 | Fresh Install**: 建立空目錄，容器初始化資料 | Create empty directories, container initializes data
- **遷移 | Migration**: 先使用 `docker cp` 從舊容器提取資料 | Use `docker cp` to extract data from existing container first

**4. 建立資料目錄 | Create data directories** (適用於兩種工作流程 / for both workflows)

```bash
mkdir -p data/{certs,lib,etc,www,log,monitor}
mkdir -p datadb
```

#### 5. 僅限遷移 | For Migration Only: 提取現有資料 | Extract existing data

```bash
# 如果從現有容器遷移 | If migrating from existing container:
docker cp <container-id>:/var/lib/asterisk/. ./data/lib/
docker cp <container-id>:/etc/asterisk/. ./data/etc/
docker cp <container-id>:/var/www/html/. ./data/www/
# 詳細遷移步驟見 SETUP.md | See SETUP.md for complete migration steps
```

**現在你可以執行 | Now you can run:**

```bash
docker-compose up -d
```

### 兩種工作流程 | Two Workflows

本專案支持兩種不同的工作流程：
This project supports two distinct workflows:

**🆕 全新安裝 | Fresh Installation** - 從零開始啟動新的 FreePBX 系統 | Starting a new FreePBX system from scratch

- 空目錄，容器用預設值初始化 | Empty directories, containers initialize with defaults
- 3 分鐘設定時間 | 3 minutes setup time
- 請參閱 [SETUP.md - 全新安裝](./SETUP.md#-fresh-installation-3-minutes) | See [SETUP.md - Fresh Installation](./SETUP.md#-fresh-installation-3-minutes)

**🔄 遷移 | Migration** - 從現有 FreePBX 容器移動資料 | Moving data from existing FreePBX container

- 先使用 `docker cp` 從舊容器提取資料 | Use `docker cp` to extract data from old container first
- 綁定掛載到已填充的目錄 | Bind mount to populated directories
- 保留所有現有配置 | Preserves all existing configuration
- 請參閱 [SETUP.md - 遷移](./SETUP.md#-migration-from-existing-container) | See [SETUP.md - Migration](./SETUP.md#-migration-from-existing-container)

### 首次訪問 | First Access

- 訪問 `https://localhost/admin` | Visit `https://localhost/admin`
- 跟隨 FreePBX 設定向導 | Follow the FreePBX setup wizard
- 建立管理員帳號並設定分機 | Create admin account and configure extensions

---

## 📊 主要功能 | Key Features

- ✅ 完整的 FreePBX 電話系統 | Complete FreePBX telephony system
- ✅ 使用 Docker Compose 容器化 | Containerized with Docker Compose
- ✅ 持久卷宗保護資料 | Persistent volumes for data protection
- ✅ 自訂橋接網路，固定 IP | Custom bridge network with fixed IPs
- ✅ SSL/HTTPS 支援 | SSL/HTTPS support
- ✅ ODBC 資料庫連線 | ODBC database connectivity
- ✅ 完整 SIP 和 IAX2 協議支援 | Full SIP and IAX2 protocol support
- ✨ **UniMRCP 集成** - 語音辨識和文字轉語音 | **UniMRCP Integration** - Speech recognition & TTS
  - 自動語音應答 (IVR) | Automatic voice response (IVR)
  - 語音辨識 (ASR) | Automatic speech recognition (ASR)
  - 文字轉語音 (TTS) | Text-to-speech synthesis (TTS)
  - MRCP v1/v2 協議支持 | MRCP v1/v2 protocol support

---

## 📁 專案結構 | Project Structure

```
freepbx-docker/
├── Dockerfile                  # FreePBX 映像定義 | FreePBX image definition
├── docker-compose.yml          # 服務協調 | Service orchestration
├── run-httpd.sh               # 容器啟動腳本 | Container startup script
├── certs.sh                   # SSL 憑證生成 | SSL certificate generation
├── compose.sh                 # Docker Compose 包裝器 | Docker Compose wrapper
├── SETUP.md                   # 快速設定指南 | Quick setup guide
├── USAGE_GUIDE.md            # 完整使用指南 | Complete usage guide
├── QUICK_REFERENCE.md        # 快速指令參考 | Quick command reference
├── ARCHITECTURE_ANALYSIS.md  # 技術分析 | Technical analysis
├── data/                      # 執行時間資料（卷宗）| Runtime data (volumes)
│   ├── etc/
│   │   ├── apache2/certs/    # SSL 憑證 | SSL certificates
│   │   └── asterisk/         # Asterisk 設定 | Asterisk configuration
│   ├── var/
│   │   ├── lib/
│   │   │   ├── asterisk/     # Asterisk 資料 | Asterisk data
│   │   │   └── mysql/        # MariaDB 數據 | MariaDB data
│   │   ├── log/asterisk/     # Asterisk 日誌 | Asterisk logs
│   │   ├── spool/asterisk/   # 通話錄音 | Call recordings
│   │   └── www/html/         # FreePBX 網頁 | FreePBX web
│   └── usr/lib64/asterisk/   # Asterisk 模組 | Asterisk modules
├── opt/unimrcp/               # UniMRCP 安裝 ✨ | UniMRCP installation
│   ├── bin/                  # UniMRCP 二進位 | UniMRCP binaries
│   ├── lib/                  # UniMRCP 庫 | UniMRCP libraries
│   ├── conf/                 # UniMRCP 配置 | UniMRCP config
│   └── plugin/asterisk/      # Asterisk 模組 | Asterisk module
└── sql/                       # 資料庫初始化腳本 | Database initialization scripts
```

---

## 🔧 設定 | Configuration

### 環境變數 | Environment Variables

`.env` 中的關鍵環境變數：
Key environment variables in `.env`:

```bash
DB_USER=asterisk           # 資料庫使用者 | Database user
DB_PASS=change_me          # 資料庫密碼 | Database password (CHANGE THIS!)
MYSQL_ROOT_PASSWORD=change # MySQL 根密碼 | MySQL root password (CHANGE THIS!)
DBHOST=freepbx_mariadb     # 資料庫主機 | Database host
DBNAME=asterisk            # 資料庫名稱 | Database name
TZ=Asia/Taipei             # 時區 | Timezone
```

詳細說明見 [.env 配置指南](./ENV_GUIDE.md) | See [.env Configuration Guide](./ENV_GUIDE.md) for details

### 網路設定 | Network Configuration

自訂 Docker 網路，固定 IP：
Custom Docker network with fixed IPs:

- **閘道 | Gateway**: 192.168.0.1
- **MariaDB**: 192.168.0.2:3306
- **FreePBX**: 192.168.0.3

### 埠號 | Ports

| 埠號/Port | 協議/Protocol | 用途/Purpose |
| --- | --- | --- |
| 80 | TCP | HTTP (FreePBX) |
| 443 | TCP | HTTPS (FreePBX 網頁/web) |
| 4445 | TCP | 替代 HTTPS/Alternative HTTPS |
| 5060 | UDP | SIP 信號/SIP signaling |
| 5160 | UDP | IAX2 協議/IAX2 protocol |
| 18000-18100 | UDP | RTP 媒體流/RTP media streams |

---

## 🛠️ 常見操作 | Common Operations

### 啟動/停止 | Start/Stop

```bash
# 啟動所有服務 | Start all services
docker-compose up -d

# 停止所有服務 | Stop all services
docker-compose stop

# 重啟 | Restart
docker-compose restart

# 完全移除 | Complete removal
docker-compose down
```

### 監控 | Monitoring

```bash
# 查看狀態 | View status
docker-compose ps

# 查看日誌 | View logs
docker-compose logs -f freepbx_server

# 監控資源 | Monitor resources
docker stats freepbx_server
```

### 資料庫存取 | Database Access

```bash
# 訪問 MariaDB | Access MariaDB
docker-compose exec mariadb mysql -u root -p asterisk

# 備份資料庫 | Backup database
docker-compose exec mariadb mysqldump -u root -p asterisk > backup.sql
```

### Asterisk CLI

```bash
# 進入 Asterisk 控制台 | Enter Asterisk console
docker-compose exec freepbx_server asterisk -r

# 顯示 SIP 對等端 | Show SIP peers
> sip show peers

# 顯示通話 | Show channels
> core show channels

# 退出 | Exit (type: exit)
```

---

## 🔒 安全性 | Security

⚠️ **重要 | Important:**

- 在 `.env` 中修改所有預設密碼 | Change all default passwords in `.env`
- 使用強密碼 | Use strong passwords
- 限制埠號 443 和 5060 的訪問 | Restrict access to ports 443 and 5060
- 僅啟用 HTTPS | Enable HTTPS only
- 保持系統更新 | Keep system updated

---

## 📝 資料持久化 | Data Persistence

### 什麼是持久化？| What is Data Persistence?

持久化是將容器內的資料儲存在主機上，以便容器停止或刪除後資料仍然保留。
Data persistence means storing container data on the host so it survives after the container stops or is deleted.

我們使用 bind mounts（本地目錄）持久化資料：
We use bind mounts (local directories) for data persistence:

- `/var/lib/asterisk` → `./data/lib` - 分機、語音信箱、佇列檔案 | Extensions, voicemail, spool files
- `/etc/asterisk` → `./data/etc` - 設定檔 | Configuration files
- `/var/log/asterisk` → `./data/log` - 日誌 | Logs
- `/var/www/html` → `./data/www` - 網頁內容 | Web content
- `/var/lib/mysql` → `./datadb` - 資料庫檔案 | Database files
- `/etc/apache2/certs` → `./data/certs` - SSL 憑證 | SSL certificates

### ❌ 如果沒有 Mount 持久化會發生什麼？| What Happens WITHOUT Volume Mounts?

#### 1️⃣ 容器停止時所有資料遺失 | All Data Lost When Container Stops

```text
場景 Scenario:
1. 啟動容器，建立分機、設定通話規則 | Start container, create extensions, configure call rules
2. 收到呼叫，記錄 CDR（通話記錄）| Receive calls, CDR recorded
3. 容器停止：docker-compose stop | Container stops: docker-compose stop
4. ❌ 所有分機、設定、通話記錄全部消失！| ALL extensions, settings, call records GONE!
5. 重新啟動容器 | Restart container
6. 容器回到初始狀態，空白系統 | Container back to initial state, empty system
```

#### 2️⃣ 容器刪除資料永久丟失 | Data Permanently Lost When Container Deleted

```text
最糟情況 Worst case:
docker-compose down  # 刪除容器 | Delete containers
❌ RESULT: 所有資料永久消失，無法恢復！| ALL data permanently deleted, UNRECOVERABLE!
   - 所有分機配置 | All extension configs
   - 所有通話記錄（CDR）| All call records (CDR)
   - 所有語音信箱 | All voicemails
   - 所有自訂設定 | All custom settings
```

#### 3️⃣ 無法追蹤問題根因 | Cannot Debug Problems

```
沒有日誌 | No logs to review:
- 容器重啟後日誌消失 | Logs disappear after container restart
- 無法查看過去的錯誤和警告 | Cannot review past errors and warnings
- 無法進行故障排除 | Cannot troubleshoot issues
```

#### 4️⃣ 系統升級或遷移時資料丟失 | Data Lost During Upgrades or Migration

```text
升級場景 Upgrade scenario:
1. 需要升級 Asterisk 版本 | Need to upgrade Asterisk version
2. 構建新的 Docker 映像 | Build new Docker image
3. 使用新映像啟動容器 | Start container with new image
4. ❌ 舊資料不存在！| Old data doesn't exist!
   - 所有分機配置丟失 | Extension configs lost
   - 無法從舊系統遷移 | Cannot migrate from old system
```

#### 5️⃣ 無法進行備份和恢復 | Cannot Backup or Restore

```text
沒有備份選項 | No backup options:
docker-compose exec mariadb mysqldump -u root -p asterisk > backup.sql
❌ FAIL: 無地方提取備份 | FAIL: No place to extract backup
   - 資料在容器內，無法訪問 | Data inside container, inaccessible
   - 容器停止後資料消失 | Data gone after container stops
   - 無法進行災難恢復 | Cannot do disaster recovery
```

### 📋 對比表 | Comparison Table

| 功能/Feature | 有 Mount | 沒有 Mount |
| --- | --- | --- |
| **容器停止後資料保留** | ✅ YES | ❌ NO |
| **分機配置持久** | ✅ YES | ❌ NO |
| **通話記錄（CDR）保留** | ✅ YES | ❌ NO |
| **容器升級後保留舊資料** | ✅ YES | ❌ NO |
| **可以備份資料** | ✅ YES | ❌ NO |
| **可以從備份恢復** | ✅ YES | ❌ NO |
| **日誌記錄** | ✅ YES | ❌ NO |
| **故障排除** | ✅ YES | ❌ NO |
| **系統遷移** | ✅ YES | ❌ NO |
| **生產環境使用** | ✅ SAFE | ❌ DANGEROUS |

### ✅ 使用 Mount 持久化的正確方式 | Correct Way: Using Volume Mounts

docker-compose.yml 中的 volumes 部分：
The volumes section in docker-compose.yml:

```yaml
volumes:
  # SSL 憑證 | SSL certificates
  - ./data/certs:/etc/apache2/certs

  # Asterisk 資料（CRITICAL）| Asterisk data (CRITICAL)
  - ./data/lib:/var/lib/asterisk

  # Asterisk 設定（CRITICAL）| Asterisk configuration (CRITICAL)
  - ./data/etc:/etc/asterisk

  # Web 內容 | Web content
  - ./data/www:/var/www/html

  # 日誌 | Logs
  - ./data/log:/var/log/asterisk

  # 通話錄音 | Call recordings
  - ./data/monitor:/var/spool/asterisk/monitor
```

### 🔄 資料流向 | Data Flow

```
有 Mount 的情況 | WITH Volume Mounts:

容器內部 Inside Container          |  主機上 On Host
──────────────────────────────────┼──────────────────
/var/lib/asterisk ──────────────→ ./data/lib/
/etc/asterisk     ──────────────→ ./data/etc/
/var/log/asterisk ──────────────→ ./data/log/
/var/www/html     ──────────────→ ./data/www/
/var/lib/mysql    ──────────────→ ./datadb/

✅ 資料同步 | Data synchronized
✅ 容器停止後資料保留 | Data persists after stop
✅ 可備份恢復 | Can backup and restore


沒有 Mount 的情況 | WITHOUT Volume Mounts:

容器內部 Inside Container          |  主機上 On Host
──────────────────────────────────┼──────────────────
/var/lib/asterisk                 |  (nothing)
/etc/asterisk                     |  (nothing)
/var/log/asterisk                 |  (nothing)
/var/www/html                     |  (nothing)
/var/lib/mysql                    |  (nothing)

❌ 容器停止 Container stopped
❌ 所有資料消失 | All data deleted
❌ 無法恢復 | Cannot recover
```

### 🛡️ 最佳實踐 | Best Practices

#### 開發環境 | Development

```bash
# 最小設定 | Minimal setup
mkdir -p data/{etc,lib,log}
docker-compose up -d
# ✅ 足夠用於開發 | Enough for development
```

#### 生產環境 | Production

```bash
# 完整設定 | Complete setup
mkdir -p data/{certs,etc,lib,www,log,monitor}
mkdir -p datadb

# 檢查目錄 | Verify directories
ls -la data/
ls -la datadb/

# 設定適當權限 | Set proper permissions
chmod 755 data/
chmod 755 datadb/

# 定期備份 | Regular backups
docker-compose exec mariadb mysqldump -u root -p asterisk > backup-$(date +%Y%m%d).sql
tar -czf data-backup-$(date +%Y%m%d).tar.gz data/

# ✅ 完整的災難恢復方案 | Complete disaster recovery plan
```

---

### 📌 Named Volumes vs Bind Mounts 的差異 | Named Volumes vs Bind Mounts

本專案使用 **Bind Mounts**，但有些人會用 **Named Volumes**。以下是詳細對比：

#### 什麼是 Named Volumes？| What are Named Volumes?

Named Volumes 是由 Docker 管理的虛擬卷宗，儲存在 Docker 數據目錄中：

```yaml
# Named Volumes 的寫法
volumes:
  asterisk_lib:          # 宣告虛擬卷宗名稱
  asterisk_etc:
  asterisk_db:

services:
  freepbx_server:
    volumes:
      - asterisk_lib:/var/lib/asterisk        # 使用虛擬卷宗
      - asterisk_etc:/etc/asterisk
```

Docker 會自動管理這些卷宗的存儲位置（通常在 `/var/lib/docker/volumes/`）。

#### 什麼是 Bind Mounts？| What are Bind Mounts?

Bind Mounts 是直接連結主機上的目錄：

```yaml
# Bind Mounts 的寫法
services:
  freepbx_server:
    volumes:
      - ./data/lib:/var/lib/asterisk          # 直接綁定本地目錄
      - ./data/etc:/etc/asterisk
```

你完全控制資料的位置（`./data/lib/`, `./data/etc/` 等）。

#### 📊 詳細對比表 | Detailed Comparison

| 功能 / Feature | Named Volumes | Bind Mounts |
| --- | --- | --- |
| **管理方式** | Docker 自動管理 | 手動控制 |
| **存儲位置** | Docker 管理目錄 | 你選擇的目錄 |
| **可見性** | 隱藏（難以訪問） | 完全可見 |
| **編輯檔案** | 困難（需要特殊工具） | 直接編輯 ✅ |
| **備份** | 需要 docker volume | 使用 tar/rsync ✅ |
| **遷移** | 複雜（docker volume copy） | 簡單（複製目錄） ✅ |
| **刪除卷宗** | 需要手動清理 | 自動隨項目刪除 |
| **權限管理** | Docker 處理 | 自己管理 ✅ |
| **跨主機共享** | 困難 | 簡單（NFS/samba） |
| **性能** | 一致（Docker 優化） | 有時較慢（特別是 Windows） |
| **生產環境** | 常用 | 也常用 ✅ |

#### ✅ Named Volumes 的優點 | Advantages of Named Volumes

1. **Docker 自動管理**
   ```bash
   # Docker 自動創建和清理
   docker volume ls
   docker volume rm volume-name
   ```

2. **跨容器共享更容易**
   ```yaml
   # 多個服務可以共享同一卷宗
   services:
     service1:
       volumes:
         - shared_data:/data
     service2:
       volumes:
         - shared_data:/data
   ```

3. **Mac/Windows 上性能更好**
   - Docker Desktop 優化了 Named Volumes 的性能
   - Bind Mounts 在 Windows 上可能較慢

4. **與 Docker Swarm/Kubernetes 相容性更好**

#### ❌ Named Volumes 的缺點 | Disadvantages of Named Volumes

1. **難以直接訪問資料**
   ```bash
   # 位置隱藏在 Docker 管理的目錄中
   /var/lib/docker/volumes/project_asterisk_lib/_data/

   # 無法直接編輯設定檔
   # 必須使用 docker cp 或進入容器
   ```

2. **備份複雜**
   ```bash
   # Named Volume 備份較複雜
   docker run --rm \
     -v named_volume:/data \
     -v $(pwd):/backup \
     alpine tar czf /backup/backup.tar.gz /data
   ```

3. **遷移困難**
   ```bash
   # 無法直接複製卷宗
   # 必須使用 docker volume 指令
   ```

4. **無法使用 docker cp 從主機提取資料**
   ```bash
   # ❌ 這對 Named Volumes 不適用
   docker cp <container-id>:/var/lib/asterisk ./data/lib/
   ```

5. **難以進行版本控制**
   - 卷宗內容不在 Git 追蹤中
   - 難以看到配置的變更歷史

#### ✅ Bind Mounts 的優點 | Advantages of Bind Mounts

1. **完全控制資料位置** ✅
   ```bash
   # 資料在你的項目目錄中
   ls -la data/lib/
   ls -la data/etc/
   # 你可以看到和編輯所有檔案
   ```

2. **簡單的備份** ✅
   ```bash
   # 簡單備份
   tar -czf backup.tar.gz data/

   # 簡單恢復
   tar -xzf backup.tar.gz
   ```

3. **簡單的遷移** ✅
   ```bash
   # 複製整個目錄到新主機
   scp -r data/ user@newhost:~/project/data/
   ```

4. **直接編輯設定檔** ✅
   ```bash
   # 可以直接編輯配置
   vim data/etc/asterisk/sip.conf
   nano data/etc/asterisk/extensions.conf
   ```

5. **使用 docker cp 提取現有資料** ✅
   ```bash
   # 從舊容器遷移資料
   docker cp <container-id>:/var/lib/asterisk/. ./data/lib/
   docker cp <container-id>:/etc/asterisk/. ./data/etc/
   ```

6. **版本控制友好** ✅
   ```bash
   # 可以在 .gitignore 中排除
   echo "data/" >> .gitignore

   # 敏感檔案可以單獨管理
   ```

#### ❌ Bind Mounts 的缺點 | Disadvantages of Bind Mounts

1. **手動權限管理**
   ```bash
   # 需要手動設定權限
   chmod 755 data/
   chown asterisk:asterisk data/lib/
   ```

2. **Windows 性能問題**
   - Windows 上 Bind Mounts 性能較差
   - Docker Desktop 中 WSL2 integration 可改善

3. **跨主機共享較困難**
   ```bash
   # 需要 NFS/Samba
   # Named Volumes 可以使用 docker volume 驅動
   ```

4. **容易意外刪除**
   ```bash
   # ⚠️ 如果誤刪 ./data/ 目錄
   rm -rf data/
   # 資料就永久丟失了（如果沒有備份）
   ```

#### 🎯 本專案為什麼選擇 Bind Mounts？| Why This Project Uses Bind Mounts?

```
優先順序：
1. ✅ 簡單遷移 - 可用 docker cp 從舊系統提取資料
2. ✅ 簡單備份 - tar/rsync 比 docker volume 更簡單
3. ✅ 直接編輯 - 可以直接編輯配置檔案
4. ✅ 透明性 - 所有資料在 ./data/ 目錄，一目了然
5. ✅ 版本控制 - 可在 Git 中排除資料，保留配置追蹤

➡️ 結論：Bind Mounts 更適合 FreePBX 這類需要頻繁迴遷和備份的系統
```

#### ⚠️ 重要：Bind Mounts 的正確操作順序 | CRITICAL: Correct Order for Using Bind Mounts

如果你想從現有容器遷移資料，操作順序很關鍵！
If you're migrating from an existing container, the order is CRITICAL!

#### ❌ 錯誤的順序 | WRONG ORDER

```bash
# 在 docker-compose.yml 中宣告 volumes: - ./data/...
# Then docker-compose up
# Then docker cp
# ❌ 結果：docker-compose.yml 已經建立了空的 ./data/ 目錄
#    docker cp 無法看到新數據（因為容器已經掛載了空目錄）
```

#### ✅ 正確的順序 | CORRECT ORDER

```
步驟 1: 暫時不宣告 volumes | Step 1: Don't declare volumes yet
步驟 2: 啟動容器並提取資料 | Step 2: Start container & extract data with docker cp
步驟 3: 停止容器並加入 volumes | Step 3: Stop, add volumes, restart
```

詳細步驟 | Detailed Steps:

##### 第 1 步：編輯 docker-compose.yml，暫時移除 volumes | Step 1: Comment out volumes in docker-compose.yml

```yaml
# docker-compose.yml 的 freepbx_server 服務部分

services:
  freepbx_server:
    container_name: freepbx_server
    image: freepbx-docker:20.17
    restart: always
    ports:
      - "80:80"
      - "443:443"
      - "5060:5060/udp"
    environment:
      - DB_PASS=${DB_PASS}
      # ... 其他環境變數

    # ⚠️ 暫時註釋掉 volumes（稍後再啟用）
    # volumes:
    #   - ./data/certs:/etc/apache2/certs
    #   - ./data/lib:/var/lib/asterisk
    #   - ./data/etc:/etc/asterisk
    #   - ./data/www:/var/www/html
    #   - ./data/log:/var/log/asterisk
    #   - ./data/monitor:/var/spool/asterisk/monitor
```

##### 第 2 步：啟動容器（沒有 volumes）| Step 2: Start container WITHOUT volumes

```bash
docker-compose up -d

# 容器現在執行，內部有所有預設配置
# Container now running with all default configs inside
```

##### 第 3 步：使用 docker cp 提取資料到主機 | Step 3: Use docker cp to extract data to host

```bash
# 建立目標目錄 | Create target directories
mkdir -p data/{certs,lib,etc,www,log,monitor}

# 從容器複製所有資料到主機
# Copy all data from container to host
docker cp <container-id>:/var/lib/asterisk/. ./data/lib/
docker cp <container-id>:/etc/asterisk/. ./data/etc/
docker cp <container-id>:/var/www/html/. ./data/www/
docker cp <container-id>:/var/log/asterisk/. ./data/log/
docker cp <container-id>:/etc/apache2/certs/. ./data/certs/

# 驗證資料已複製
# Verify data was copied
ls -la data/lib/
ls -la data/etc/
```

##### 第 4 步：停止容器 | Step 4: Stop the container

```bash
docker-compose stop
```

##### 第 5 步：啟用 docker-compose.yml 中的 volumes | Step 5: Enable volumes in docker-compose.yml

```yaml
# 取消註釋 volumes 部分
# Uncomment the volumes section

services:
  freepbx_server:
    # ... 其他配置

    volumes:
      - ./data/certs:/etc/apache2/certs
      - ./data/lib:/var/lib/asterisk
      - ./data/etc:/etc/asterisk
      - ./data/www:/var/www/html
      - ./data/log:/var/log/asterisk
      - ./data/monitor:/var/spool/asterisk/monitor
```

##### 第 6 步：重新啟動容器（現在有 volumes）| Step 6: Restart with volumes

```bash
docker-compose up -d

# 容器現在會掛載 ./data/* 目錄中的資料
# Container now mounts the data from ./data/* directories
```

##### 第 7 步：驗證資料是否可存取 | Step 7: Verify data is accessible

```bash
# 驗證容器內能看到資料
# Verify container can access the data
docker-compose exec freepbx_server ls -la /var/lib/asterisk/
docker-compose exec freepbx_server ls -la /etc/asterisk/

# 驗證主機上的資料是否與容器內同步
# Verify host and container data are in sync
ls -la data/lib/
ls -la data/etc/
```

#### 📊 視覺化流程 | Visual Workflow

```
錯誤流程 WRONG:
┌─────────────────────────────────────┐
│ 編輯 docker-compose.yml 加入 volumes │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ docker-compose up -d                │
│ (建立空的 ./data/ 目錄)              │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ docker cp ... ./data/               │
│ ❌ 無法看到新數據！                  │
│    (容器已掛載空目錄)                │
└─────────────────────────────────────┘


正確流程 CORRECT:
┌─────────────────────────────────────┐
│ 編輯 docker-compose.yml             │
│ ⚠️ 暫時註釋掉 volumes               │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ docker-compose up -d                │
│ (無 volumes，容器有預設配置)        │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ docker cp ... ./data/               │
│ ✅ 成功複製所有資料！                │
│    (容器內數據複製到主機)            │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ docker-compose stop                 │
│ (停止容器)                          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 編輯 docker-compose.yml             │
│ ✅ 啟用 volumes                     │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ docker-compose up -d                │
│ ✅ 掛載 ./data/ 目錄，資料保留      │
└─────────────────────────────────────┘
```

#### 🔄 如何轉換？| How to Switch Between Them?

**從 Named Volumes 改為 Bind Mounts:**

```bash
# 1. 備份 Named Volume
docker run --rm -v old_volume:/data -v $(pwd):/backup \
  alpine tar czf /backup/backup.tar.gz /data

# 2. 建立 Bind Mount 目錄
mkdir -p data/

# 3. 解壓資料
tar -xzf backup.tar.gz -C data/

# 4. 更新 docker-compose.yml
# 改為：- ./data:/var/lib/asterisk

# 5. 重啟容器
docker-compose down
docker-compose up -d
```

**從 Bind Mounts 改為 Named Volumes:**

```bash
# 1. 建立 Named Volume
docker volume create asterisk_lib

# 2. 複製資料到 Named Volume
docker run --rm -v asterisk_lib:/target -v ./data:/source \
  alpine cp -r /source/* /target/

# 3. 更新 docker-compose.yml
# 改為：- asterisk_lib:/var/lib/asterisk

# 4. 重啟容器
docker-compose down
docker-compose up -d
```

#### 💡 建議 | Recommendation

**開發和小型部署：** Bind Mounts 👈 本專案選擇
- 簡單易用
- 便於調試
- 易於備份遷移

**大型企業部署：** Named Volumes
- Docker 官方推薦
- 更好的性能（特別是 Swarm/Kubernetes）
- 更專業的管理

**混合方案：** 也可以混合使用
```yaml
volumes:
  database_data:            # Named Volume 用於數據庫
  asterisk_config:          # Named Volume 用於關鍵配置

services:
  mariadb:
    volumes:
      - database_data:/var/lib/mysql
  freepbx:
    volumes:
      - asterisk_config:/etc/asterisk    # 關鍵配置用 Named Volume
      - ./data/lib:/var/lib/asterisk     # 日誌用 Bind Mount
```

---

## 🐛 故障排除 | Troubleshooting

### 查看日誌 | View Logs

```bash
# 查看容器日誌 | View container logs
docker-compose logs freepbx_server

# 查看 Asterisk 日誌 | View Asterisk logs
docker-compose exec freepbx_server tail -f /var/log/asterisk/full
```

### 連線測試 | Connectivity

```bash
# 測試資料庫連線 | Test database connection
docker-compose exec freepbx_server mysql -h mariadb -u asterisk -p asterisk

# 測試 SIP | Test SIP
docker-compose exec freepbx_server asterisk -r
> sip show registry
```

### 容器名稱 | Container Names

Docker-compose.yml 中的容器名稱：
Container names in docker-compose.yml:

- `freepbx_server` - FreePBX 和 Asterisk 服務 | FreePBX and Asterisk service
- `freepbx_mariadb` - MariaDB 資料庫服務 | MariaDB database service

---

## 📚 文檔 | Documentation

- **[⚡ 快速開始](./SETUP.md)** ← 從這裡開始（3 分鐘）| **[Quick Start](./SETUP.md)** ← Start here (3 minutes)
- [🚀 使用指南](./USAGE_GUIDE.md) - 完整教程 | Complete tutorials
- [⚡ 快速參考](./QUICK_REFERENCE.md) - 指令速查表 | Command cheat sheet
- [🔐 .env 配置指南](./ENV_GUIDE.md) - 環境變數和敏感資訊管理 | Environment variables and secrets
- [🏗️ Dockerfile 分析](./ARCHITECTURE_ANALYSIS.md) - Dockerfile 詳細分析 | Dockerfile detailed analysis
- [🔧 docker-compose 分析](./DOCKER_COMPOSE_ANALYSIS.md) - docker-compose.yml 詳細分析和修正建議 | docker-compose.yml detailed analysis
- [🎙️ UniMRCP 設置](./UNIMRCP_SETUP.md) - 語音辨識和文字轉語音 | Speech recognition and TTS
- [📦 數據掛載 SOP](./MOUNT_SOP.md) - 完整遷移程序 | Complete migration procedure
- [🎯 簡明版本](./BRIEF_README.md) - 快速參考 | Quick reference
- [Asterisk 文檔](https://wiki.asterisk.org/) | [Asterisk Documentation](https://wiki.asterisk.org/)
- [FreePBX 文檔](https://wiki.freepbx.org/) | [FreePBX Documentation](https://wiki.freepbx.org/)
- [UniMRCP 文檔](http://www.unimrcp.org/) | [UniMRCP Documentation](http://www.unimrcp.org/)

---

## English Version

A complete Docker-based telephony solution integrating Asterisk, FreePBX, and MariaDB.
This project provides a containerized PBX system for VoIP communications with web-based management interface.

For bilingual content, scroll up to the main sections above.
本專案提供了雙語內容，請往上滾動查看主要章節。

---

## 中文版

這是一個完整的 Docker 電話系統解決方案，整合了 Asterisk、FreePBX 和 MariaDB。
本專案提供了一個容器化的 PBX 系統，用於 VoIP 通訊並具有基於網頁的管理介面。

詳細內容請往上滾動，查看雙語內容章節。

---

## 📄 授權 | License

本專案設定如實提供。請確保符合 Asterisk 和 FreePBX 的授權條款。
This project configuration is provided as-is. Ensure compliance with Asterisk and FreePBX licensing.
