import secrets
import base64
import hmac
import hashlib
import json
import time
import os
import sys

# -----------------------------------------------------------------------------
# CRYPTOGRAPHY & SECURITY
# -----------------------------------------------------------------------------
def generate_secret(length=32):
    return secrets.token_urlsafe(length)

def generate_hex(length=16):
    return secrets.token_hex(length)

def generate_jwt(secret, role):
    """Generates a Supabase-compatible HS256 JWT."""
    header = {"typ": "JWT", "alg": "HS256"}
    payload = {
        "role": role,
        "iss": "supabase",
        "iat": int(time.time()),
        "exp": int(time.time()) + 315360000 # 10 years
    }
    h = base64.urlsafe_b64encode(json.dumps(header).encode()).decode().rstrip('=')
    p = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip('=')
    sig_input = f"{h}.{p}"
    sig = hmac.new(secret.encode(), sig_input.encode(), hashlib.sha256).digest()
    s = base64.urlsafe_b64encode(sig).decode().rstrip('=')
    return f"{h}.{p}.{s}"

# -----------------------------------------------------------------------------
# MAIN CONFIGURATION WIZARD
# -----------------------------------------------------------------------------
def main():
    print("\n=========================================================")
    print("   ULTRA-NODE SETUP: DEEP OPENWEBUI INTEGRATION")
    print("   (With 'On-Failure:2' Restart Limits)")
    print("=========================================================\n")

    # 1. IDENTIFY THE NODE
    team_name = input("1. Team Name (lowercase, no spaces): ").strip().lower()
    domain_root = input("2. Root Domain (e.g., company.com): ").strip()
    host_ip = input("3. Local IP of THIS container: ").strip()

    print(f"\nConfiguring 'God Mode' for {team_name}...")

    # 2. GENERATE ALL SECRETS
    # Supabase / Postgres
    jwt_secret = generate_secret(40)
    pg_pass = generate_secret(24)
    dash_pass = generate_secret(24)
    
    # Vector & Graph
    qdrant_key = generate_secret(32)
    neo4j_pass = generate_secret(24)
    
    # Langfuse (Observability)
    lf_salt = generate_secret()
    lf_secret = generate_secret()
    ch_pass = generate_secret(24) # Clickhouse
    minio_pass = generate_secret(24)
    
    # N8N & Flowise
    n8n_enc = generate_secret()
    n8n_jwt = generate_secret()
    flowise_pass = generate_secret(20)

    # 3. DEFINE EXTERNAL HOSTNAMES
    h_web = f"{team_name}-chat.{domain_root}"
    h_n8n = f"{team_name}-n8n.{domain_root}"
    h_flo = f"{team_name}-flowise.{domain_root}"
    h_sup = f"{team_name}-supabase.{domain_root}"
    h_obs = f"{team_name}-langfuse.{domain_root}"
    h_srx = f"{team_name}-search.{domain_root}"
    h_neo = f"{team_name}-neo4j.{domain_root}"
    h_min = f"{team_name}-minio.{domain_root}"

    # 4. PREPARE .ENV FILE (COMPREHENSIVE)
    env_content = f"""# GENERATED ULTRA-NODE CONFIG FOR: {team_name}
# ------------------------------------------------------------------

# === NETWORK & IDENTITY ===
HOST_IP={host_ip}
DOMAIN_ROOT={domain_root}

# === SERVICE HOSTNAMES ===
WEBUI_HOSTNAME={h_web}
N8N_HOSTNAME={h_n8n}
FLOWISE_HOSTNAME={h_flo}
SUPABASE_HOSTNAME={h_sup}
LANGFUSE_HOSTNAME={h_obs}
SEARXNG_HOSTNAME={h_srx}
NEO4J_HOSTNAME={h_neo}
OLLAMA_HOSTNAME={team_name}-ollama.{domain_root}

# === OPEN WEBUI (The Brain) ===
ENABLE_SIGNUP=True
DEFAULT_MODELS=llama3,mistral

# === SUPABASE (The Backbone) ===
POSTGRES_PASSWORD={pg_pass}
JWT_SECRET={jwt_secret}
ANON_KEY={generate_jwt(jwt_secret, 'anon')}
SERVICE_ROLE_KEY={generate_jwt(jwt_secret, 'service_role')}
DASHBOARD_USERNAME=admin
DASHBOARD_PASSWORD={dash_pass}
POOLER_TENANT_ID={generate_hex(16)}
POOLER_DB_POOL_SIZE=10
API_EXTERNAL_URL=https://{h_sup}
SUPABASE_PUBLIC_URL=https://{h_sup}
STUDIO_DEFAULT_ORGANIZATION={team_name.capitalize()} Org
STUDIO_DEFAULT_PROJECT={team_name.capitalize()} Project

# === QDRANT (Vector Memory) ===
QDRANT_API_KEY={qdrant_key}

# === NEO4J (Graph Memory) ===
NEO4J_AUTH=neo4j/{neo4j_pass}
NEO4J_dbms_memory_heap_initial__size=512m
NEO4J_dbms_memory_heap_max__size=1G

# === LANGFUSE (Observability) ===
CLICKHOUSE_PASSWORD={ch_pass}
MINIO_ROOT_PASSWORD={minio_pass}
LANGFUSE_SALT={lf_salt}
NEXTAUTH_SECRET={lf_secret}
ENCRYPTION_KEY={generate_secret()}
LANGFUSE_INIT_ORG_ID={team_name}-org
LANGFUSE_INIT_PROJECT_ID={team_name}-project
NEXTAUTH_URL=https://{h_obs}
DATABASE_URL=postgresql://postgres:{pg_pass}@db:5432/postgres
CLICKHOUSE_URL=http://clickhouse:8123
CLICKHOUSE_USER=default

# === N8N (Automation) ===
N8N_ENCRYPTION_KEY={n8n_enc}
N8N_USER_MANAGEMENT_JWT_SECRET={n8n_jwt}
DB_TYPE=postgresdb
DB_POSTGRESDB_DATABASE=postgres
DB_POSTGRESDB_HOST=db
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_USER=postgres
DB_POSTGRESDB_PASSWORD={pg_pass}

# === FLOWISE (Agents) ===
FLOWISE_USERNAME=admin
FLOWISE_PASSWORD={flowise_pass}
FLOWISE_DATABASE_TYPE=postgres
FLOWISE_DATABASE_HOST=db
FLOWISE_DATABASE_PORT=5432
FLOWISE_DATABASE_USER=postgres
FLOWISE_DATABASE_PASSWORD={pg_pass}
FLOWISE_DATABASE_NAME=postgres

# === OLLAMA ===
OLLAMA_ORIGINS="*"
"""

    with open(".env", "w") as f:
        f.write(env_content)
    print("-> .env file created (All Values Filled).")

    # 5. PREPARE DOCKER OVERRIDE (DEEP INTEGRATION + RESTART LIMITS)
    
    docker_override = f"""version: "3.8"

services:
  # === OPEN WEBUI ===
  open-webui:
    ports: ["8080:8080"]
    restart: on-failure:2
    environment:
      - PORT=8080
      - VECTOR_DB=qdrant
      - QDRANT_HTTP_HOST=qdrant
      - QDRANT_API_KEY={qdrant_key}
      - RAG_EMBEDDING_ENGINE=ollama
      - RAG_EMBEDDING_MODEL=nomic-embed-text:latest
      - RAG_OPENAI_API_BASE_URL=http://ollama:11434/v1
      - OLLAMA_BASE_URL=http://ollama:11434
      - ENABLE_RAG_WEB_SEARCH=True
      - RAG_WEB_SEARCH_ENGINE=searxng
      - SEARXNG_QUERY_URL=http://searxng:8080/search?q=<query>
      - ENABLE_STT=True
      - STT_ENGINE=openai
      - STT_OPENAI_API_BASE_URL=http://ollama:11434/v1
      - ENABLE_TTS=True
      - ENABLE_IMAGE_GENERATION=True
      - WEBHOOK_URL=http://n8n:5678/webhook/

  # === DATABASES ===
  db:
    ports: ["5432:5432"]
    restart: on-failure:2
  
  qdrant:
    ports: ["6333:6333"]
    restart: on-failure:2
    environment:
      - QDRANT__SERVICE__API_KEY={qdrant_key}

  neo4j:
    ports: ["7474:7474", "7687:7687"]
    restart: on-failure:2

  clickhouse:
    ports: ["8123:8123", "9000:9000"]
    restart: on-failure:2

  # === APPLICATIONS ===
  flowise:
    ports: ["3001:3000"]
    restart: on-failure:2
    environment:
      - PORT=3000
      - OLLAMA_SERVER_URL=http://ollama:11434
      - QDRANT_API_KEY={qdrant_key}

  n8n:
    ports: ["5678:5678"]
    restart: on-failure:2
    environment:
      - N8N_HOST={h_n8n}
      - WEBHOOK_URL=https://{h_n8n}/
      - OLLAMA_HOST=http://ollama:11434

  langfuse-server:
    ports: ["3300:3000"]
    restart: on-failure:2
    environment:
      - PORT=3000
      - DATABASE_URL=postgresql://postgres:{pg_pass}@db:5432/postgres

  searxng:
    ports: ["8081:8080"]
    restart: on-failure:2

  kong:
    ports: ["8000:8000"]
    restart: on-failure:2

  minio:
    ports: ["9011:9001", "9090:9000"]
    restart: on-failure:2

  ollama:
    ports: ["11434:11434"]
    restart: on-failure:2
"""

    with open("docker-compose.override.private.yml", "w") as f:
        f.write(docker_override)
    print("-> docker-compose.override.private.yml created (With Restart Limits).")

    # 6. TRAEFIK CONFIG
    traefik_yaml = f"""http:
  routers:
    {team_name}-webui:
      rule: "Host(`{h_web}`)"
      service: {team_name}-webui
      tls:
        certResolver: myresolver
    {team_name}-n8n:
      rule: "Host(`{h_n8n}`)"
      service: {team_name}-n8n
      tls:
        certResolver: myresolver
    {team_name}-flowise:
      rule: "Host(`{h_flo}`)"
      service: {team_name}-flowise
      tls:
        certResolver: myresolver
    {team_name}-supabase:
      rule: "Host(`{h_sup}`)"
      service: {team_name}-supabase
      tls:
        certResolver: myresolver
    {team_name}-langfuse:
      rule: "Host(`{h_obs}`)"
      service: {team_name}-langfuse
      tls:
        certResolver: myresolver
    {team_name}-search:
      rule: "Host(`{h_srx}`)"
      service: {team_name}-search
      tls:
        certResolver: myresolver
    {team_name}-neo4j:
      rule: "Host(`{h_neo}`)"
      service: {team_name}-neo4j
      tls:
        certResolver: myresolver
    {team_name}-minio:
      rule: "Host(`{h_min}`)"
      service: {team_name}-minio
      tls:
        certResolver: myresolver

  services:
    {team_name}-webui:
      loadBalancer:
        servers:
          - url: "http://{host_ip}:8080"
    {team_name}-n8n:
      loadBalancer:
        servers:
          - url: "http://{host_ip}:5678"
    {team_name}-flowise:
      loadBalancer:
        servers:
          - url: "http://{host_ip}:3001"
    {team_name}-supabase:
      loadBalancer:
        servers:
          - url: "http://{host_ip}:8000"
    {team_name}-langfuse:
      loadBalancer:
        servers:
          - url: "http://{host_ip}:3300"
    {team_name}-search:
      loadBalancer:
        servers:
          - url: "http://{host_ip}:8081"
    {team_name}-neo4j:
      loadBalancer:
        servers:
          - url: "http://{host_ip}:7474"
    {team_name}-minio:
      loadBalancer:
        servers:
          - url: "http://{host_ip}:9011"
"""
    
    with open(f"traefik_{team_name}.yml", "w") as f:
        f.write(traefik_yaml)

    print("\n=========================================================")
    print("   ULTRA-NODE DEPLOYMENT READY")
    print("=========================================================")
    print("1. All Database Ports are OPEN on this Host IP.")
    print("2. All Services set to 'restart: on-failure:2' (No infinite loops).")
    print("3. Deep Integration Enabled (WebUI -> Qdrant/Ollama/SearXNG).")
    print("=========================================================")
    print("Run: python start_services.py --profile cpu --environment private")

if __name__ == "__main__":
    main()
