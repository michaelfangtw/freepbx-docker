# 📋 Data Mount SOP - Standard Operating Procedure
# 數據掛載標準操作程序

⚠️ **CRITICAL: Always use `docker cp` BEFORE enabling volume mounts!**
⚠️ **重要：在啟用卷掛載前，必須使用 `docker cp` 複製數據！**

---

## 🚨 Why This Matters / 為什麼重要

### ❌ Wrong Order = Data Loss
```
1. Enable volumes in docker-compose.yml
2. docker-compose up -d
3. docker cp ...
❌ RESULT: docker-compose creates EMPTY directories
   docker cp cannot copy into already-mounted volumes
   → Data extraction FAILS!
```

### ✅ Correct Order = Data Safety
```
1. Comment out volumes in docker-compose.yml
2. docker-compose up -d (without volumes)
3. docker cp ... (copy data from running container)
4. Stop container
5. Uncomment volumes
6. docker-compose up -d (with volumes + data)
✅ RESULT: All data safely migrated!
```

---

## 📊 Directory Structure

```
freepbx-docker/
├── data/                           # Main data directory
│   ├── etc/
│   │   ├── apache2/certs/         # SSL certificates
│   │   └── asterisk/              # Asterisk configuration
│   ├── var/
│   │   ├── lib/
│   │   │   ├── asterisk/          # Asterisk data (CRITICAL)
│   │   │   └── mysql/             # MariaDB data (CRITICAL)
│   │   ├── log/asterisk/          # Asterisk logs
│   │   ├── spool/asterisk/        # Voicemail, call recordings
│   │   └── www/html/              # FreePBX web interface
│   └── usr/lib64/asterisk/        # Asterisk modules & libraries
├── sql/                            # Database init scripts
└── docker-compose.yml
```

---

## 🔄 Complete Migration SOP

### Step 1: Prepare Environment Files

```bash
# Create directory structure (empty initially)
mkdir -p data/{etc/apache2/certs,etc/asterisk}
mkdir -p data/{var/lib/asterisk,var/lib/mysql}
mkdir -p data/{var/log/asterisk,var/spool/asterisk}
mkdir -p data/{var/www/html,usr/lib64/asterisk}

# Copy environment template
cp .env.example .env

# Edit .env with your passwords
nano .env
# Or use your preferred editor
```

### Step 2: Verify Directory Structure

```bash
# Check that directories are empty and correct structure exists
tree data/ -L 3

# Expected output:
# data/
# ├── etc/
# │   ├── apache2/
# │   │   └── certs/
# │   └── asterisk/
# ├── var/
# │   ├── lib/
# │   │   ├── asterisk/
# │   │   └── mysql/
# │   ├── log/
# │   │   └── asterisk/
# │   ├── spool/
# │   │   └── asterisk/
# │   └── www/
# │       └── html/
# └── usr/
#     └── lib64/
#         └── asterisk/
```

### Step 3: Comment Out Volumes in docker-compose.yml

Edit `docker-compose.yml` - Find the FreePBX service volumes section:

```yaml
services:
  freepbx_server:
    # ... other config ...

    # ⚠️ TEMPORARILY COMMENT OUT ALL VOLUMES
    # volumes:
    #   - ./data/etc/apache2/certs:/etc/apache2/certs
    #   - ./data/etc/asterisk:/etc/asterisk
    #   - ./data/var/lib/asterisk:/var/lib/asterisk
    #   - ./data/usr/lib64/asterisk:/usr/lib64/asterisk
    #   - ./data/var/spool/asterisk:/var/spool/asterisk
    #   - ./data/var/log/asterisk:/var/log/asterisk
    #   - ./data/var/www/html:/var/www/html
    #   - ./data/etc/apache2/apache2.conf:/etc/apache2/apache2.conf

  mariadb:
    # ... other config ...

    # ⚠️ TEMPORARILY COMMENT OUT MARIADB VOLUME
    # volumes:
    #   - ./data/var/lib/mysql:/var/lib/mysql
    #   - ./sql:/docker-entrypoint-initdb.d
```

