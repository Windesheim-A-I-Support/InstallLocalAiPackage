# New Services Deployment Plan - Forensics & AI Enhancement

## Available Container IPs
- 10.0.5.108
- 10.0.5.119
- 10.0.5.124
- Plus any that fail (111 Tika timeout, 120 Gitea SSH issue)

## Priority 1: OpenWebUI & RAG Enhancements

### 1. pgvector (10.0.5.102 - Add to existing PostgreSQL)
- **What:** PostgreSQL extension for vector similarity search
- **Why:** Enable RAG directly in PostgreSQL, combine relational + vector data
- **Integration:** Works with Langfuse, n8n workflows
- **Deployment:** Extension install on existing PostgreSQL

### 2. LiteLLM Proxy (10.0.5.108)
- **What:** Unified OpenAI-compatible API gateway
- **Why:** Route between Ollama, OpenAI, Anthropic with single interface
- **Port:** 4000
- **Integration:** OpenWebUI backend, n8n workflows
- **Native:** Python + Redis caching

### 3. Mem0 (10.0.5.119)
- **What:** Persistent memory layer for AI agents
- **Why:** Remember context across sessions, user preferences
- **Port:** 8080
- **Integration:** OpenWebUI, n8n agent workflows
- **Storage:** PostgreSQL or Qdrant backend

## Priority 2: Forensics & Data Analysis

### 4. Jupyter Lab (10.0.5.124)
- **What:** Interactive notebook environment
- **Why:** Data analysis, forensics exploration, Python scripting
- **Port:** 8888
- **Integration:** Connect to all databases, visualization
- **Packages:** pandas, numpy, matplotlib, networkx, neo4j driver

### 5. Elasticsearch (10.0.5.108 if LiteLLM elsewhere)
- **What:** Search and analytics engine
- **Why:** Log aggregation, timeline analysis, full-text search
- **Port:** 9200, 9300
- **Integration:** Loki logs, forensic timelines
- **Storage:** Fast indexing for large datasets

### 6. Apache Superset (10.0.5.119 if Mem0 elsewhere)
- **What:** Data visualization and BI platform
- **Why:** Create dashboards from PostgreSQL, Neo4j
- **Port:** 8088
- **Integration:** All databases, better than Metabase for forensics

## Priority 3: Advanced RAG & Agent Frameworks

### 7. Haystack RAG Pipeline (Container TBD)
- **What:** End-to-end RAG framework
- **Why:** Production RAG pipelines, document QA
- **Integration:** Qdrant, PostgreSQL, Ollama
- **API:** REST API for RAG queries

### 8. GraphRAG (Container TBD)
- **What:** Knowledge graph enhanced RAG
- **Why:** Relationship-aware document analysis
- **Integration:** Neo4j + Ollama + Qdrant
- **Use:** Complex forensic relationship queries

### 9. LangGraph Multi-Agent (Container TBD)
- **What:** Agent orchestration framework
- **Why:** Multi-agent forensic workflows
- **Integration:** n8n triggers, Neo4j memory
- **Agents:** Researcher, Analyst, Reporter

## Priority 4: Specialized Forensics Tools

### 10. Plaso/log2timeline (Container TBD)
- **What:** Timeline generation from logs
- **Why:** Core forensic timeline analysis
- **Output:** PostgreSQL, Elasticsearch
- **Format:** Super timeline format

### 11. Volatility3 (Container TBD)
- **What:** Memory forensics framework
- **Why:** RAM dump analysis
- **Integration:** Store results in PostgreSQL
- **API:** REST wrapper for memory analysis

### 12. Unstructured.io API (Container TBD)
- **What:** Advanced document parsing
- **Why:** Better than Docling for complex docs
- **Integration:** RAG preprocessing
- **Formats:** PDFs, emails, HTML, tables

## Immediate Next Steps

1. **Enable pgvector** on PostgreSQL (102) - No new container needed
2. **Deploy Jupyter Lab** (124) - Immediate analyst value
3. **Deploy LiteLLM** (108) - Unified LLM access
4. **Fix Tika** (111) - Already have script
5. **Continue monitoring:** Whisper, Flowise, Formbricks

## Integration Architecture

```
OpenWebUI
  ├─> LiteLLM Proxy (unified LLM routing)
  ├─> Mem0 (persistent memory)
  ├─> Langfuse (observability)
  └─> n8n (workflow automation)
       ├─> Jupyter Lab (analysis)
       ├─> PostgreSQL+pgvector (vector search)
       ├─> Neo4j (graph relationships)
       ├─> Qdrant (embeddings)
       └─> Elasticsearch (log search)

Forensics Workflow:
  Input → Unstructured.io → Docling → Embedding
    ↓
  PostgreSQL+pgvector ← → Neo4j (relationships)
    ↓
  GraphRAG / Haystack
    ↓
  LangGraph Agents → Jupyter Analysis → Superset Dashboard
```

## Deployment Order

1. ✅ pgvector (PostgreSQL extension - 5 min)
2. ✅ Jupyter Lab (124 - Python, 10 min)
3. ✅ LiteLLM (108 - Python, 10 min)
4. Elasticsearch (119 - Java, 20 min)
5. Mem0 (Available IP - Python, 15 min)
6. Superset (Available IP - Python, 20 min)
7. Haystack (Available IP - Python, 15 min)

Total: 7 new services within 2 hours
