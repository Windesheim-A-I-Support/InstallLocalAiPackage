#!/bin/bash
# ==============================================================================
# AI STACK DIAGNOSTIC & INTEGRATION TEST SUITE
# Tests: Container health, Service connectivity, Database integration, APIs
# ==============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0
WARN=0

# Test result tracking
print_test() {
  echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
  ((PASS++))
}

print_fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  ((FAIL++))
}

print_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
  ((WARN++))
}

print_section() {
  echo ""
  echo "========================================================="
  echo "  $1"
  echo "========================================================="
}

# ==============================================================================
# 1. PREREQUISITES CHECK
# ==============================================================================
check_prerequisites() {
  print_section "1. PREREQUISITES"

  print_test "Checking if Docker is installed..."
  if command -v docker &> /dev/null; then
    print_pass "Docker found: $(docker --version)"
  else
    print_fail "Docker not installed"
    exit 1
  fi

  print_test "Checking if Docker Compose plugin is available..."
  if docker compose version &> /dev/null; then
    print_pass "Docker Compose found: $(docker compose version)"
  else
    print_fail "Docker Compose plugin not installed"
    exit 1
  fi

  print_test "Checking if .env file exists..."
  if [ -f ".env" ]; then
    print_pass ".env file found"
  else
    print_fail ".env file missing - run setup_ultra_node.py first"
    exit 1
  fi

  print_test "Checking if docker-compose.override.private.yml exists..."
  if [ -f "docker-compose.override.private.yml" ]; then
    print_pass "Override file found"
  else
    print_fail "docker-compose.override.private.yml missing"
    exit 1
  fi
}

# ==============================================================================
# 2. CONTAINER HEALTH CHECK
# ==============================================================================
check_container_health() {
  print_section "2. CONTAINER HEALTH"

  # Expected containers
  CONTAINERS=(
    "ollama"
    "open-webui"
    "db"
    "qdrant"
    "n8n"
    "flowise"
    "langfuse-server"
    "searxng"
    "neo4j"
    "clickhouse"
    "kong"
    "minio"
  )

  for container in "${CONTAINERS[@]}"; do
    print_test "Checking container: $container"

    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
      STATUS=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
      HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "none")

      if [ "$STATUS" = "running" ]; then
        if [ "$HEALTH" = "healthy" ] || [ "$HEALTH" = "none" ]; then
          print_pass "$container is running (Health: ${HEALTH})"
        else
          print_warn "$container is running but health is: $HEALTH"
        fi
      else
        print_fail "$container exists but status is: $STATUS"
      fi
    else
      print_fail "$container not found or not running"
    fi
  done
}

# ==============================================================================
# 3. PORT BINDING CHECK
# ==============================================================================
check_port_bindings() {
  print_section "3. PORT BINDINGS"

  PORTS=(
    "8080:open-webui:Open WebUI"
    "11434:ollama:Ollama"
    "5432:db:PostgreSQL"
    "6333:qdrant:Qdrant"
    "5678:n8n:n8n"
    "3001:flowise:Flowise"
    "3300:langfuse-server:Langfuse"
    "8081:searxng:SearXNG"
    "7474:neo4j:Neo4j HTTP"
    "7687:neo4j:Neo4j Bolt"
    "8123:clickhouse:Clickhouse HTTP"
    "8000:kong:Supabase Kong"
    "9011:minio:MinIO Console"
  )

  for port_spec in "${PORTS[@]}"; do
    IFS=':' read -r port container service <<< "$port_spec"
    print_test "Checking if port $port is bound ($service)..."

    if ss -tuln 2>/dev/null | grep -q ":$port "; then
      print_pass "Port $port is listening ($service)"
    elif netstat -tuln 2>/dev/null | grep -q ":$port "; then
      print_pass "Port $port is listening ($service)"
    else
      print_fail "Port $port is NOT listening ($service - container may be down)"
    fi
  done
}