### Step 4: Start Containers WITHOUT Volumes

```bash
# Start containers (they will create default data inside)
docker-compose up -d

# Verify containers are running
docker-compose ps
# Expected: Both freepbx_server and mariadb should show "Up"

# Wait for services to initialize (30-60 seconds)
docker-compose logs -f freepbx_server
# Press Ctrl+C when you see "Asterisk started successfully" or similar
```

### Step 5: Copy Data from Running Containers

**CRITICAL: Do this while containers are still running!**

#### Copy Asterisk Configuration

```bash
# Copy Asterisk configuration (CRITICAL)
docker cp freepbx_server:/etc/asterisk/. data/etc/asterisk/

# Verify
ls -la data/etc/asterisk/
# Should show: extensions.conf, sip.conf, etc.
```

#### Copy Asterisk Data

```bash
# Copy Asterisk data (CRITICAL)
docker cp freepbx_server:/var/lib/asterisk/. data/var/lib/asterisk/

# Verify
ls -la data/var/lib/asterisk/
# Should show: agi-bin, bin, phoneprov, sounds, etc.
```

#### Copy Asterisk Modules

```bash
# Copy Asterisk modules
docker cp freepbx_server:/usr/lib64/asterisk/. data/usr/lib64/asterisk/

# Verify
ls -la data/usr/lib64/asterisk/ | head
# Should show multiple .so files
```

#### Copy FreePBX Web Files

```bash
# Copy FreePBX web interface
docker cp freepbx_server:/var/www/html/. data/var/www/html/

# Verify
ls -la data/var/www/html/
# Should show: admin, rest, etc.
```

#### Copy Asterisk Logs (optional)

```bash
# Copy existing logs (optional, can be empty initially)
docker cp freepbx_server:/var/log/asterisk/. data/var/log/asterisk/ || true

# The "|| true" ignores errors if directory is empty
```

#### Copy SSL Certificates

```bash
# Copy SSL certificates (if they exist)
docker cp freepbx_server:/etc/apache2/certs/. data/etc/apache2/certs/ || true
```

#### Copy MariaDB Data

```bash
# For fresh install: skip this (MariaDB will initialize)
# For migration: copy existing database
docker cp freepbx_mariadb:/var/lib/mysql/. data/var/lib/mysql/

# Verify
ls -la data/var/lib/mysql/
# Should show: asterisk, asteriskcdrdb, mysql, performance_schema, etc.
```

### Step 6: Set Correct Permissions

```bash
# Set directory permissions (important for Asterisk)
chmod -R 755 data/

# For production, restrict permissions
# chmod -R 750 data/var/lib/asterisk
# chown -R asterisk:asterisk data/var/lib/asterisk
```

### Step 7: Stop Containers

```bash
# Stop both containers gracefully
docker-compose stop

# Verify they're stopped
docker-compose ps
# Status should show "Exited"
```

### Step 8: Uncomment Volumes in docker-compose.yml

Edit `docker-compose.yml` - Uncomment all the volumes you commented out in Step 3:

```yaml
services:
  freepbx_server:
    # ... other config ...

    # ✅ NOW ENABLE VOLUMES
    volumes:
      - ./data/etc/apache2/certs:/etc/apache2/certs
      - ./data/etc/asterisk:/etc/asterisk
      - ./data/var/lib/asterisk:/var/lib/asterisk
      - ./data/usr/lib64/asterisk:/usr/lib64/asterisk
      - ./data/var/spool/asterisk:/var/spool/asterisk
      - ./data/var/log/asterisk:/var/log/asterisk
      - ./data/var/www/html:/var/www/html
      - ./data/etc/apache2/apache2.conf:/etc/apache2/apache2.conf

  mariadb:
    # ... other config ...

    # ✅ NOW ENABLE MARIADB VOLUME
    volumes:
      - ./data/var/lib/mysql:/var/lib/mysql
      - ./sql:/docker-entrypoint-initdb.d
```

