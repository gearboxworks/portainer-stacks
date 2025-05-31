# WordPress Remote Development Setup Guide

## Overview
This guide sets up a development workflow where you can edit WordPress files locally on your development computer using WebStorm, with the website running in Docker containers on a remote Debian VM. Changes sync automatically and provide fast performance.

## Architecture
- **Local Development Computer**: WebStorm IDE editing files in Git repository
- **Remote Debian VM**: Docker containers serving WordPress
- **Sync Method**: WebStorm SFTP auto-deployment

---

## Part 1: Prepare Docker Environment

### Step 1: Create WordPress Directory and Deployment User on Debian VM
SSH into your Debian VM:
```bash
ssh your-username@your-debian-vm-ip

# Create directory with standard web server ownership
sudo mkdir -p /srv/wordpress
sudo chown -R www-data:www-data /srv/wordpress

# Set proper group permissions for deployment
sudo chmod g+w /srv/wordpress
sudo chmod g+s /srv/wordpress

# Create a dedicated deployment user for WebStorm SFTP
sudo useradd -s /bin/bash -G www-data wp-deploy
sudo passwd wp-deploy
```

### Step 2: Create Dedicated SSH Key for Deployment
On your local development computer, create a dedicated SSH key for the wp-deploy user:
```bash
# Generate a new SSH key pair specifically for wp-deploy
ssh-keygen -t ed25519 -C "wp-deploy@your-project" -f ~/.ssh/wp-deploy

# Copy the public key to the wp-deploy user on your VM
ssh-copy-id -i ~/.ssh/wp-deploy.pub wp-deploy@your-debian-vm-ip
```

### Step 3: Configure SSH Client
Add the following configuration to your `~/.ssh/config` file on your local development computer:
```
Host wp-deploy
    HostName your-debian-vm-ip
    User wp-deploy
    PreferredAuthentications publickey
    AddKeysToAgent yes
    IdentitiesOnly yes
    UseKeychain yes
    IdentityFile ~/.ssh/wp-deploy
```

**Note**: Replace `your-debian-vm-ip` with your actual VM's hostname or IP address.

### Step 4: Test SSH Connection
Verify the SSH setup works:
```bash
# Test the connection
ssh wp-deploy

# You should be logged into your VM as the wp-deploy user
```

### Step 2: Update Docker Compose Configuration
Edit your docker-compose file to change from CIFS volume to bind mount:

**Before:**
```yaml
services:
  wordpress:
    volumes:
      - wordpress-root:/var/www/html

volumes:
  wordpress-root:
    external: true
```

**After:**
```yaml
services:
  php:
    volumes:
      - /srv/wordpress:/var/www/html
    # Let container use default user (www-data)

# Remove the volumes section entirely
```

### Step 3: Restart Docker Stack
In Portainer:
1. Go to your WordPress stack
2. Stop the stack
3. Start the stack (it will now use the local bind mount)

---

## Part 3: Copy WordPress Files

### Copy WordPress Files from Local Development Computer
Copy your existing WordPress files from your local development computer to the VM:
```bash
# From your local development computer, copy the wordpress-root directory to the VM
# Using rsync for efficient, incremental copying
rsync -avz --delete ./wordpress-root/ wp-deploy:/srv/wordpress/

# SSH into VM and fix ownership of uploaded files
ssh your-username@your-debian-vm-ip
sudo chown -R www-data:www-data /srv/wordpress

# Ensure subdirectories maintain proper group permissions
sudo find /srv/wordpress -type d -exec chmod g+ws {} \;
```

**Note**: The `rsync` command with `--delete` will make `/srv/wordpress/` an exact mirror of your local `./wordpress-root/` directory, including removing any files on the server that don't exist locally.

---

## Part 4: Configure WebStorm SFTP Deployment

### Step 1: Open Project in WebStorm
Open your Git repository (containing `wordpress-root/` directory) in WebStorm.

### Step 2: Configure SSH Connection
1. **File → Settings** (Windows/Linux) or **WebStorm → Preferences** (Mac)
2. **Build, Execution, Deployment → SSH Configurations**
3. **Click "+" to add new SSH configuration:**
   - **Host**: Your Debian VM IP address
   - **Port**: 22 (or your custom SSH port)
   - **Username**: `wp-deploy`
   - **Authentication type**: Key pair
   - **Private key file**: `~/.ssh/wp-deploy`