# ==============================================================================
# 4. HTTP ENDPOINT TESTS
# ==============================================================================
check_http_endpoints() {
  print_section "4. HTTP ENDPOINT TESTS"

  # Get host IP from .env
  HOST_IP=$(grep "^HOST_IP=" .env | cut -d'=' -f2)
  if [ -z "$HOST_IP" ]; then
    print_warn "HOST_IP not set in .env, using localhost"
    HOST_IP="localhost"
  fi

  ENDPOINTS=(
    "http://${HOST_IP}:8080:Open WebUI"
    "http://${HOST_IP}:11434:Ollama API"
    "http://${HOST_IP}:6333:Qdrant API"
    "http://${HOST_IP}:5678:n8n"
    "http://${HOST_IP}:3001:Flowise"
    "http://${HOST_IP}:3300:Langfuse"
    "http://${HOST_IP}:8081:SearXNG"
    "http://${HOST_IP}:7474:Neo4j Browser"
    "http://${HOST_IP}:8123/ping:Clickhouse"
  )

  for endpoint_spec in "${ENDPOINTS[@]}"; do
    IFS=':' read -r proto host port_path service <<< "$endpoint_spec"
    url="${proto}:${host}:${port_path}"

    print_test "Testing HTTP endpoint: $service ($url)"

    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "$url" 2>/dev/null || echo "000")

    if [ "$response" = "200" ] || [ "$response" = "302" ] || [ "$response" = "401" ]; then
      print_pass "$service responded with HTTP $response"
    elif [ "$response" = "000" ]; then
      print_fail "$service unreachable (connection refused or timeout)"
    else
      print_warn "$service responded with HTTP $response (may be normal)"
    fi
  done
}

# ==============================================================================
# 5. DATABASE CONNECTIVITY
# ==============================================================================
check_database_connectivity() {
  print_section "5. DATABASE CONNECTIVITY"

  print_test "Testing PostgreSQL connection from n8n..."
  if docker exec n8n nc -zv db 5432 2>&1 | grep -q "succeeded"; then
    print_pass "n8n can reach PostgreSQL on db:5432"
  else
    print_fail "n8n cannot reach PostgreSQL"
  fi

  print_test "Testing PostgreSQL connection from flowise..."
  if docker exec flowise nc -zv db 5432 2>&1 | grep -q "succeeded"; then
    print_pass "Flowise can reach PostgreSQL on db:5432"
  else
    print_fail "Flowise cannot reach PostgreSQL"
  fi

  print_test "Testing PostgreSQL connection from langfuse-server..."
  if docker exec langfuse-server nc -zv db 5432 2>&1 | grep -q "succeeded"; then
    print_pass "Langfuse can reach PostgreSQL on db:5432"
  else
    print_fail "Langfuse cannot reach PostgreSQL"
  fi

  print_test "Testing Clickhouse connection from langfuse-server..."
  if docker exec langfuse-server nc -zv clickhouse 8123 2>&1 | grep -q "succeeded"; then
    print_pass "Langfuse can reach Clickhouse on clickhouse:8123"
  else
    print_fail "Langfuse cannot reach Clickhouse"
  fi
}

