# UniMRCP Installation & Configuration Guide
# UniMRCP 安裝及配置指南

---

## 📋 What is UniMRCP?

**UniMRCP** (Universal MRCP Client Library) is an open-source MRCP (Media Resource Control Protocol) client library for Asterisk.

**作用**: 連接 Asterisk 和 MRCP 伺服器（如：語音辨識、文字轉語音服務）
**用途**: IVR、自動語音應答、語音互動系統

---

## 🔧 Installation Steps

### Step 1: Build Image with UniMRCP

The Dockerfile now includes UniMRCP installation:

```bash
# Build the Docker image
docker build -t freepbx-docker:v17.20 .

# This will:
# 1. Install UniMRCP 1.8.0 to /opt/unimrcp
# 2. Compile UniMRCP Asterisk plugin
# 3. Install the plugin to Asterisk modules directory
```

Build time: ~10-15 minutes (depends on internet speed)

### Step 2: Verify UniMRCP Installation

After container starts, verify installation:

```bash
# Enter container
docker-compose exec freepbx_server bash

# Check UniMRCP installation
ls -la /opt/unimrcp/

# Check Asterisk plugin loaded
asterisk -r
*CLI> module show like unimrcp
*CLI> exit

# Expected output:
# res_unimrcp.so              Speech Recognition Applications
```

---

## 📁 Directory Structure

```
/opt/unimrcp/                  # UniMRCP installation directory
├── bin/
│   ├── mrcpserver            # MRCP server binary
│   └── unimrcpclient         # MRCP client utility
├── lib/
│   └── *.so files            # Libraries
├── conf/
│   ├── unimrcpclient.xml     # Client configuration
│   ├── logger.xml            # Logging configuration
│   └── mrcp-*.conf           # Protocol configurations
├── plugin/
│   └── asterisk/
│       └── res_unimrcp.so    # Asterisk module
└── samples/

/usr/lib64/asterisk/modules/
└── res_unimrcp.so            # Asterisk plugin (symlink/copy)

/etc/asterisk/
├── unimrcp.conf              # Asterisk UniMRCP configuration
└── res_unimrcp.conf          # Detailed settings
```

---

## ⚙️ Configuration

### Step 1: Configure UniMRCP Client

Edit `/etc/asterisk/unimrcp.conf` (or create if not exists):

```ini
[default]
; UniMRCP client name
name = defaultclient

; MRCP server connection
server_ip = 192.168.1.100        ; MRCP server IP
server_port = 5060              ; MRCP server port
rtp_ip = 192.168.1.50           ; Your Asterisk IP for RTP
rtp_port = 5000                 ; RTP port range start
rtp_port_max = 5100             ; RTP port range end

; Protocol settings
protocol = mrcpv2               ; MRCP version (mrcpv1 or mrcpv2)
transport = tcp                 ; Connection transport (tcp or sctp)
timeout = 10000                 ; Connection timeout (ms)
```

### Step 2: Create res_unimrcp.conf

```bash
# Create/edit Asterisk module configuration
vi /etc/asterisk/res_unimrcp.conf
```

Content:

```ini
[engine]
; Logging level: OFF, CRITICAL, ERROR, WARNING, NOTICE, INFO, DEBUG
log_level = INFO
log_channel = console

; Maximum number of MRCP profiles
max_profiles = 10

; RTP port range
rtp_min_port = 5000
rtp_max_port = 5100

; Connection timeout (seconds)
connection_timeout = 10

; DTMF detection (yes/no)
dtmf_detection = yes

; Confidence threshold for recognition (0.0-1.0)
confidence_threshold = 0.5
```

### Step 3: Configure Asterisk Dialplan

Edit `/etc/asterisk/extensions.conf`:

