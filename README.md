# InstallLocalAiPackage
Here is the **Server Setup & Initialization Context** designed specifically to be prepended to the previous README.
https://github.com/coleam00/local-ai-packaged/tree/main

When you feed this to another AI, it will understand the exact state of the Operating System **before** the AI application stack is deployed.

---

## CHANGELOG - Infrastructure Fixes (2025-11-23)

### Changes Made to Ensure First-Try Deployment Success

#### 1. Fixed User Creation Automation ([02_install_docker.sh](02_install_docker.sh))
**Problem:** Script prompted for username interactively, breaking automation when `chain_setup.sh` expected `ai-admin`.

**Solution:**
- Removed interactive `read -p` prompt
- User now accepts username as first argument: `$1` (defaults to `ai-admin`)
- Changed `adduser --gecos ""` → `adduser --disabled-password --gecos ""` to prevent password prompts
- Added NOPASSWD sudoers rule: `/etc/sudoers.d/$target_user` for fully automated execution

**Files Modified:** [02_install_docker.sh:41-64](02_install_docker.sh#L41-L64)

#### 2. Improved Error Handling ([chain_setup.sh](chain_setup.sh))
**Problem:** All output redirected to `/dev/null 2>&1` caused silent failures.

**Solution:**
- Removed stderr suppression (`2>&1`) from script execution
- Added explicit error checks with `if !` conditionals for all critical steps
- Added repository verification to ensure `start_services.py` exists post-clone

**Files Modified:** [chain_setup.sh:21-50](chain_setup.sh#L21-L50)

#### 3. Service Integration Documentation
**Added Complete Dependency Map:**
- **Open WebUI** → Qdrant, Ollama, SearXNG, n8n
- **Flowise** → Supabase Postgres, Qdrant, Ollama
- **n8n** → Supabase Postgres, Ollama
- **Langfuse** → Supabase Postgres, Clickhouse
- **Neo4j** → Standalone (available for knowledge graphs)

All integrations configured automatically via `setup_ultra_node.py` environment injection.

---

TRAEFIK SERVER IP 10.0.4.10
Dynamic Folder is in /opt/traefik-stack/dynamic

The IP of container one is 10.0.5.7 and the domain is just nothing so direct, valuechainhackers.xyz (openwebui.valuechainhackers.xyz) for example
The IP of container two is 10.0.5.8 Reuse.valuechainhackers.xyz
The IP of container three is 10.0.5.9 team2.valuechainhackers.xyz
The IP of container four is 10.0.5.10 team3.valuechainhackers.xyz
The IP of container Five is 10.0.5.11 team4.valuechainhackers.xyz
The IP of container Six is 10.0.5.12 team5.valuechainhackers.xyz



***

# 0. Infrastructure & Server Initialization Context

## System Architecture
* **Base Operating System:** Debian 12 "Bookworm" (Minimal/Netinst Install).
* **Kernel:** Standard Linux Kernel (Proxmox LXC/VM).
* **Privilege Hierarchy:**
    * **Root (`UID 0`):** Used *only* for bootstrapping dependencies and Docker engine installation.
    * **Service User (`UID > 1000`):** A dedicated, password-less automation account (default: `ai-admin`) created specifically to own the Docker socket and application files.

## Bootstrapping Sequence (Root Layer)
The initialization process transforms a generic Debian environment into a Docker Host via three sequenced shell scripts.

### 1. Dependency Resolution (`01_system_dependencies.sh`)
* **Action:** Updates `apt` cache and upgrades existing packages.
* **Package Injection:** Installs utilities often missing from minimal images:
    * `sudo`: Required for privilege delegation.
    * `curl`, `wget`, `gnupg`: Required for repository key management.
    * `python3`, `python3-venv`, `python3-pip`: Required for the Python Setup Wizard (`setup_ultra_node.py`).
    * `git`: Required for repository cloning.

### 2. Container Runtime Engine (`02_install_docker.sh`)
* **Repository Management:** Removes conflicting Debian-native Docker packages (`docker.io`) and installs the official `download.docker.com` repository and GPG keys.
* **Engine Installation:** Installs `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, and `docker-compose-plugin`.
* **User Provisioning:**
    * Creates user `ai-admin` (flag `--disabled-password`).
    * Appends user to `docker` group (Socket access).
    * Appends user to `sudo` group.
    * **Privilege Bypass:** Writes specific rule to `/etc/sudoers.d/ai-admin` to allow `NOPASSWD:ALL`. This is critical for automated script execution without TTY intervention.

### 3. Orchestration & Handoff (`chain_setup.sh`)
This is the **Entry Point** for the operator. It enforces the following execution logic:
1.  **Root Check:** Verifies execution as `root`.
2.  **Sequential Execution:** Runs `01` -> `02`.
3.  **Context Switching:**
    * Drops privileges via `su - ai-admin`.
    * Clones the target application repository (`coleam00/local-ai-packaged`) into `/home/ai-admin/`.
    * **Artifact Injection:** Copies the `setup_ultra_node.py` wizard from the install directory into the repository root.
    * **Trigger:** Executes the Python Wizard inside the user context to begin Application Layer deployment.

Here is a `README.md` optimized for LLM (Large Language Model) parsing.

It prioritizes high semantic density, structural clarity, explicit relationship mapping, and procedural logic over human-centric narrative. If you paste this context into another AI, it will immediately understand the topology, execution flow, and state changes required.

-----

# Local AI Stack Deployment Suite (Debian 12 / Docker)

## 1\. System Identity & Objective

  * **Target OS:** Debian 12 (Bookworm) - Bare Metal / LXC Container.
  * **Target Environment:** Proxmox Virtualization Cluster (CPU Inference / No GPU Pass-through).
  * **Networking Topology:** Internal Docker Network exposed to Host IP; routed via External Traefik Proxy (Dynamic Configuration).
  * **Objective:** Zero-touch deployment of a multi-tenant, fully interconnected Generative AI stack (n8n, Supabase, Flowise, Open WebUI, Ollama, Qdrant, etc.).

## 2\. Repository Manifest

| File | Executor | Permissions | Function |
| :--- | :--- | :--- | :--- |
| `01_system_dependencies.sh` | `root` | `755` | Updates `apt`, installs `sudo`, `git`, `python3-venv`, `build-essential`. Prepares bare OS. |
| `02_install_docker.sh` | `root` | `755` | Installs official Docker Engine. Creates Service User (`ai-admin`). Configures `nopasswd` sudo access. |
| `chain_setup.sh` | `root` | `755` | **Master Orchestrator.** Chains `01` -\> `02` -\> Clones Repo -\> Handoffs to User -\> Triggers Python Wizard. |
| `setup_ultra_node.py` | `user` | `644` | **Configuration Logic.** Auto-detects network. Generates crypto secrets. Writes `.env`. Configures Docker Overrides. |

## 3\. Deployment Workflow (State Machine)

### State 0: Initial

  * **Context:** Fresh Debian 12 install.
  * **User:** `root`
  * **Dependencies:** None.

### Transition A: Infrastructure Layer

**Command:** `bash chain_setup.sh`

1.  **Sys Prep:** System packages installed.
2.  **Runtime:** Docker Engine installed & active.
3.  **Identity:** User `ai-admin` created with Docker group privileges.

### Transition B: Application Layer (Automated)

*The Orchestrator switches context to `ai-admin` and executes `setup_ultra_node.py`.*

1.  **Clone:** Repository `coleam00/local-ai-packaged` (Stable branch) cloned to `$HOME`.
2.  **Detection:** LAN IP and Hostname auto-resolved via socket connection.
3.  **Cryptography:** `HS256` JWTs (Supabase), Salt/Secrets (Langfuse), API Keys (Qdrant) generated.
4.  **Injection:** Connection strings injected into `.env` and `docker-compose.override.private.yml`.

### State 1: Ready to Start

  * **Context:** Fully configured repository.
  * **Artifacts Created:** `.env`, `docker-compose.override.private.yml`, `traefik_{team}.yml`.

## 4\. Configuration Logic (Deep Integration)

The Python Wizard (`setup_ultra_node.py`) enforces the following service inter-dependencies via Environment Variables:

  * **Open WebUI:**
      * `VECTOR_DB` → **Qdrant** (Port 6333)
      * `RAG_EMBEDDING_ENGINE` → **Ollama** (Port 11434, Model: `nomic-embed-text`)
      * `RAG_WEB_SEARCH` → **SearXNG** (Port 8080)
      * `WEBHOOK_URL` → **N8N** (Port 5678)
  * **Flowise:**
      * `DATABASE` → **Supabase Postgres** (Port 5432)
      * `VECTOR_STORE` → **Qdrant** (Shared API Key)
  * **N8N:**
      * `DB_TYPE` → **Supabase Postgres** (Port 5432)
      * `OLLAMA_HOST` → **Ollama** (Internal Docker Network)
  * **Langfuse:**
      * `DATABASE_URL` → **Supabase Postgres** (Port 5432)
      * `CLICKHOUSE_URL` → **Clickhouse** (Port 8123)

## 5\. Network Exposure & Routing

### Internal (Docker Network)

  * Services communicate via internal DNS names (`db`, `ollama`, `qdrant`).

### Host (Private LAN)

All ports are exposed to `HOST_IP` via `docker-compose.override.private.yml` to allow:

1.  Direct Database Access (DBeaver/TablePlus).
2.  Traefik Proxy Reachability.

### External (Traefik Proxy)

**Artifact:** `traefik_{team}.yml`

  * **Logic:** Dynamic File Provider configuration.
  * **Action:** Must be moved to external Traefik container's `dynamic/` folder.
  * **Routing:** Maps `https://{service}.{domain}` → `http://{HOST_IP}:{PORT}`.

## 6\. Execution Instructions

### Installation

Run as `root` in the directory containing the scripts:

```bash
bash chain_setup.sh
```

### Verification & Start

1.  Log in as the service user: `su - ai-admin`
2.  Navigate to repo: `cd local-ai-packaged`
3.  Verify artifacts: `ls -la` (Check for `.env` and `traefik_*.yml`)
4.  Start Stack:
    ```bash
    python3 start_services.py --profile cpu --environment private
    ```

### Post-Deployment Diagnostics

**NEW:** Comprehensive diagnostic script to verify stack health: [diagnose_stack.sh](diagnose_stack.sh)

Run from the repository directory (`~/local-ai-packaged`):

```bash
bash ~/InstallLocalAiPackage/diagnose_stack.sh
```

**What it tests:**
- ✅ Container health status (all 12 services)
- ✅ Port bindings (ensures all services are listening)
- ✅ HTTP endpoint accessibility
- ✅ Database connectivity (Postgres, Clickhouse)
- ✅ Service integrations:
  - Open WebUI → Ollama, Qdrant, SearXNG, n8n
  - Flowise → Ollama, Qdrant, Postgres
  - n8n → Ollama, Postgres
  - Langfuse → Postgres, Clickhouse
- ✅ API functionality (Ollama models, Qdrant collections, etc.)
- ✅ Docker network configuration and DNS resolution
- ✅ Container log error scanning

**Output:** Color-coded PASS/FAIL/WARN with actionable error messages and fix suggestions.

## 7\. Troubleshooting / Heuristics

  * **Looping Restarts:** Service restart policy is set to `on-failure:2`. If a container stops, check logs (`docker logs <container_name>`).
  * **Database Lock:** Services (N8N/Flowise) share the Postgres `db` container. First startup requires migration time.
  * **Ollama Models:** RAG requires embedding models. Post-install action required:
    `docker exec -it ollama ollama pull nomic-embed-text`