# ==============================================================================
# 6. SERVICE INTEGRATION TESTS
# ==============================================================================
check_service_integrations() {
  print_section "6. SERVICE INTEGRATION TESTS"

  # Test Open WebUI -> Ollama
  print_test "Testing Open WebUI -> Ollama integration..."
  if docker exec open-webui nc -zv ollama 11434 2>&1 | grep -q "succeeded"; then
    print_pass "Open WebUI can reach Ollama"
  else
    print_fail "Open WebUI cannot reach Ollama"
  fi

  # Test Open WebUI -> Qdrant
  print_test "Testing Open WebUI -> Qdrant integration..."
  if docker exec open-webui nc -zv qdrant 6333 2>&1 | grep -q "succeeded"; then
    print_pass "Open WebUI can reach Qdrant"
  else
    print_fail "Open WebUI cannot reach Qdrant"
  fi

  # Test Open WebUI -> SearXNG
  print_test "Testing Open WebUI -> SearXNG integration..."
  if docker exec open-webui nc -zv searxng 8080 2>&1 | grep -q "succeeded"; then
    print_pass "Open WebUI can reach SearXNG"
  else
    print_fail "Open WebUI cannot reach SearXNG"
  fi

  # Test Open WebUI -> n8n
  print_test "Testing Open WebUI -> n8n webhook integration..."
  if docker exec open-webui nc -zv n8n 5678 2>&1 | grep -q "succeeded"; then
    print_pass "Open WebUI can reach n8n"
  else
    print_fail "Open WebUI cannot reach n8n"
  fi

  # Test Flowise -> Ollama
  print_test "Testing Flowise -> Ollama integration..."
  if docker exec flowise nc -zv ollama 11434 2>&1 | grep -q "succeeded"; then
    print_pass "Flowise can reach Ollama"
  else
    print_fail "Flowise cannot reach Ollama"
  fi

  # Test Flowise -> Qdrant
  print_test "Testing Flowise -> Qdrant integration..."
  if docker exec flowise nc -zv qdrant 6333 2>&1 | grep -q "succeeded"; then
    print_pass "Flowise can reach Qdrant"
  else
    print_fail "Flowise cannot reach Qdrant"
  fi

  # Test n8n -> Ollama
  print_test "Testing n8n -> Ollama integration..."
  if docker exec n8n nc -zv ollama 11434 2>&1 | grep -q "succeeded"; then
    print_pass "n8n can reach Ollama"
  else
    print_fail "n8n cannot reach Ollama"
  fi
}

# ==============================================================================
# 7. API FUNCTIONALITY TESTS
# ==============================================================================
check_api_functionality() {
  print_section "7. API FUNCTIONALITY TESTS"

  HOST_IP=$(grep "^HOST_IP=" .env | cut -d'=' -f2)
  if [ -z "$HOST_IP" ]; then
    HOST_IP="localhost"
  fi

  # Test Ollama API
  print_test "Testing Ollama API (list models)..."
  response=$(curl -s "http://${HOST_IP}:11434/api/tags" 2>/dev/null || echo "{}")
  if echo "$response" | grep -q "models"; then
    print_pass "Ollama API is functional"
    model_count=$(echo "$response" | grep -o '"name"' | wc -l)
    echo "   Found $model_count model(s) installed"
  else
    print_fail "Ollama API not responding correctly"
  fi

  # Test Qdrant API
  print_test "Testing Qdrant API..."
  QDRANT_KEY=$(grep "^QDRANT_API_KEY=" .env | cut -d'=' -f2)
  response=$(curl -s -H "api-key: ${QDRANT_KEY}" "http://${HOST_IP}:6333/collections" 2>/dev/null || echo "{}")
  if echo "$response" | grep -q "result\|collections"; then
    print_pass "Qdrant API is functional"
  else
    print_fail "Qdrant API not responding correctly (check API key)"
  fi

  # Test PostgreSQL
  print_test "Testing PostgreSQL availability..."
  PG_PASS=$(grep "^POSTGRES_PASSWORD=" .env | cut -d'=' -f2)
  if docker exec db psql -U postgres -c "SELECT 1;" &>/dev/null; then
    print_pass "PostgreSQL is accepting connections"

    # Check database count
    db_count=$(docker exec db psql -U postgres -t -c "SELECT count(*) FROM pg_database WHERE datistemplate = false;" | tr -d ' ')
    echo "   Active databases: $db_count"
  else
    print_fail "PostgreSQL not accepting connections"
  fi

  # Test Clickhouse
  print_test "Testing Clickhouse availability..."
  response=$(curl -s "http://${HOST_IP}:8123/ping" 2>/dev/null || echo "")
  if [ "$response" = "Ok." ]; then
    print_pass "Clickhouse is responding"
  else
    print_fail "Clickhouse not responding to ping"
  fi
}

