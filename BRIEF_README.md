# FreePBX Docker - Quick Overview

A containerized telephony system combining Asterisk, FreePBX, and MariaDB for VoIP communications.

## Component Versions

| Component | Version |
|-----------|---------|
| **Asterisk** | 20-current |
| **FreePBX** | 17.0 (EDGE) |
| **MariaDB** | Latest (Debian 12) |
| **PHP** | 8.2 |
| **Base OS** | Debian 12 |

## Quick Usage

### Build & Run
```bash
# Clone and setup
git clone <repo-url>
cd freepbx-docker
cp .env.example .env          # Edit passwords!
mkdir -p data/{certs,lib,etc,www,log}
mkdir -p datadb

# Start services
docker-compose up -d
```

### Access
- **Web UI**: `https://localhost/admin`
- **Asterisk CLI**: `docker-compose exec freepbx_server asterisk -r`
- **Database**: `docker-compose exec mariadb mysql -u root -p asterisk`

## Key Ports
- **443** - HTTPS (FreePBX web)
- **5060/UDP** - SIP signaling
- **5160/UDP** - IAX2
- **18000-18100/UDP** - RTP media

## Data Persistence
All data stored in `./data/` and `./datadb/`:
- Configurations, extensions, voicemail, call records
- Survive container restarts and recreation

## Documentation
- [Full Setup Guide](./SETUP.md)
- [Usage Guide](./USAGE_GUIDE.md)
- [Quick Reference](./QUICK_REFERENCE.md)
