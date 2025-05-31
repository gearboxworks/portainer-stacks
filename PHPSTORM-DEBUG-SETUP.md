# PhpStorm Docker Debugging Setup Guide

## Overview
This guide configures debugging in PhpStorm for running PHP code in Docker containers, using PhpStorm with automatic file deployment. Based on a working setup where WordPress files are edited locally and automatically synced to a remote Docker environment.

## Prerequisites
- PHP running in Docker containers (PHP + MySQL)
- PhpStorm or WebStorm IDE
- SSH access to Docker host machine
- Deployment user configured for file sync (see main [WordPress Remote Development Setup Guide](./WORDPRESS-SETUP.md))

---

## Part 1: Configure Xdebug in Docker Container

### Dockerfile Configuration
Add Xdebug installation and configuration to your WordPress Dockerfile:

```dockerfile
FROM wordpress:latest
LABEL authors="your-name"

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
  php wp-cli.phar --info && \
  chmod +x wp-cli.phar && \
  mv wp-cli.phar /usr/local/bin/wp && \
  apt-get update && \
  apt-get install -y nano less iputils-ping && \
  pecl install xdebug && \
  docker-php-ext-enable xdebug && \
  cd /usr/local/etc/php && \
  cp php.ini-development php.ini && \
  touch /var/log/xdebug.log && \
  chmod 777 /var/log/xdebug.log && \
  printf "\n\
xdebug.mode=debug\n\
xdebug.client_port=9003\n\
xdebug.start_with_request=yes\n\
xdebug.log=/var/log/xdebug.log\n\
xdebug.idekey=PHPSTORM\n\
xdebug.discover_client_host=true\n\
" >> conf.d/docker-php-ext-xdebug.ini
```

**Key Xdebug Settings Explained:**
- `mode=debug`: Enables step debugging
- `client_port=9003`: Xdebug 3.x default debug port
- `start_with_request=yes`: Automatically attempts debug connection on every request
- `discover_client_host=true`: Auto-detects the client IP address
- `idekey=PHPSTORM`: Identifier for the IDE

### Build and Deploy Container
1. Rebuild your Docker container with the updated Dockerfile
2. Deploy via your container orchestration (Portainer, docker-compose, etc.)

---

## Part 2: Install Browser Extension

### JetBrains Official Extension (Recommended)
Install the **Xdebug Helper by JetBrains** browser extension:
- **Chrome/Edge**: https://chromewebstore.google.com/detail/xdebug-helper-by-jetbrain/aoelhdemabeimdhedkidlnbkfhnhgnhm
- **Firefox**: Search for "Xdebug Helper" in Firefox Add-ons

### Alternative: Manual Cookie Method
If browser extensions aren't available, use browser console:

**Start debugging:**
```javascript
document.cookie = 'XDEBUG_SESSION=PHPSTORM; path=/';
```

**Stop debugging:**
```javascript
document.cookie = 'XDEBUG_SESSION=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/';
```

---

## Part 3: Configure PhpStorm/WebStorm

### Debug Settings
1. **File → Settings → PHP → Debug** (or **WebStorm → Preferences** on Mac)
2. **Configure Xdebug:**
    - **Port**: `9003`
    - **Check**: "Can accept external connections"
    - **Uncheck**: "Force break at first line when no path mapping specified"

### Server Configuration
1. **Settings → PHP → Servers**
2. **Add new server:**
    - **Name**: Your WordPress site URL (e.g., `http://your-etc-hosts-domain.com`)
    - **Host**: Your Docker host IP or domain
    - **Port**: Your WordPress container's exposed port
    - **Use path mappings**: ✓ Check this

3. **Configure Path Mappings:**
    - **Local path**: `/path/to/your/wordpress-root` (absolute path)
    - **Remote path**: `/var/www/html` (path inside the container)

### Test Debug Connection
1. **Start Debug Listener**: Click the phone/bug icon in PhpStorm toolbar
2. **Verify Listening**: Run `netstat -an | grep :9003` - should show PhpStorm listening
3. **If not listening**: Stop and restart the debug listener

---

## Part 4: Testing and Usage

### Basic Debug Test
1. **Create test file** in your WordPress root:
```php
<?php
// test-debug.php
echo "Before breakpoint\n";
$test_var = "Set breakpoint here"; // <-- Set breakpoint on this line
echo "After breakpoint\n";
phpinfo();
?>
```

2. **Set breakpoint** on the `$test_var` line
3. **Start PhpStorm listener** (phone icon should be highlighted)
4. **Enable debugging** in browser extension
5. **Visit** `https://your-etc-hosts-domain.com/test-debug.php`

### Daily Debugging Workflow
1. **Set breakpoints** in your WordPress PHP files
2. **Start PhpStorm listener**
3. **Enable debugging** via browser extension
4. **Navigate to WordPress pages** - debugger will break at your breakpoints
5. **Disable debugging** when done to avoid interruptions

---

## Troubleshooting

### Check Xdebug Status
**Verify Xdebug is loaded:**
```bash
docker exec -it your-wordpress-container php -m | grep xdebug
```

**Check Xdebug configuration:**
```bash
docker exec -it your-wordpress-container php -i | grep xdebug
```

### Monitor Debug Connections
**Watch Xdebug log in real-time:**
```bash
docker exec -it your-wordpress-container tail -f /var/log/xdebug.log
```

**Expected successful connection log:**
```
[Step Debug] INFO: Connected to debugging client: [IP]:9003
```

### Common Issues and Solutions

**Issue: "Port 9003 busy"**
- Check what's using the port: `lsof -i :9003`
- Change debug port in both PhpStorm and Xdebug config

**Issue: "Cannot connect to client"**
- Verify PhpStorm is listening: `netstat -an | grep :9003`
- Check firewall settings on host machine
- Test network connectivity from container to host

**Issue: PhpStorm not listening despite UI showing it is**
- Stop and restart debug listener
- Restart PhpStorm completely
- Check for port conflicts

**Issue: Multiple debug sessions**
- WordPress AJAX calls often trigger debugging
- Use "Stop All Sessions" button in Debug tool window
- Set breakpoints more selectively

### Network Connectivity Test
**From inside container:**
```bash
# Test if container can reach host
docker exec -it your-wordpress-container ping [YOUR_HOST_IP]

# Test debug port accessibility (install telnet first)
docker exec -it your-wordpress-container apt-get update && apt-get install -y telnet
docker exec -it your-wordpress-container telnet [YOUR_HOST_IP] 9003
```

---

## Advanced Configuration

## Multi-Computer Setup
The `discover_client_host=true` setting automatically detects the IP of the machine initiating debug requests, making the setup work across multiple development computers without hardcoding IP addresses.

---

## Validation Notes

PhpStorm's debug validation tool may fail due to file upload path issues, but this doesn't prevent actual debugging from working. If validation fails but debugging works in practice, the setup is correct and validation can be ignored.

The validation failure is typically a PhpStorm working directory issue when uploading temporary test files, not a problem with the actual debug connection.

---

## Benefits of This Setup

- ✅ **Real-time debugging**: Set breakpoints and step through WordPress code
- ✅ **Automatic connection**: No manual debug triggering needed (with `start_with_request=yes`)
- ✅ **Multi-computer support**: Works from any development machine
- ✅ **Container isolation**: Debug configuration contained within Docker
- ✅ **IDE integration**: Full PhpStorm debugging features available
- ✅ **AJAX debugging**: Catches WordPress admin-ajax.php and other background requests