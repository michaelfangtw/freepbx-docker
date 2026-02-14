# FreePBX Modules Installation Guide
# FreePBX 模塊安裝指南

---

## 📋 Installed Modules | 已安裝模塊

本 Dockerfile 包含以下 FreePBX 模塊的自動安裝：

### 1. **Misc Applications** (miscapplications)
- **功能**: 雜項應用程式
- **用途**: 提供額外的應用程式功能
- **特性**:
  - 自訂應用程式執行
  - 進階呼叫處理
  - 靈活的應用程式整合

### 2. **Misc Destinations** (miscdestinations)
- **功能**: 雜項目標
- **用途**: 建立自訂呼叫目標和路由
- **特性**:
  - 自訂目標定義
  - 靈活的呼叫路由
  - 進階呼叫管理

### 3. **Config Edit** (configedit)
- **功能**: 配置檔案編輯器
- **用途**: 直接編輯 Asterisk 配置檔案
- **特性**:
  - Web 介面編輯配置
  - 語法檢查
  - 即時檔案編輯
  - 備份和還原功能

### 4. **Dynamic Routes** (dynamicroutes)
- **功能**: 動態路由
- **用途**: 建立基於條件的動態呼叫路由
- **特性**:
  - 條件式路由
  - 時間表路由
  - 負載平衡
  - 進階路由邏輯

---

## 📦 Installation Methods | 安裝方法

### 方法 1: 自動安裝（在 Docker Build 時）

Dockerfile 已包含自動安裝，構建時會自動安裝所有模塊：

```bash
docker build -t freepbx-docker:latest .
```

### 方法 2: 手動安裝（在運行的容器中）

如果需要在現有容器中安裝模塊：

```bash
# 進入容器
docker-compose exec freepbx_server bash

# 安裝單個模塊
fwconsole ma install miscapplications
fwconsole ma install miscdestinations
fwconsole ma install configedit
fwconsole ma install dynamicroutes

# 重新載入
fwconsole reload
asterisk -rx "core reload"

# 退出容器
exit
```

### 方法 3: 使用 fwconsole 命令

```bash
# 檢查可用模塊
docker-compose exec freepbx_server fwconsole ma list

# 搜尋特定模塊
docker-compose exec freepbx_server fwconsole ma search miscapplications

# 安裝特定版本
docker-compose exec freepbx_server fwconsole ma install miscapplications 17.0

# 更新模塊
docker-compose exec freepbx_server fwconsole ma upgrade miscapplications

# 禁用模塊
docker-compose exec freepbx_server fwconsole ma disable miscapplications

# 啟用模塊
docker-compose exec freepbx_server fwconsole ma enable miscapplications

# 移除模塊
docker-compose exec freepbx_server fwconsole ma remove miscapplications
```

---

## 🔧 Module Configuration | 模塊配置

### Misc Applications 配置

在 FreePBX Web UI 中配置：

1. 進入 **Admin** → **Applications** → **Misc Applications**
2. 建立新應用程式
3. 設定應用名稱和執行命令
4. 在 Dialplan 中使用

**Dialplan 使用範例**:

```ini
[mycontext]
exten => 100,1,Misc(MyApp)
```

### Misc Destinations 配置

建立自訂目標：

1. 進入 **Admin** → **Applications** → **Misc Destinations**
2. 建立新目標
3. 設定目標名稱和參數
4. 在路由中使用

**範例**:

```ini
[from-internal]
exten => 200,1,Goto(mycontext,100,1)
```

### Config Edit 配置

直接編輯配置檔案：

1. 進入 **Admin** → **Config Edit**
2. 選擇要編輯的檔案
3. 修改設定
4. 點擊儲存

**常見檔案**:
- `/etc/asterisk/sip.conf` - SIP 設定
- `/etc/asterisk/extensions.conf` - 撥號方案
- `/etc/asterisk/voicemail.conf` - 語音信箱

### Dynamic Routes 配置

建立動態路由：

1. 進入 **Admin** → **Connectivity** → **Dynamic Routes**
2. 建立新路由規則
3. 設定條件（時間、日期、來源等）
4. 指定目標

**條件範例**:
- 時間範圍（工作時間/下班時間）
- 星期幾
- 來源 DID
- 來源分機

---

## 📝 Dialplan Examples | 撥號方案範例

### 範例 1: 簡單的 Misc Application

```ini
[from-internal]
; 使用 Misc Application
exten => 500,1,Answer()
exten => 500,n,Playback(silence/1)
exten => 500,n,Misc(MyCustomApp)
exten => 500,n,Hangup()
```

### 範例 2: 使用 Misc Destination

```ini
[from-internal]
; 使用 Misc Destination
exten => 501,1,Goto(miscdestnation,MyDestination,1)
```

### 範例 3: 動態路由（工作時間判斷）

```ini
[from-internal]
exten => 502,1,Answer()
exten => 502,n,GotoIf($["${STRFTIME(${EPOCH},):%w)}" = "0"]?closedtime)
exten => 502,n,GotoIf($["${STRFTIME(${EPOCH},):%w)}" = "6"]?closedtime)
exten => 502,n,Goto(businesshours)
exten => 502,n(closedtime),Playback(vm-goodbye)
exten => 502,n,Hangup()
exten => 502,n(businesshours),Goto(from-internal,100,1)
```

### 範例 4: 條件式呼叫轉接

