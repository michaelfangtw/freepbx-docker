⚡ FreePBX Docker - Quick Setup Guide

**Choose your workflow below:**

## 🆕 Fresh Installation (3 minutes)

Starting from scratch with a new FreePBX system:

### 1. Clone repository
```bash
git clone <repository-url>
cd freepbx-docker
```

### 2. Create .env file
```bash
cp .env.example .env
# Edit .env and change these critical passwords:
# - DB_PASS=change_to_secure_password
# - MYSQL_ROOT_PASSWORD=change_to_secure_password
```

### 3. Create empty data directories
```bash
mkdir -p data/{certs,lib,etc,www,log,monitor}
mkdir -p datadb
```

**Important**: These directories start **EMPTY**. The containers will initialize with default Asterisk/FreePBX data on first run.

### 4. Start services
```bash
docker-compose up -d
```

Wait 2-3 minutes for containers to initialize.

### 5. Access FreePBX
- **URL**: `https://localhost`
- **Username**: admin
- **Setup**: Follow the FreePBX setup wizard to configure your system

---

## 🔄 Migration from Existing Container

Migrating data from an existing FreePBX container to this docker-compose setup:

### Prerequisites
You have an existing FreePBX container (running or stopped) with data you want to preserve.

### Step 1: Create target directories
```bash
mkdir -p data/{certs,lib,etc,www,log,monitor}
mkdir -p datadb
```

### Step 2: Extract data from existing container

**Option A: If container is still running**

```bash
# Get the running container ID
docker ps | grep freepbx

# Copy Asterisk data
docker cp <container-id>:/var/lib/asterisk/. ./data/lib/

# Copy Asterisk configuration
docker cp <container-id>:/etc/asterisk/. ./data/etc/

# Copy web content
docker cp <container-id>:/var/www/html/. ./data/www/

# Copy logs (optional)
docker cp <container-id>:/var/log/asterisk/. ./data/log/

# Copy SSL certificates (optional)
docker cp <container-id>:/etc/apache2/certs/. ./data/certs/
```

**Option B: If you have a stopped container**

```bash
# Start the container temporarily (read-only mode)
docker start <container-id>

# Run the docker cp commands above

# Stop the container
docker stop <container-id>
```

**Option C: If you only have a Docker image (no running container)**

```bash
# Create temporary container from image
docker run --name temp-freepbx --entrypoint /bin/bash <image-name> sleep 3600

# Copy data while running
docker cp temp-freepbx:/var/lib/asterisk/. ./data/lib/
docker cp temp-freepbx:/etc/asterisk/. ./data/etc/
docker cp temp-freepbx:/var/www/html/. ./data/www/

# Clean up
docker stop temp-freepbx
docker rm temp-freepbx
```

### Step 3: Extract database

**For MariaDB/MySQL data:**

```bash
# If you have the old MariaDB container
docker cp <old-mariadb-container-id>:/var/lib/mysql/. ./datadb/

# OR, export database as SQL
docker exec <old-mariadb-container-id> mysqldump -u root -p<password> asterisk > asterisk.sql
docker exec <old-mariadb-container-id> mysqldump -u root -p<password> asteriskcdrdb > asteriskcdrdb.sql

# Then when new container starts, import:
# docker exec <new-mariadb-container-id> mysql -u root -p<password> asterisk < asterisk.sql
```

### Step 4: Create .env file
```bash
cp .env.example .env
# Edit .env with same credentials used in old container
# IMPORTANT: Use the SAME DB_PASS and MYSQL_ROOT_PASSWORD as the old system
```

### Step 5: Start services
```bash
docker-compose up -d
```

### Step 6: Verify migration
```bash
# Check containers are running
docker-compose ps

# Verify data is accessible
docker-compose exec freepbx_server ls -la /var/lib/asterisk/
docker-compose exec freepbx_server ls -la /etc/asterisk/

# Check database connection
docker-compose exec freepbx_server mysql -h mariadb -u asterisk -p<DB_PASS> asterisk
```

---

## 📊 Data Workflow Comparison

| Aspect | Fresh Install | Migration |
|--------|---|---|
| **Initial directories** | Empty | Populated via docker cp |
| **Container startup** | Initializes with defaults | Uses existing config |
| **Data source** | Container's default files | Your extracted files |
| **Volume mount** | Bind mounts to empty dirs | Bind mounts to populated dirs |
| **Time to ready** | 2-3 minutes | 1-2 minutes |
| **Data loss risk** | None (starting fresh) | Only if docker cp fails |

---

## ❓ Why This Two-Step Process?

### The Problem
When using **bind mounts** (like `./data/lib:/var/lib/asterisk`), Docker has these rules:

- **If directory is empty on host**: Container can write to it, but it starts empty
- **If directory has files on host**: These files are visible in container at startup

### Fresh Installation
For a new system, you want:
1. Container starts with default Asterisk/FreePBX installation
2. Files initialize automatically
3. User completes setup wizard
4. Data persists to `./data/*` directories

### Migration
For an existing system, you want:
1. Extract all files from old container first (via docker cp)
2. Place in `./data/*` directories on host
3. Start new container with bind mounts
4. Container sees your existing configuration immediately
5. No re-setup needed

---

## ⚠️ What Happens If You Skip These Steps?

### 1. Skip creating .env file

**Consequence**: Containers will use default/example values
- Database passwords default to example values (insecure!)
- All containers can communicate but with hardcoded credentials
- **CRITICAL SECURITY ISSUE**: Anyone with access to docker-compose.yml can see passwords

