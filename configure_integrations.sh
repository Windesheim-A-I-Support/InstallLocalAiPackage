#!/bin/bash
set -e

echo "========================================================="
echo "   CONFIGURING SERVICE INTEGRATIONS"
echo "========================================================="

# This script patches docker-compose.override.private.yml to add integration environment variables
# Based on verified integrations from official documentation:
# - Open WebUI → Qdrant (vector DB), Ollama (LLM)
# - n8n → Ollama (LLM)
# - Flowise → Qdrant (vector DB), Ollama (LLM)

if [ ! -f "docker-compose.override.private.yml" ]; then
    echo "❌ Error: docker-compose.override.private.yml not found. Please run this in the local-ai-packaged directory."
    exit 1
fi

echo "--> Patching docker-compose.override.private.yml with integration configurations..."

# Backup original file
cp docker-compose.override.private.yml docker-compose.override.private.yml.backup

# Create a temporary Python script to patch the YAML file
cat > /tmp/patch_compose.py << 'PYTHON_SCRIPT'
import sys
import re

# Read the file
with open('docker-compose.override.private.yml', 'r') as f:
    content = f.read()

# Add Open WebUI integrations
if 'open-webui:' in content:
    # Find the open-webui service section
    open_webui_match = re.search(r'(  open-webui:\s*\n(?:    .*\n)*?)(    environment:\s*\n)', content)
    if open_webui_match:
        # Environment section exists, add to it
        env_section = re.search(r'(  open-webui:.*?environment:\s*\n)((?:      - .*\n)*)', content, re.DOTALL)
        if env_section and 'VECTOR_DB' not in content:
            new_env = env_section.group(1) + env_section.group(2)
            new_env += "      - VECTOR_DB=qdrant\n"
            new_env += "      - QDRANT_URI=http://qdrant:6333\n"
            new_env += "      - OLLAMA_BASE_URL=http://ollama:11434\n"
            content = content.replace(env_section.group(0), new_env)
            print("Added Open WebUI integrations")
    else:
        # No environment section, add one
        open_webui_section = re.search(r'(  open-webui:\s*\n(?:    .*\n)*?)(  \w+:|$)', content, re.DOTALL)
        if open_webui_section and 'environment:' not in open_webui_section.group(1):
            insertion = open_webui_section.group(1) + "    environment:\n"
            insertion += "      - VECTOR_DB=qdrant\n"
            insertion += "      - QDRANT_URI=http://qdrant:6333\n"
            insertion += "      - OLLAMA_BASE_URL=http://ollama:11434\n"
            content = content.replace(open_webui_section.group(1), insertion)
            print("Added Open WebUI environment section with integrations")

# Add n8n integrations
if 'n8n:' in content:
    n8n_env = re.search(r'(  n8n:.*?environment:\s*\n)((?:      - .*\n)*)', content, re.DOTALL)
    if n8n_env and 'NODE_FUNCTION_ALLOW_EXTERNAL' not in content:
        new_env = n8n_env.group(1) + n8n_env.group(2)
        new_env += "      - NODE_FUNCTION_ALLOW_EXTERNAL=*\n"
        content = content.replace(n8n_env.group(0), new_env)
        print("Added n8n external function support")

# Add Ollama configuration
if 'ollama-cpu:' in content:
    ollama_env = re.search(r'(  ollama-cpu:.*?)(    restart:)', content, re.DOTALL)
    if ollama_env and 'OLLAMA_HOST' not in content:
        insertion = ollama_env.group(1) + "    environment:\n"
        insertion += "      - OLLAMA_HOST=0.0.0.0:11434\n"
        insertion += "      - OLLAMA_ORIGINS=*\n"
        insertion += "    " + ollama_env.group(2)
        content = content.replace(ollama_env.group(0), insertion)
        print("Added Ollama host configuration")

# Write the updated content
with open('docker-compose.override.private.yml', 'w') as f:
    f.write(content)

print("\n✅ Successfully patched docker-compose.override.private.yml")
PYTHON_SCRIPT

# Run the Python script
python3 /tmp/patch_compose.py

# Clean up
rm /tmp/patch_compose.py

echo ""
echo "========================================================="
echo "✅ INTEGRATION CONFIGURATION COMPLETE"
echo "========================================================="
echo ""
echo "Patched docker-compose.override.private.yml with:"
echo "  ✓ Open WebUI → Qdrant (VECTOR_DB=qdrant, QDRANT_URI=http://qdrant:6333)"
echo "  ✓ Open WebUI → Ollama (OLLAMA_BASE_URL=http://ollama:11434)"
echo "  ✓ n8n external functions (NODE_FUNCTION_ALLOW_EXTERNAL=*)"
echo "  ✓ Ollama host binding (OLLAMA_HOST=0.0.0.0:11434)"
echo ""
echo "Backup saved to: docker-compose.override.private.yml.backup"
echo ""
echo "Configure in application UIs after deployment:"
echo "  • Flowise → Qdrant: Use 'qdrant:6333' in Qdrant node"
echo "  • Flowise → Ollama: Use 'http://ollama:11434' in ChatOllama node"
echo "  • n8n → Ollama: Use 'http://ollama:11434' in Ollama credentials"
echo ""
echo "Ready for deployment with: python3 start_services.py --profile cpu --environment private"
echo "========================================================="
echo ""
echo "📚 SOURCES:"
echo "  • Open WebUI + Qdrant: https://docs.openwebui.com/getting-started/env-configuration/"
echo "  • n8n + Ollama: https://docs.ollama.com/integrations/n8n"
echo "  • Flowise + Qdrant: https://docs.flowiseai.com/integrations/langchain/vector-stores/qdrant"
echo "  • Flowise + Ollama: https://docs.flowiseai.com/integrations/langchain/chat-models/chatollama"
echo "========================================================="