```ini
[ivr]
exten => s,1,Verbose(2,Starting IVR with speech recognition)
exten => s,n,Answer()
exten => s,n,MRCPSynth(Say hello "Hello, please say your account number or press 1",en-US)
exten => s,n,MRCPRecog(grammar=yes/no;timeout=10000,en-US)
exten => s,n,Verbose(2,Recognized: ${RECOG_RESULT})

; Handle recognition results
exten => s,n(check_result),GotoIf($["${RECOG_RESULT}"="yes"]?yes:no)

exten => s,n(yes),Verbose(2,User said yes)
exten => s,n,Goto(handle_yes)

exten => s,n(no),Verbose(2,User said no)
exten => s,n,Goto(handle_no)

exten => s,n(handle_yes),Playback(tt-weasels)
exten => s,n,Hangup()

exten => s,n(handle_no),Playback(vm-goodbye)
exten => s,n,Hangup()
```

---

## 🚀 Testing UniMRCP

### Test 1: Check Module Loading

```bash
docker-compose exec freepbx_server asterisk -r

*CLI> module show like unimrcp
Module                         Description                      Use Count  Status
res_unimrcp.so                 Speech Recognition Applications  0          Running

# If you see "res_unimrcp.so  ... Running", installation is successful!
```

### Test 2: Test Speech Synthesis

Create test dialplan:

```bash
# Edit extensions.conf
docker-compose exec freepbx_server vi /etc/asterisk/extensions.conf
```

Add test extension:

```ini
[test]
exten => 100,1,Answer()
exten => 100,n,MRCPSynth(Say "Testing speech synthesis")
exten => 100,n,Hangup()
```

```bash
# Reload dialplan
docker-compose exec freepbx_server asterisk -r

*CLI> dialplan reload
*CLI> exit

# Test from SIP phone: dial 100
```

### Test 3: Enable Debugging

```bash
# Check UniMRCP logs
docker-compose exec freepbx_server tail -f /var/log/asterisk/unimrcp.log

# Or use Asterisk verbose mode
docker-compose exec freepbx_server asterisk -r

*CLI> core set verbose 3
*CLI> module reload res_unimrcp.so
# Now make a test call to see verbose output
```

---

## 📝 Common MRCP Applications

### 1. Speech Recognition (ASR)

```ini
; Recognize speech and store result
exten => 101,1,Answer()
exten => 101,n,MRCPRecog(grammar=yes/no;timeout=5000,en-US)
exten => 101,n,Verbose(Result: ${RECOG_RESULT})
exten => 101,n,Hangup()
```

### 2. Text-to-Speech (TTS)

```ini
; Synthesize and play text
exten => 102,1,Answer()
exten => 102,n,MRCPSynth(Say "Your account balance is 100 dollars",en-US)
exten => 102,n,Hangup()
```

### 3. Combined IVR

```ini
; More complex IVR
exten => 103,1,Answer()
exten => 103,n,MRCPSynth(Say "Please say your account number",en-US)
exten => 103,n,MRCPRecog(grammar=\d{4};timeout=10000,en-US)
exten => 103,n,GotoIf($["${RECOG_RESULT}"=""]?error)
exten => 103,n,Set(ACCOUNT=${RECOG_RESULT})
exten => 103,n,MRCPSynth(Say "Thank you, your account is ${ACCOUNT}",en-US)
exten => 103,n,Hangup()
exten => 103,n(error),MRCPSynth(Say "Sorry, I did not understand",en-US)
exten => 103,n,Hangup()
```

---

## 🔌 MRCP Server Connection

### Option 1: Open Source MRCP Server

**UniMRCP Server** (included in installation):

```bash
# Run UniMRCP server in container
docker-compose exec freepbx_server /opt/unimrcp/bin/mrcpserver

# Or configure to start automatically
```

### Option 2: Third-Party MRCP Servers

**Popular Options**:
- **Voxeo** MRCP Server
- **LumenVox** MRCP Server
- **ScanSoft** Server
- **VocalTec** VoiceXML Server

**Configuration** (in `unimrcp.conf`):

```ini
[remote_server]
name = external_mrcp
server_ip = 203.0.113.10        ; External MRCP server IP
server_port = 5060
rtp_ip = 192.168.1.50
rtp_port = 5000
rtp_port_max = 5100
protocol = mrcpv2
transport = tcp
timeout = 10000
```

---

## 🐛 Troubleshooting

### Problem: Module Not Loading