```
❌ RESULT: Docker Compose startup fails or uses unsafe defaults
```

### 2. Skip creating ./data directories

**Fresh Install Consequence**:
```
✅ OK: Docker creates them automatically on first run
   - Container writes default files into empty directories
   - System works fine
```

**Migration Consequence**:
```
❌ FAIL: Docker creates empty directories
   - `docker cp` has nowhere to paste extracted data
   - OR you paste data after docker-compose starts
   - Volume mounts already created empty, can't see new files
   - Must restart containers: docker-compose restart
   - (Extra step, but recoverable)
```

### 3. Skip changing DB_PASS in .env

**Consequence**: Default password remains (example_password)
```
❌ SECURITY RISK: Password exposed in git repo
❌ Any developer/anyone with repo access can access database
❌ Production deployment vulnerable to unauthorized access
```

### 4. Skip Migration docker cp (if migrating)

**Consequence**: Your existing data is LOST
```
❌ LOST: All extensions, voicemail, call recordings, configurations
❌ LOST: CDR (call records), billing data
❌ LOST: Custom dialplans, IVR settings
❌ Starting fresh with empty system

This is UNRECOVERABLE if you don't have backups!
```

### 5. Skip changing MYSQL_ROOT_PASSWORD

**Consequence**: Database root is accessible with default password
```
❌ SECURITY RISK: Anyone can log in as root
❌ RISK: Drop entire database, delete all data
❌ RISK: Modify user tables, create backdoors
```

### 6. Create empty datadb/ directory but don't copy old MySQL data

**Migration Consequence**:
```
❌ LOSS: Old database deleted, cannot recover
   - MariaDB initializes fresh when it sees empty datadb/
   - All asterisk configuration database lost
   - All CDR (call detail records) lost
   - Cannot restore without backup file

⚠️ MariaDB container uses ./datadb volume mount
   - If directory is empty, it creates fresh database
   - Old data is GONE (unless you have SQL dumps)
```

---

## 📋 Quick Risk Checklist

Before running `docker-compose up -d`:

| Step | Skip? | Consequence |
|------|-------|-------------|
| Clone repo | ❌ NO | Can't run anything |
| Create .env | ❌ NO | Uses unsafe defaults |
| Change DB_PASS | ❌ NO | Security vulnerability |
| Change MYSQL_ROOT_PASSWORD | ❌ NO | Database compromise risk |
| Create data/ directories | ⚠️ MAYBE | Auto-created, but messy |
| Create datadb/ directory | ✅ OK | Auto-created by MariaDB |
| **Migration: docker cp /var/lib/asterisk** | ❌ NO | **ALL DATA LOST** ⚠️ |
| **Migration: docker cp /etc/asterisk** | ❌ NO | **ALL CONFIGS LOST** ⚠️ |
| **Migration: docker cp /var/www/html** | ❌ NO | **WEB CONTENT LOST** ⚠️ |

---

## 🛟 How to Recover If You Made Mistakes

### Deleted data accidentally?

**If you have SQL backup files:**
```bash
# Stop containers
docker-compose stop

# Restart MariaDB
docker-compose up -d mariadb

# Wait for MariaDB to be ready
sleep 10

# Restore from backup
docker-compose exec mariadb mysql -u root -p asterisk < asterisk.sql
docker-compose exec mariadb mysql -u root -p asteriskcdrdb < asteriskcdrdb.sql

# Start FreePBX
docker-compose up -d freepbx_server
```

**If you don't have backups:**
```
❌ Data is UNRECOVERABLE
⚠️ You must reconfigure from scratch or restore from external backup
```

### Used wrong password in .env?

```bash
# Edit .env with correct password
nano .env

# Restart services
docker-compose restart

# Verify connection
docker-compose exec freepbx_server mysql -h mariadb -u asterisk -p<DB_PASS> asterisk
```

### docker-compose won't start?

```bash
# Check logs for specific errors
docker-compose logs freepbx_server

# Common causes:
# 1. .env not created → Create it
# 2. Directory permissions → chmod -R 755 data/
# 3. Port already in use → Change ports in docker-compose.yml
```

---

## 🆘 Troubleshooting

### "Permission denied" when copying data
```bash
# Fix permissions after docker cp
chmod -R 755 data/
```

### Data doesn't appear in container
```bash
# Verify bind mount worked
docker-compose exec freepbx_server mount | grep /var/lib/asterisk
docker-compose exec freepbx_server ls -la /var/lib/asterisk
```

### Container won't start
```bash
# Check logs
docker-compose logs freepbx_server

# Verify directory ownership
ls -la data/lib/
ls -la data/etc/
```

### Database connection fails after migration
```bash
# Verify database imported correctly
docker-compose exec mariadb mysql -u root -p asterisk -e "SHOW TABLES;"

# Check if database files exist
ls -la datadb/
```

---

## 📝 Next Steps

After setup completes:

1. **Access the Web Interface**
   - Go to `https://localhost/admin`
   - Login with credentials you set during setup

2. **Configure Extensions**
   - Create SIP extensions for your phones
   - Set up voicemail
   - Configure call routing

3. **Test Connectivity**
   - Register a SIP phone to your system
   - Make test calls

4. **Backup Your Data**
   - See [DOCKER_COMPOSE_ANALYSIS.md](./DOCKER_COMPOSE_ANALYSIS.md) for backup procedures

---

**For detailed usage guide, see [USAGE_GUIDE.md](./USAGE_GUIDE.md)**