```ini
[from-internal]
exten => 503,1,Answer()
exten => 503,n,Set(HOUR=${STRFTIME(${EPOCH},):%H)})
exten => 503,n,GotoIf($[${HOUR} >= 9 & ${HOUR} < 17]?office:afterhours)
exten => 503,n(office),Goto(from-internal,100,1)
exten => 503,n(afterhours),Playback(sorry-but-office-closed)
exten => 503,n,Hangup()
```

---

## ✅ Verification | 驗證安裝

### 檢查模塊是否已安裝

```bash
# 進入 Asterisk CLI
docker-compose exec freepbx_server asterisk -r

# 檢查模塊
*CLI> module show like misc
Module                         Description                      Use Count  Status
app_miscapplications.so        Misc Applications Module                  0  Running
res_miscdestinations.so        Misc Destinations Module                  0  Running

# 查看所有已加載的模塊
*CLI> module show

# 退出
*CLI> exit
```

### 檢查 FreePBX Module Manager

```bash
# 列出所有已安裝的模塊
docker-compose exec freepbx_server fwconsole ma list

# 檢查特定模塊狀態
docker-compose exec freepbx_server fwconsole ma check miscapplications
```

### 在 Web UI 中驗證

1. 登入 FreePBX Admin 頁面
2. 進入 **Admin** → **Module Admin**
3. 查看 **Enabled Modules** 清單
4. 確認以下模塊已列出：
   - Misc Applications
   - Misc Destinations
   - Config Edit
   - Dynamic Routes

---

## 🔧 Troubleshooting | 故障排除

### 模塊無法安裝

```bash
# 檢查錯誤訊息
docker-compose logs freepbx_server | grep -i "miscapplications"

# 手動重新安裝
docker-compose exec freepbx_server fwconsole ma install miscapplications --force

# 重新載入
docker-compose exec freepbx_server fwconsole reload
```

### 模塊未顯示在 Web UI 中

```bash
# 清除快取
docker-compose exec freepbx_server fwconsole cache clear

# 重新啟動 FreePBX
docker-compose restart freepbx_server

# 檢查日誌
docker-compose logs freepbx_server | tail -50
```

### Asterisk 無法載入模塊

```bash
# 檢查 Asterisk 日誌
docker-compose exec freepbx_server tail -f /var/log/asterisk/full

# 重新編譯模塊
docker-compose exec freepbx_server asterisk -rx "module reload"

# 核心重新載入
docker-compose exec freepbx_server asterisk -rx "core reload"
```

### 模塊依賴項缺失

```bash
# 檢查依賴項
docker-compose exec freepbx_server fwconsole ma list | grep -E "dependent|required"

# 安裝依賴項
docker-compose exec freepbx_server fwconsole ma install framework

# 更新所有模塊
docker-compose exec freepbx_server fwconsole ma upgradeall
```

---

## 📊 Module Versions | 模塊版本

### 檢查已安裝的版本

```bash
docker-compose exec freepbx_server fwconsole ma list | grep -E "miscapplications|miscdestinations|configedit|dynamicroutes"
```

**預期輸出**:

```
miscapplications         Miscellaneous Applications          Enabled  Installed  Version: 17.0.xx
miscdestinations         Miscellaneous Destinations          Enabled  Installed  Version: 17.0.xx
configedit               Config Edit                         Enabled  Installed  Version: 17.0.xx
dynamicroutes            Dynamic Routes                      Enabled  Installed  Version: 17.0.xx
```

---

## 🔄 Updating Modules | 更新模塊

### 更新單個模塊

```bash
docker-compose exec freepbx_server fwconsole ma upgrade miscapplications
```

### 更新所有模塊

```bash
docker-compose exec freepbx_server fwconsole ma upgradeall
```

### 禁用自動更新

在 FreePBX Web UI：
1. 進入 **Admin** → **System Settings** → **Module Repository**
2. 禁用 **Automatic Module Updates**

---

## 💾 Backup & Restore | 備份與還原

### 備份模塊配置

```bash
# 備份 FreePBX 配置
tar -czf freepbx-backup-$(date +%Y%m%d).tar.gz /etc/asterisk /var/lib/asterisk
```

### 還原模塊配置

```bash
# 還原備份
tar -xzf freepbx-backup-20240215.tar.gz -C /
```

---

## 📚 Additional Resources | 額外資源

- **FreePBX Module Admin**: https://wiki.freepbx.org/display/FPBX/Module+Admin
- **Asterisk Applications**: https://wiki.asterisk.org/wiki/display/AST/Asterisk+14+Applications
- **Dynamic Routing**: https://wiki.freepbx.org/display/FPBX/Dynamic+Routes
- **Config Edit**: https://wiki.freepbx.org/display/FPBX/Config+Edit

---

## 🔐 Security Notes | 安全說明

1. **Config Edit Access**
   - 限制只有管理員可以存取 Config Edit
   - 避免編輯敏感檔案
   - 始終進行備份

2. **Misc Applications**
   - 驗證應用程式代碼的安全性
   - 避免執行不受信任的應用程式

3. **Dynamic Routes**
   - 定期檢查路由規則
   - 確保路由邏輯正確

---

**Last Updated**: 2026-02-15
**FreePBX Version**: 17.0
**Asterisk Version**: 20-current
**Supported Modules**: 4 (miscapplications, miscdestinations, configedit, dynamicroutes)