4. **Test Connection** to verify it works
5. **OK** to save

### Step 3: Configure SFTP Deployment
1. **Build, Execution, Deployment → Deployment**
2. **Click "+" to add new server → SFTP**
3. **Configure Connection tab:**
   - **Name**: "WordPress VM" (or any name you prefer)
   - **SSH configuration**: Select the SSH config you just created
   - **Root path**: `/` (leave as default)
   - **Check "Visible only for this project"** if desired

### Step 4: Set Up Path Mappings
1. **Switch to "Mappings" tab**
2. **Configure mapping:**
   - **Local path**: Click folder icon and select your `wordpress-root` directory
   - **Deployment path**: `/srv/wordpress`
   - **Web path**: Leave blank

### Step 5: Configure Auto-Upload Options
1. **Switch to "Options" tab**
2. **Recommended settings:**
   - **Upload changed files automatically**: Select "On explicit save action"
   - **Delete remote files when local are deleted**: Check this if desired
   - **Create empty directories**: Check this
   - **Preserve files timestamps**: Check this

### Step 6: Enable Automatic Upload
1. **Tools → Deployment → Automatic Upload → Always** (or "On explicit save action")
2. This enables auto-sync whenever you save files

### Step 7: Initial Upload
1. **Right-click on your `wordpress-root` folder** in the Project tree
2. **Deployment → Upload to "WordPress VM"**
3. Wait for initial sync to complete

---

## Part 3: Remove Old CIFS Volume (Cleanup)

### Step 1: Remove CIFS Volume from Portainer
1. **Portainer → Volumes**
2. **Find the old `wordpress-root` CIFS volume**
3. **Remove it** (ensure no containers are using it first)

### Step 2: Remove Mac File Sharing (Optional)
If you no longer need it:
1. **System Settings → General → Sharing → File Sharing**
2. **Remove the `wordpress-root` shared folder**
3. **Toggle File Sharing OFF** if not needed for other purposes

---

## Usage Instructions

### Daily Development Workflow
1. **Open WebStorm** and edit files in your `wordpress-root/` directory
2. **Save files** (Cmd+S / Ctrl+S) - they automatically sync to the VM
3. **View changes** immediately on your WordPress site
4. **Commit to Git** as normal from your local repository

### Manual Sync Operations
- **Upload entire project**: Right-click `wordpress-root` → Deployment → Upload
- **Download from server**: Right-click → Deployment → Download
- **Compare local vs remote**: Right-click → Deployment → Compare with Deployed Version
- **Sync specific file**: Right-click file → Deployment → Upload/Download

### Troubleshooting
- **Check deployment console**: View → Tool Windows → Deployment
- **Test SSH connection**: Settings → SSH Configurations → Test Connection
- **Verify file permissions**: Ensure `www-data` user owns the `/srv/wordpress` directory
- **Check deploy user setup**: Verify you can SSH as the wp-deploy user: `ssh wp-deploy@vm-ip`
- **Verify group membership**: Check that wp-deploy user is in www-data group: `groups wp-deploy`
- **Check container logs**: In Portainer, view WordPress container logs for errors

---

## Benefits of This Setup
- ✅ **Fast performance**: PHP files served locally from VM
- ✅ **Real-time sync**: Changes appear immediately in containers
- ✅ **IDE integration**: All WebStorm features work normally
- ✅ **Git workflow**: Standard Git operations on local files
- ✅ **Reliable**: Uses battle-tested SFTP protocol
- ✅ **No external dependencies**: No need for additional tools or scripts
- ✅ **Robust**: Uses standard `www-data` ownership that works across all distributions
- ✅ **Future-proof**: No custom UID/GID mapping that could break with updates
- ✅ **Standards-compliant**: Uses `/srv` for site-specific data as per FHS

## Performance Notes
This setup eliminates the network file access bottleneck by:
- Storing WordPress files locally on the VM
- Using WebStorm's efficient SFTP sync
- Maintaining fast Docker container file access