### Step 9: Start Containers WITH Volumes

```bash
# Start containers (now with volumes mounted and data loaded)
docker-compose up -d

# Verify services are starting
docker-compose ps

# Monitor startup
docker-compose logs -f freepbx_server

# Wait for full initialization (1-2 minutes)
```

### Step 10: Verify Data is Accessible

```bash
# Check Asterisk configuration is accessible inside container
docker-compose exec freepbx_server ls -la /etc/asterisk/
# Should match: ls -la data/etc/asterisk/

# Check Asterisk data
docker-compose exec freepbx_server ls -la /var/lib/asterisk/
# Should match: ls -la data/var/lib/asterisk/

# Check FreePBX web files
docker-compose exec freepbx_server ls -la /var/www/html/
# Should show FreePBX files

# Test Asterisk CLI
docker-compose exec freepbx_server asterisk -r
> core show version
> exit
```

### Step 11: Final Verification

```bash
# Check that data is persisting on host
ls -la data/var/lib/asterisk/
ls -la data/var/www/html/

# Test persistence: make a change in container
docker-compose exec freepbx_server bash -c 'echo "test" > /var/lib/asterisk/test.txt'

# Verify on host
cat data/var/lib/asterisk/test.txt
# Should output: test

# Clean up test file
rm data/var/lib/asterisk/test.txt
docker-compose exec freepbx_server rm /var/lib/asterisk/test.txt
```

---

## 🎯 Quick Checklist

- [ ] Created directory structure with correct OS paths
- [ ] Edited .env with secure passwords
- [ ] Commented out volumes in docker-compose.yml
- [ ] Started containers without volumes
- [ ] Used `docker cp` to copy all data
- [ ] Set correct permissions
- [ ] Stopped containers
- [ ] Uncommented volumes in docker-compose.yml
- [ ] Started containers with volumes
- [ ] Verified data is accessible inside containers
- [ ] Verified data matches on host
- [ ] Tested persistence

---

## 🚨 Troubleshooting

### Issue: "docker cp" fails with permission denied

```bash
# Solution: Check container is running
docker-compose ps

# If not running, start without volumes first
docker-compose up -d

# Then retry docker cp
```

### Issue: Data directory already has files from previous mount

```bash
# Clean up old data
rm -rf data/

# Recreate fresh structure
mkdir -p data/{etc/apache2/certs,etc/asterisk}
mkdir -p data/{var/lib/asterisk,var/lib/mysql}
mkdir -p data/{var/log/asterisk,var/spool/asterisk}
mkdir -p data/{var/www/html,usr/lib64/asterisk}

# Start SOP from Step 4
```

### Issue: Asterisk not starting after mounting

```bash
# Check logs
docker-compose logs freepbx_server | tail -50

# Common causes:
# 1. Permissions wrong - fix with: chmod -R 755 data/
# 2. Volume paths incorrect - check docker-compose.yml
# 3. Data corrupted - re-run docker cp
```

### Issue: FreePBX shows blank web page

```bash
# Check web files are mounted
docker-compose exec freepbx_server ls -la /var/www/html/

# Should show: admin, rest, libraries, etc.

# If empty:
# 1. Stop container: docker-compose stop
# 2. Re-run docker cp
# 3. Restart container
```

---

## 📝 Notes

- **Always** comment volumes BEFORE starting containers
- **Always** use `docker cp` while containers are running
- **Never** try to copy into already-mounted volumes (docker cp will fail silently)
- Backup data regularly: `tar -czf backup-$(date +%Y%m%d).tar.gz data/`
- Test recovery process periodically

---

## 📞 Getting Help

If you encounter issues:

1. Check the logs: `docker-compose logs freepbx_server`
2. Verify directory structure: `tree data/ -L 3`
3. Check volume mounts: `docker-compose exec freepbx_server mount | grep /data`
4. Review this SOP step-by-step

---

**Last Updated**: 2026-02-15
**Version**: v17.20
