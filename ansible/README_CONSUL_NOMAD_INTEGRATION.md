# Consul Configuration for Nomad Workload Identity

This playbook configures Consul to work with Nomad workload identity, enabling secure service-to-service communication and automatic token generation for Nomad workloads.

## Overview

The playbook creates:
1. **Nomad Server Policy** - Allows Nomad servers to manage services and ACL tokens
2. **Nomad Client Policy** - Allows Nomad clients to register services
3. **Nomad Workload Policy** - Policy for workloads using workload identity
4. **JWT Auth Method** - Enables Nomad to authenticate workloads via JWT
5. **Binding Rules** - Automatically assigns policies to workloads

## Prerequisites

1. Consul cluster must be running with ACLs enabled
2. Consul bootstrap token must exist at `/tmp/consul_bootstrap_secret_id.txt`
3. Run the main site.yml playbook first to set up Consul

## Usage

### Run the Configuration Playbook

```bash
cd ansible
ansible-playbook -i inventory.ini configure_consul_for_nomad.yml
```

### Generated Tokens

The playbook creates and saves two tokens locally:

1. **Nomad Server Token**: `/tmp/nomad_server_consul_token.txt`
   - Used by Nomad servers to manage Consul
   - Has permissions to create tokens for workloads
   - Configure in Nomad server's `consul` block

2. **Nomad Client Token**: `/tmp/nomad_client_consul_token.txt`
   - Used by Nomad clients to register services
   - Has read/write permissions for services
   - Configure in Nomad client's `consul` block

## Consul Policies Created

### 1. Nomad Server Policy (`nomad-server`)

Allows Nomad servers to:
- Read agent and node information
- Write services and manage service registrations
- Create ACL tokens for workloads (ACL write)
- Read key-value store
- Manage prepared queries
- Manage service mesh intentions

### 2. Nomad Client Policy (`nomad-client`)

Allows Nomad clients to:
- Read agent and node information
- Write services for task registration
- Read key-value store

### 3. Nomad Workload Policy (`nomad-workload`)

Allows workloads to:
- Register their own services
- Read other services for discovery
- Read nodes for health checks
- Read key-value store
- Use prepared queries

## Configuring Nomad

### Nomad Server Configuration

Add to your Nomad server configuration (`/etc/nomad.d/nomad.hcl`):

```hcl
consul {
  address = "127.0.0.1:8500"
  token   = "<NOMAD_SERVER_TOKEN>"
  
  # Enable service identity for workloads
  service_identity {
    aud = ["consul.io"]
    ttl = "1h"
  }
  
  # Enable task identity for workloads
  task_identity {
    aud = ["consul.io"]
    ttl = "1h"
  }
}
```

### Nomad Client Configuration

Add to your Nomad client configuration (`/etc/nomad.d/nomad.hcl`):

```hcl
consul {
  address = "127.0.0.1:8500"
  token   = "<NOMAD_CLIENT_TOKEN>"
}
```

### Get Token Values

```bash
# Get Nomad server token
grep "SecretID (for configuration):" /tmp/nomad_server_consul_token.txt | awk '{print $NF}'

# Get Nomad client token
grep "SecretID (for configuration):" /tmp/nomad_client_consul_token.txt | awk '{print $NF}'
```

## Using Workload Identity in Jobs

### Example Job with Workload Identity

```hcl
job "example" {
  datacenters = ["dc1"]
  
  group "web" {
    network {
      port "http" {
        to = 8080
      }
    }
    
    service {
      name = "web-service"
      port = "http"
      
      # Enable Consul service identity
      identity {
        aud = ["consul.io"]
        ttl = "1h"
      }
      
      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }
    
    task "web" {
      driver = "docker"
      
      # Enable task identity for Consul access
      identity {
        aud = ["consul.io"]
        ttl = "1h"
      }
      
      config {
        image = "nginx:latest"
        ports = ["http"]
      }
    }
  }
}
```

## JWT Auth Method

The playbook configures a JWT auth method named `nomad-workloads` that:
- Validates JWT tokens from Nomad
- Maps Nomad claims to Consul identities
- Automatically assigns appropriate policies
- Binds services based on Nomad metadata

### Claim Mappings

- `nomad_namespace` → Consul namespace (if using Consul Enterprise)
- `nomad_job_id` → Job identifier
- `nomad_task` → Task name

## Verification

### Check Policies

```bash
export CONSUL_HTTP_TOKEN=$(cat /tmp/consul_bootstrap_secret_id.txt)

# List all policies
consul acl policy list

# Read specific policy
consul acl policy read -name nomad-server
consul acl policy read -name nomad-client
consul acl policy read -name nomad-workload
```

### Check Tokens

```bash
# List all tokens
consul acl token list

# Read Nomad server token
consul acl token read -id <SERVER_TOKEN_ID>
```

### Check Auth Method

```bash
# List auth methods
consul acl auth-method list

# Read JWT auth method
consul acl auth-method read -name nomad-workloads

# List binding rules
consul acl binding-rule list -method nomad-workloads
```

## Troubleshooting

### Error: Token not found

Ensure the Consul bootstrap token exists:
```bash
ls -la /tmp/consul_bootstrap_secret_id.txt
```

If missing, run the main playbook first:
```bash
ansible-playbook -i inventory.ini site.yml
```

### Error: Policy already exists

The playbook will update existing policies. This is normal on subsequent runs.

### Error: Permission denied

Verify the bootstrap token has admin privileges:
```bash
export CONSUL_HTTP_TOKEN=$(cat /tmp/consul_bootstrap_secret_id.txt)
consul acl token read -self
```

### Workload identity not working

1. Verify Nomad server has the correct token configured
2. Check Nomad server logs for JWT signing errors
3. Ensure the JWT auth method is properly configured
4. Verify binding rules are created

## Security Best Practices

1. **Rotate Tokens Regularly**: Create new tokens periodically
2. **Least Privilege**: Use specific policies for each workload type
3. **Audit Logs**: Enable Consul audit logging
4. **Token TTL**: Set appropriate TTLs for workload tokens
5. **Secure Storage**: Store tokens securely, never in version control

## References

- [Nomad Consul Integration](https://developer.hashicorp.com/nomad/docs/integrations/consul-integration)
- [Nomad Workload Identity](https://developer.hashicorp.com/nomad/docs/concepts/workload-identity)
- [Consul ACL System](https://developer.hashicorp.com/consul/docs/security/acl)
- [Consul JWT Auth Method](https://developer.hashicorp.com/consul/docs/security/acl/auth-methods/jwt)