```bash
docker-compose exec freepbx_server asterisk -r

*CLI> module load res_unimrcp.so
  Loaded res_unimrcp.so => (Speech Recognition Applications)
```

If error:

```bash
# Check logs
cat /var/log/asterisk/full | grep -i unimrcp

# Common issues:
# 1. Missing dependencies - reinstall Asterisk build tools
# 2. Path issues - verify /opt/unimrcp/plugin/asterisk/res_unimrcp.so exists
# 3. Asterisk version mismatch - ensure building with same Asterisk version
```

### Problem: Cannot Connect to MRCP Server

```bash
# Check configuration
cat /etc/asterisk/unimrcp.conf

# Verify network connectivity
docker-compose exec freepbx_server ping 192.168.1.100

# Check MRCP server is running on port 5060
docker-compose exec freepbx_server netstat -tlnp | grep 5060
```

### Problem: No Audio Output

```bash
# Check RTP ports are open
docker-compose exec freepbx_server netstat -tlnp | grep 500

# Verify RTP settings in unimrcp.conf
rtp_port = 5000
rtp_port_max = 5100

# Check firewall rules
iptables -L | grep 500
```

### Problem: Recognition Not Working

```bash
# Verify grammar file exists
ls -la /opt/unimrcp/conf/

# Check log level
*CLI> core set verbose 10

# Enable debugging
asterisk -r
*CLI> unimrcp debug on
*CLI> exit

# Check full Asterisk logs
tail -f /var/log/asterisk/full | grep -i recog
```

---

## 📊 Performance Tuning

### Optimize for High Call Volume

Edit `/etc/asterisk/res_unimrcp.conf`:

```ini
[engine]
; Increase connection pool
max_profiles = 50

; Increase RTP port range
rtp_min_port = 5000
rtp_max_port = 6000

; Connection pooling
connection_pooling = yes
pool_size = 10

; Timeout settings (seconds)
connection_timeout = 15
request_timeout = 10
```

### Memory Optimization

```ini
[engine]
; Reduce logging for production
log_level = WARNING

; Limit session duration
max_session_duration = 3600

; Clear stale connections
connection_cleanup_interval = 300
```

---

## 📚 Resources

- **Official UniMRCP**: http://www.unimrcp.org/
- **Documentation**: http://www.unimrcp.org/project/component-view/documentation
- **MRCP Protocol RFC**: https://www.rfc-editor.org/rfc/rfc6787
- **Asterisk Documentation**: https://wiki.asterisk.org/wiki/display/AST/MRCP

---

## 🔐 Security Notes

1. **Firewall**: Only allow MRCP connections from trusted servers
   ```bash
   iptables -A INPUT -p tcp --dport 5060 -s 192.168.1.0/24 -j ACCEPT
   ```

2. **Encryption**: Use TLS for MRCP connections
   ```ini
   [server]
   transport = tls
   cert_file = /etc/asterisk/certs/server.crt
   key_file = /etc/asterisk/certs/server.key
   ```

3. **Authentication**: Enable MRCP server authentication
   ```ini
   [server]
   auth_enabled = yes
   username = asterisk_user
   password = secure_password
   ```

---

## 📝 Version History

- **v1.8.0**: Latest stable release (current in Dockerfile)
- **v1.7.0**: Previous stable
- **v1.6.0**: Legacy version

To use different version, edit Dockerfile:

```dockerfile
# Change this line:
wget -O /usr/src/unimrcp-1.8.0.tar.gz \
  http://www.unimrcp.org/project/component-view/unimrcp-downloads/unimrcp-1.8.0/unimrcp-1.8.0.tar.gz

# To desired version, e.g., 1.7.0:
wget -O /usr/src/unimrcp-1.7.0.tar.gz \
  http://www.unimrcp.org/project/component-view/unimrcp-downloads/unimrcp-1.7.0/unimrcp-1.7.0.tar.gz
```

---

**Last Updated**: 2026-02-15
**UniMRCP Version**: 1.8.0
**Asterisk Version**: 20-current
**FreePBX Version**: 17.0