# ==============================================================================
# 8. DOCKER NETWORK TESTS
# ==============================================================================
check_docker_networks() {
  print_section "8. DOCKER NETWORK TESTS"

  print_test "Checking Docker network configuration..."
  network=$(docker inspect open-webui --format='{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' 2>/dev/null || echo "")

  if [ -n "$network" ]; then
    print_pass "Containers are on network: $network"

    # List all containers on the same network
    print_test "Verifying all containers are on the same network..."
    containers_on_network=$(docker network inspect "$network" --format='{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")

    if echo "$containers_on_network" | grep -q "ollama"; then
      print_pass "All containers appear to be on the same network"
    else
      print_warn "Some containers may be on different networks"
    fi
  else
    print_fail "Could not determine Docker network"
  fi

  print_test "Testing DNS resolution between containers..."
  if docker exec open-webui nslookup ollama &>/dev/null || docker exec open-webui getent hosts ollama &>/dev/null; then
    print_pass "DNS resolution working (open-webui -> ollama)"
  else
    print_fail "DNS resolution not working between containers"
  fi
}

# ==============================================================================
# 9. LOG ERROR DETECTION
# ==============================================================================
check_container_logs() {
  print_section "9. CONTAINER LOG ERROR SCAN"

  CONTAINERS=(
    "ollama"
    "open-webui"
    "db"
    "qdrant"
    "n8n"
    "flowise"
    "langfuse-server"
  )

  for container in "${CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
      print_test "Scanning $container logs for errors..."

      errors=$(docker logs "$container" 2>&1 | tail -n 100 | grep -iE "error|fatal|exception|failed|panic" | grep -viE "error_rate|error_log|errorlog" | wc -l)

      if [ "$errors" -eq 0 ]; then
        print_pass "$container: No recent errors detected"
      elif [ "$errors" -lt 5 ]; then
        print_warn "$container: $errors potential error(s) found in recent logs"
      else
        print_fail "$container: $errors errors found - check logs with: docker logs $container"
      fi
    fi
  done
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

echo ""
echo "============================================================"
echo "  AI STACK DIAGNOSTIC & INTEGRATION TEST SUITE"
echo "============================================================"
echo ""

# Change to repository directory if needed
if [ -f "start_services.py" ]; then
  echo "Running from: $(pwd)"
else
  if [ -d "$HOME/local-ai-packaged" ]; then
    cd "$HOME/local-ai-packaged"
    echo "Changed to: $(pwd)"
  else
    echo "ERROR: Cannot find local-ai-packaged directory"
    exit 1
  fi
fi

# Run all checks
check_prerequisites
check_container_health
check_port_bindings
check_http_endpoints
check_database_connectivity
check_service_integrations
check_api_functionality
check_docker_networks
check_container_logs

# ==============================================================================
# SUMMARY
# ==============================================================================
print_section "TEST SUMMARY"

TOTAL=$((PASS + FAIL + WARN))

echo -e "${GREEN}Passed:${NC}  $PASS / $TOTAL"
echo -e "${RED}Failed:${NC}  $FAIL / $TOTAL"
echo -e "${YELLOW}Warnings:${NC} $WARN / $TOTAL"

echo ""
if [ $FAIL -eq 0 ] && [ $WARN -eq 0 ]; then
  echo -e "${GREEN}✅ ALL TESTS PASSED - Stack is healthy!${NC}"
  exit 0
elif [ $FAIL -eq 0 ]; then
  echo -e "${YELLOW}⚠️  All critical tests passed, but there are warnings${NC}"
  exit 0
else
  echo -e "${RED}❌ CRITICAL FAILURES DETECTED - Stack needs attention${NC}"
  echo ""
  echo "Common fixes:"
  echo "  - Restart failed containers: docker restart <container>"
  echo "  - Check logs: docker logs <container>"
  echo "  - Verify .env configuration"
  echo "  - Ensure all required models are pulled: docker exec ollama ollama pull nomic-embed-text"
  exit 1
fi
