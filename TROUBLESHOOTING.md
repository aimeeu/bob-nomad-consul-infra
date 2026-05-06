# Troubleshooting Guide

## Nomad Service Failures

### Check Service Status
```bash
# Check service status
sudo systemctl status nomad

# View recent logs
sudo journalctl -xeu nomad.service -n 50

# View all Nomad logs
sudo journalctl -u nomad.service --no-pager
```

### Common Issues

#### 1. Configuration Validation Errors

**Symptom**: Service fails to start with configuration errors

**Solution**:
```bash
# Validate configuration manually
sudo nomad agent -config=/etc/nomad.d -dry-run

# Check configuration file syntax
sudo cat /etc/nomad.d/nomad.hcl
```

#### 2. Permission Issues

**Symptom**: "Permission denied" errors in logs

**Solution**:
```bash
# Check directory ownership
ls -la /opt/nomad/data
ls -la /etc/nomad.d

# Fix ownership if needed
sudo chown -R root:root /opt/nomad
sudo chown -R root:root /etc/nomad.d
```

#### 3. Port Conflicts

**Symptom**: "Address already in use" errors

**Solution**:
```bash
# Check what's using Nomad ports
sudo netstat -tlnp | grep -E '4646|4647|4648'
sudo lsof -i :4646
sudo lsof -i :4647
sudo lsof -i :4648

# Kill conflicting processes if needed
sudo systemctl stop nomad
sudo pkill nomad
```

#### 4. Consul Connection Issues

**Symptom**: "Failed to connect to Consul" errors

**Solution**:
```bash
# Check Consul status
sudo systemctl status consul

# Test Consul connectivity
curl http://127.0.0.1:8500/v1/status/leader

# Check Consul logs
sudo journalctl -u consul.service -n 50
```

#### 5. Docker Driver Issues

**Symptom**: "Docker driver not detected" or container failures

**Solution**:
```bash
# Check Docker status
sudo systemctl status docker

# Test Docker
sudo docker ps
sudo docker run hello-world

# Check Docker socket permissions
ls -la /var/run/docker.sock

# Add nomad user to docker group (if not using root)
sudo usermod -aG docker nomad
```

#### 6. Network Interface Issues

**Symptom**: "Failed to detect network interface" errors

**Solution**:
```bash
# List network interfaces
ip addr show

# Check configured interface in Nomad config
grep network_interface /etc/nomad.d/nomad.hcl

# Update if needed
sudo nano /etc/nomad.d/nomad.hcl
```

### Manual Service Restart

```bash
# Stop service
sudo systemctl stop nomad

# Clear any stale state
sudo rm -rf /opt/nomad/data/server/*
sudo rm -rf /opt/nomad/data/client/*

# Reload systemd
sudo systemctl daemon-reload

# Start service
sudo systemctl start nomad

# Check status
sudo systemctl status nomad
```

### Configuration Validation

Before starting Nomad, validate the configuration:

```bash
# For servers
sudo nomad agent -config=/etc/nomad.d -dry-run

# Check specific config file
sudo nomad agent -config=/etc/nomad.d/nomad.hcl -dry-run
```

### Debugging Steps

1. **Check Prerequisites**:
   ```bash
   # Verify Consul is running
   sudo systemctl status consul
   
   # Verify Docker is running (for clients)
   sudo systemctl status docker
   
   # Check network connectivity
   ping -c 3 8.8.8.8
   ```

2. **Verify Configuration**:
   ```bash
   # Check config file exists
   ls -la /etc/nomad.d/nomad.hcl
   
   # Validate syntax
   sudo nomad agent -config=/etc/nomad.d -dry-run
   ```

3. **Check Logs**:
   ```bash
   # Real-time logs
   sudo journalctl -u nomad.service -f
   
   # Last 100 lines
   sudo journalctl -u nomad.service -n 100
   ```

4. **Test Connectivity**:
   ```bash
   # From client to servers
   nc -zv <server-ip> 4647
   nc -zv <server-ip> 4648
   
   # Check Consul
   curl http://127.0.0.1:8500/v1/catalog/services
   ```

## Consul Service Failures

### Check Service Status
```bash
sudo systemctl status consul
sudo journalctl -xeu consul.service -n 50
```

### Common Issues

#### 1. Port 53 Conflict with systemd-resolved

**Solution**: Already handled in playbook, but verify:
```bash
# Check if systemd-resolved is stopped
sudo systemctl status systemd-resolved

# Check DNS configuration
cat /etc/resolv.conf
```

#### 2. ACL Bootstrap Issues

**Symptom**: "ACL not found" errors

**Solution**:
```bash
# Check if ACL is bootstrapped
consul acl bootstrap

# If already bootstrapped, use saved token
export CONSUL_HTTP_TOKEN=$(cat /tmp/consul_bootstrap_token.txt)
consul members
```

## Ansible Playbook Failures

### Re-run Specific Roles

```bash
# Re-run only Nomad role
ansible-playbook -i inventory.ini site.yml --tags nomad

# Re-run only Consul role
ansible-playbook -i inventory.ini site.yml --tags consul

# Re-run with verbose output
ansible-playbook -i inventory.ini site.yml -vvv
```

### Check Connectivity

```bash
# Test SSH connectivity
ansible all -i inventory.ini -m ping

# Check if hosts are reachable
ansible all -i inventory.ini -m shell -a "hostname"
```

## AWS Infrastructure Issues

### Check EC2 Instances

```bash
# List instances
aws ec2 describe-instances --filters "Name=tag:Project,Values=nomad-consul-infra"

# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

### SSH Connection Issues

```bash
# Test SSH connection
ssh -i terraform/nomad-consul-key.pem ubuntu@<instance-ip>

# Check key permissions
chmod 400 terraform/nomad-consul-key.pem
```

## Getting Help

If issues persist:

1. Collect logs:
   ```bash
   sudo journalctl -u nomad.service > nomad.log
   sudo journalctl -u consul.service > consul.log
   ```

2. Check configuration:
   ```bash
   sudo cat /etc/nomad.d/nomad.hcl > nomad-config.txt
   sudo cat /etc/consul.d/consul.hcl > consul-config.txt
   ```

3. Gather system info:
   ```bash
   uname -a > system-info.txt
   docker version >> system-info.txt
   nomad version >> system-info.txt
   consul version >> system-info.txt
   ```

4. Review the logs and configuration files for specific error messages.