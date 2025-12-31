# Setup SSH Access for Deployment Containers

**SSH setup needed for these containers before I can deploy services:**
- **111** (Tika) - SSH not accessible
- **120** (Gitea) - Permission denied
- **124** (JupyterLab) - Permission denied
- **127-133** (New services) - Permission denied

## Option 1: Quick Command (Copy-Paste on Each Container)

For each container (**111, 120, 124, 127, 128, 129, 130, 131, 132, 133**):

1. **Open console in Proxmox** for the container
2. **Login as root** (use your Proxmox root password)
3. **Run this single command:**

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/InstallLocalAiPackage/main/scripts/07_enablessh.sh -o /tmp/setup.sh && bash /tmp/setup.sh
```

OR if you can't use curl, use this **all-in-one command:**

```bash
mkdir -p /root/.ssh && chmod 700 /root/.ssh && echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINWvFcpfPYPzu6zxjLUlYDqmJYXRRbxexPBFR6NvSyR5 claude-code" >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && systemctl restart ssh && echo "SSH Setup Complete!"
```

## Option 2: Manual File Copy

If the above doesn't work, on YOUR HOST machine:

```bash
# For each container, replace XXX with container number (127, 128, etc.)
scp scripts/07_enablessh.sh root@10.0.5.XXX:/tmp/setup.sh
ssh root@10.0.5.XXX "bash /tmp/setup.sh"
```

## What This Does

- Creates `/root/.ssh/` directory
- Adds my SSH public key to `authorized_keys`
- Enables root login via SSH
- Enables public key authentication
- Restarts SSH daemon

## After Running

Once you've run this on all 10 containers (111, 120, 124, 127-133), tell me "SSH setup done" and I'll immediately start deploying all services automatically!

---

**Containers to setup:**
- [ ] 111 (Tika)
- [ ] 120 (Gitea)
- [ ] 124 (JupyterLab)
- [ ] 127 (Elasticsearch)
- [ ] 128 (LiteLLM)
- [ ] 129 (Unstructured)
- [ ] 130 (Superset)
- [ ] 131 (Airflow)
- [ ] 132 (Haystack)
- [ ] 133 (LangGraph)
