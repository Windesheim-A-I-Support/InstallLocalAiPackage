# n8n Configuration & Integration Guide

**Complete guide for connecting n8n to all infrastructure services**

---

## Table of Contents

1. [PostgreSQL Integration](#postgresql-integration)
2. [MinIO S3 Integration](#minio-s3-integration)
3. [Ollama LLM Integration](#ollama-llm-integration)
4. [Qdrant Vector Database Integration](#qdrant-vector-database-integration)
5. [SearXNG Search Integration](#searxng-search-integration)
6. [Nextcloud WebDAV Integration](#nextcloud-webdav-integration)
7. [Redis Integration](#redis-integration)
8. [Tika Document Extraction](#tika-document-extraction)
9. [Gitea Integration](#gitea-integration)
10. [Matrix Chat Integration](#matrix-chat-integration)
11. [Complete Workflow Examples](#complete-workflow-examples)

---

## PostgreSQL Integration

### Credential Configuration

**Node**: PostgreSQL
**Credential Type**: Postgres account

| Field | Value | Notes |
|-------|-------|-------|
| **Host** | `10.0.5.102` | Shared PostgreSQL server |
| **Database** | `n8n_user1` | Per-user database (e.g., `n8n_user1`, `n8n_user2`) |
| **User** | `dbadmin` | PostgreSQL superuser |
| **Password** | `${POSTGRES_PASSWORD}` | From central secrets |
| **Port** | `5432` | Default PostgreSQL port |
| **SSL** | `Allow` | First try non-SSL, then SSL |

### ENV Variable

```bash
POSTGRES_PASSWORD=<generated-once>
```

### Example n8n PostgreSQL Node Operations

**Common operations**:
- `Execute Query` - Run custom SQL
- `Insert` - Add rows to table
- `Update` - Modify existing rows
- `Delete` - Remove rows
- `Select` - Query data

**Example Query**:
```sql
SELECT * FROM workflows WHERE status = 'active' LIMIT 10;
```

### Use Cases

1. **Workflow Data Storage** - Store workflow results in PostgreSQL
2. **ETL Operations** - Extract, transform, load data between systems
3. **Reporting** - Query database for analytics
4. **Data Sync** - Keep databases in sync across services

### Sources

- [Postgres credentials | n8n Docs](https://docs.n8n.io/integrations/builtin/credentials/postgres/)
- [Postgres node documentation | n8n Docs](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.postgres/)

---

## MinIO S3 Integration

### Credential Configuration

**Node**: S3 (NOT AWS S3 - use generic S3 node for MinIO)
**Credential Type**: S3 account

| Field | Value | Notes |
|-------|-------|-------|
| **S3 Endpoint** | `http://10.0.5.104:9000` | MinIO API endpoint (port 9000, not 9001) |
| **Region** | `us-east-1` | Default region for MinIO |
| **Access Key ID** | `minioadmin` or per-user key | S3 access key |
| **Secret Access Key** | `${MINIO_ROOT_PASSWORD}` | From central secrets |
| **Force Path Style** | `true` | REQUIRED for MinIO |
| **Ignore SSL Issues** | `false` | Set to `true` if using self-signed certs |

### ENV Variables

```bash
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=<generated-once>

# Per-user credentials (recommended)
S3_ACCESS_KEY_USER1=<generated>
S3_SECRET_KEY_USER1=<generated>
```

### Example S3 Operations

**Common operations**:
- `Upload` - Upload files to bucket
- `Download` - Download files from bucket
- `List` - List objects in bucket
- `Delete` - Delete objects
- `Create Bucket` - Create new bucket

**Example Configuration**:
```
Bucket Name: user1-n8n-workflows
Operation: Upload
File Path: /tmp/workflow_backup.json
```

### Use Cases

1. **Workflow Backups** - Auto-backup n8n workflows to S3
2. **File Processing** - Process files uploaded to MinIO
3. **Data Lake** - Store processed data in S3 buckets
4. **Artifact Storage** - Save workflow artifacts

### Important Notes

- **Use S3 node**, not AWS S3 node (AWS node causes "incorrect service" error with MinIO)
- **Force Path Style must be enabled** for MinIO compatibility
- **Use port 9000** for API (9001 is web console)

### Sources

- [S3 credentials | n8n Docs](https://docs.n8n.io/integrations/builtin/credentials/s3/)
- [Custom S3 API Call (Minio) - n8n Community](https://community.n8n.io/t/custom-s3-api-call-minio/45849)

---

## Ollama LLM Integration

### Credential Configuration

**Node**: Ollama Model / Ollama Chat Model
**Credential Type**: Ollama API

| Field | Value | Notes |
|-------|-------|-------|
| **Base URL** | `http://10.0.5.100:11434` | Shared Ollama server |
| **API Key** | (optional) | Leave empty if no auth configured |

### Alternative: HTTP Request Node

You can also use HTTP Request node for more control:

**Configuration**:
```
Method: POST
URL: http://10.0.5.100:11434/api/generate
Content-Type: application/json

Body:
{
  "model": "llama3.2:3b",
  "prompt": "{{ $json.prompt }}",
  "stream": false
}
```

### Available Ollama Models

Check available models on Ollama server:
```bash
curl http://10.0.5.100:11434/api/tags
```

### Example Ollama Operations

**Using Ollama Chat Model Node**:
1. Add "Ollama Chat Model" node
2. Configure credentials with base URL
3. Set model (e.g., `llama3.2:3b`, `mistral:7b`)
4. Connect to AI Agent or use in chain

**Using HTTP Request**:
```json
{
  "model": "llama3.2:3b",
  "prompt": "Summarize this text: {{$json.text}}",
  "stream": false,
  "options": {
    "temperature": 0.7,
    "top_p": 0.9
  }
}
```

### Use Cases

1. **Text Summarization** - Summarize documents, emails, articles
2. **Content Generation** - Generate content based on templates
3. **Data Extraction** - Extract structured data from unstructured text
4. **Question Answering** - Answer questions about documents
5. **Translation** - Translate text between languages
6. **Sentiment Analysis** - Analyze sentiment of text

### Docker Networking Note

If n8n is in Docker and Ollama is on host:
- Use `http://10.0.5.100:11434` (the assigned IP)
- Do NOT use `localhost` or `127.0.0.1` from inside container

### Sources

- [How do you integrate n8n with Ollama for local LLM workflows?](https://www.hostinger.com/tutorials/n8n-ollama-integration)
- [Ollama Model node documentation | n8n Docs](https://docs.n8n.io/integrations/builtin/cluster-nodes/sub-nodes/n8n-nodes-langchain.lmollama/)
- [Chat with local LLMs using n8n and Ollama | n8n workflow](https://n8n.io/workflows/2384-chat-with-local-llms-using-n8n-and-ollama/)

---

## Qdrant Vector Database Integration

### Credential Configuration

**Node**: Qdrant Vector Store
**Credential Type**: Qdrant API

| Field | Value | Notes |
|-------|-------|-------|
| **URL** | `http://10.0.5.101:6333` | Qdrant HTTP endpoint |
| **API Key** | (optional) | Leave empty if no auth configured |

### Qdrant Node Modes

1. **Get Many** - Retrieve multiple documents
2. **Insert Documents** - Add documents to collection
3. **Retrieve Documents (As Vector Store)** - For Chain/Tool
4. **Retrieve Documents (As Tool)** - For AI Agent

### Example Configuration for Document Insertion

```
Mode: Insert Documents
Collection Name: user1_n8n_knowledge
Embeddings: Use Ollama Embeddings node
  - Model: nomic-embed-text
  - Base URL: http://10.0.5.100:11434
```

### Example Configuration for Retrieval

```
Mode: Retrieve Documents
Collection Name: user1_n8n_knowledge
Prompt: {{ $json.query }}
Top K: 5
```

### Workflow Pattern: RAG (Retrieval Augmented Generation)

```
1. Qdrant Vector Store (Retrieve Documents)
   ↓
2. Ollama Chat Model (Answer with context)
   ↓
3. Return Result
```

### Use Cases

1. **Semantic Search** - Search documents by meaning, not keywords
2. **RAG Systems** - Retrieve relevant context for LLM
3. **Knowledge Base** - Build searchable knowledge base
4. **Document Q&A** - Answer questions about stored documents
5. **Similar Document Finding** - Find similar documents

### Collection Naming Convention

Per-user collections to maintain isolation:
- `user1_n8n_knowledge`
- `user1_workflows`
- `team_shared_docs`

### Sources

- [Qdrant Vector Store node documentation | n8n Docs](https://docs.n8n.io/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.vectorstoreqdrant/)
- [Automating Processes with Qdrant and n8n - Qdrant](https://qdrant.tech/documentation/qdrant-n8n/)

---

## SearXNG Search Integration

### Configuration via HTTP Request Node

**Node**: HTTP Request
**Method**: GET

| Field | Value | Notes |
|-------|-------|-------|
| **URL** | `http://10.0.5.105:8080/search` | SearXNG endpoint |
| **Query Parameters** | `q`: search query, `format`: json | |

### Example HTTP Request Configuration

```
Method: GET
URL: http://10.0.5.105:8080/search
Query Parameters:
  - q: {{ $json.searchQuery }}
  - format: json
  - categories: general
  - language: en
```

### Response Format

```json
{
  "results": [
    {
      "title": "Result title",
      "url": "https://example.com",
      "content": "Result snippet...",
      "engine": "google"
    }
  ]
}
```

### Use Cases

1. **Web Research** - Automated web searches
2. **Fact Checking** - Verify information from web
3. **Content Discovery** - Find relevant content
4. **Competitive Analysis** - Monitor competitors
5. **News Monitoring** - Track news on topics

### Example Workflow

```
1. Webhook/Schedule Trigger
   ↓
2. HTTP Request to SearXNG
   ↓
3. Process results (extract URLs, titles)
   ↓
4. Store in PostgreSQL or send notification
```

---

## Nextcloud WebDAV Integration

### Credential Configuration

**Node**: WebDAV
**Credential Type**: WebDAV account

| Field | Value | Notes |
|-------|-------|-------|
| **URL** | `https://nextcloud.valuechainhackers.xyz/remote.php/dav/files/USERNAME/` | Per-user WebDAV URL |
| **User** | Nextcloud username | |
| **Password** | Nextcloud password | |

### Example WebDAV Operations

**Common operations**:
- `Upload` - Upload files to Nextcloud
- `Download` - Download files from Nextcloud
- `List` - List directory contents
- `Delete` - Delete files
- `Move` - Move/rename files
- `Copy` - Copy files

### Use Cases

1. **File Sync** - Sync files between services and Nextcloud
2. **Document Processing** - Process files uploaded to Nextcloud
3. **Backup** - Backup workflow outputs to Nextcloud
4. **Collaboration** - Share files with team via Nextcloud

### Example Workflow: Process Uploaded Documents

```
1. Nextcloud WebDAV (List files in /uploads/)
   ↓
2. For each file:
   - Download file
   - Send to Tika for text extraction
   - Embed text via Ollama
   - Store in Qdrant
   - Move file to /processed/ folder
```

---

## Redis Integration

### Credential Configuration

**Node**: Redis
**Credential Type**: Redis account

| Field | Value | Notes |
|-------|-------|-------|
| **Host** | `10.0.5.103` | Shared Redis server |
| **Port** | `6379` | Default Redis port |
| **Password** | `${REDIS_PASSWORD}` | From central secrets |
| **Database** | `4` (or assigned DB number) | Per-user/service DB number |

### ENV Variable

```bash
REDIS_PASSWORD=<generated-once>
```

### Database Allocation

- DB 0: General cache
- DB 1: Authentik
- DB 2: Open WebUI user1
- DB 3: Open WebUI user2
- DB 4: n8n user1 (workflows, cache)
- DB 5: n8n user2

### Example Redis Operations

**Common operations**:
- `Get` - Retrieve value by key
- `Set` - Set key-value pair
- `Delete` - Delete key
- `Increment/Decrement` - Atomic counter operations
- `Push/Pop` - List operations
- `Publish` - Pub/sub messaging

### Use Cases

1. **Caching** - Cache API responses, computed results
2. **Rate Limiting** - Track API call counts
3. **Session Storage** - Store temporary workflow state
4. **Queue Management** - Implement job queues
5. **Real-time Counters** - Track events in real-time

---

## Tika Document Extraction

### Configuration via HTTP Request Node

**Node**: HTTP Request
**Method**: PUT

| Field | Value | Notes |
|-------|-------|-------|
| **URL** | `http://10.0.5.111:9998/tika` | Tika text extraction endpoint |
| **Method** | `PUT` | |
| **Body** | Binary file data | |
| **Headers** | `Accept: text/plain` | For plain text output |

### Example Configuration

```
Method: PUT
URL: http://10.0.5.111:9998/tika
Headers:
  - Accept: text/plain
Body Content Type: Raw/Binary
Body: {{ $binary.data }}
```

### Supported File Types

Tika supports 1000+ file formats including:
- PDF, Word, Excel, PowerPoint
- Images (OCR with Tesseract)
- HTML, XML, JSON
- Archives (ZIP, TAR)
- Email formats (MSG, EML)
- And many more...

### Use Cases

1. **Document Indexing** - Extract text for search indexing
2. **PDF Processing** - Extract text from PDFs
3. **OCR** - Extract text from images
4. **Email Parsing** - Parse email attachments
5. **Content Analysis** - Analyze document content with LLM

### Example Workflow: PDF to Vector DB

```
1. Nextcloud WebDAV (Download PDF)
   ↓
2. HTTP Request to Tika (Extract text)
   ↓
3. Split text into chunks
   ↓
4. Ollama Embeddings (Generate embeddings)
   ↓
5. Qdrant Insert (Store in vector DB)
```

---

## Gitea Integration

### Configuration via HTTP Request Node

**Node**: HTTP Request
**Method**: Various (GET, POST, etc.)
**Base URL**: `http://10.0.5.120:3003/api/v1`

### Authentication

Use Gitea API token:

```
Headers:
  - Authorization: token {{ $credentials.giteaToken }}
```

### Common API Endpoints

**Repositories**:
- `GET /repos/{owner}/{repo}` - Get repository info
- `GET /repos/{owner}/{repo}/commits` - List commits
- `POST /org/{org}/repos` - Create repository
- `GET /repos/{owner}/{repo}/issues` - List issues
- `POST /repos/{owner}/{repo}/issues` - Create issue

**Users**:
- `GET /user` - Get current user
- `GET /users/{username}` - Get user info

### Use Cases

1. **Automated Backups** - Backup workflows to Git
2. **Issue Tracking** - Auto-create issues from workflow errors
3. **CI/CD Integration** - Trigger workflows on Git events
4. **Code Analysis** - Analyze commits, pull requests
5. **Repository Management** - Automate repo creation

### Example Workflow: Backup n8n Workflows to Git

```
1. Schedule (daily)
   ↓
2. n8n API (Export all workflows)
   ↓
3. For each workflow:
   - Format as JSON
   - HTTP Request to Gitea (create/update file)
   ↓
4. Notification (send backup status)
```

---

## Matrix Chat Integration

### Configuration via HTTP Request Node

**Node**: HTTP Request
**Base URL**: `http://10.0.5.142:8008/_matrix/client/v3`

### Authentication

1. First, get access token by logging in:
```
POST http://10.0.5.142:8008/_matrix/client/v3/login
Body:
{
  "type": "m.login.password",
  "user": "n8n-bot",
  "password": "bot-password"
}
```

2. Use access token in subsequent requests:
```
Headers:
  - Authorization: Bearer {{ $json.access_token }}
```

### Common Operations

**Send Message to Room**:
```
PUT /_matrix/client/v3/rooms/{roomId}/send/m.room.message/{txnId}
Body:
{
  "msgtype": "m.text",
  "body": "Message from n8n workflow"
}
```

**Create Room**:
```
POST /_matrix/client/v3/createRoom
Body:
{
  "name": "Workflow Notifications",
  "topic": "Automated notifications from n8n"
}
```

### Use Cases

1. **Workflow Notifications** - Send alerts to Matrix chat
2. **Error Reporting** - Alert team of workflow errors
3. **Status Updates** - Send periodic status updates
4. **Collaboration** - Trigger workflows from chat messages
5. **ChatOps** - Execute workflows via chat commands

---

# Complete Workflow Examples

## 1. Document Processing Pipeline

**Purpose**: Automatically process documents uploaded to Nextcloud

**Trigger**: Schedule (every 15 minutes)

**Steps**:
```
1. Nextcloud WebDAV (List files in /uploads/)
   ↓
2. IF (files found)
   ↓
3. For Each File:
   a. Download file from Nextcloud
   b. HTTP Request to Tika (extract text)
   c. Split text into chunks (500 words each)
   d. For each chunk:
      - Generate embeddings via Ollama (nomic-embed-text)
      - Insert into Qdrant (user1_docs collection)
   e. Move file to /processed/ in Nextcloud
   ↓
4. Matrix Notification (send processing summary)
```

**Nodes**:
- Nextcloud WebDAV (List)
- IF
- Loop Over Items
- Nextcloud WebDAV (Download)
- HTTP Request (Tika)
- Code (Split text)
- Ollama Embeddings
- Qdrant Vector Store (Insert)
- Nextcloud WebDAV (Move)
- HTTP Request (Matrix)

---

## 2. AI Research Assistant

**Purpose**: Research a topic and generate summary using web search + LLM

**Trigger**: Webhook (POST with `topic` parameter)

**Steps**:
```
1. Webhook (receive topic)
   ↓
2. HTTP Request to SearXNG (search for topic)
   ↓
3. Extract top 5 results (URLs and snippets)
   ↓
4. For each URL:
   - HTTP Request (fetch page content)
   - Extract main text
   ↓
5. Combine all text
   ↓
6. Ollama Chat Model (summarize with prompt)
   Prompt: "Based on the following sources, provide a comprehensive summary about {{topic}}:\n\n{{sources}}"
   ↓
7. Store summary in PostgreSQL
   ↓
8. Return summary via webhook response
```

**Nodes**:
- Webhook
- HTTP Request (SearXNG)
- Code (extract URLs)
- Loop Over Items
- HTTP Request (fetch pages)
- Code (extract text)
- Aggregate
- Ollama Chat Model
- PostgreSQL (Insert)
- Respond to Webhook

---

## 3. Automated Workflow Backup to S3

**Purpose**: Daily backup of all n8n workflows to MinIO S3

**Trigger**: Schedule (daily at 2 AM)

**Steps**:
```
1. Schedule (cron: 0 2 * * *)
   ↓
2. n8n API (GET /workflows - get all workflows)
   ↓
3. For each workflow:
   - Format as JSON
   - Add timestamp to filename
   ↓
4. Combine all workflows into single backup file
   ↓
5. S3 (Upload to bucket: n8n-backups)
   File: backup_YYYY-MM-DD.json
   ↓
6. Redis (Set key: last_backup_date)
   ↓
7. Matrix Notification (send backup status)
```

**Nodes**:
- Schedule
- HTTP Request (n8n API)
- Loop Over Items
- Code (format JSON)
- Aggregate
- S3 (Upload)
- Redis (Set)
- HTTP Request (Matrix)

---

## 4. PostgreSQL to MinIO Data Lake

**Purpose**: Extract data from PostgreSQL and store in MinIO as Parquet

**Trigger**: Schedule (daily)

**Steps**:
```
1. Schedule (daily at midnight)
   ↓
2. PostgreSQL (Execute Query)
   Query: SELECT * FROM analytics_data WHERE date = CURRENT_DATE - 1
   ↓
3. Code (Convert to Parquet format)
   ↓
4. S3 (Upload to data-lake bucket)
   Path: /year=2025/month=01/day=15/data.parquet
   ↓
5. PostgreSQL (Update sync_log table)
   ↓
6. IF (errors occurred)
   ↓
7. Matrix Notification (alert team)
```

**Nodes**:
- Schedule
- PostgreSQL (Execute Query)
- Code
- S3 (Upload)
- PostgreSQL (Insert)
- IF
- HTTP Request (Matrix)

---

## 5. RAG Question Answering System

**Purpose**: Answer questions using documents in Qdrant

**Trigger**: Webhook (POST with `question` parameter)

**Steps**:
```
1. Webhook (receive question)
   ↓
2. Qdrant Vector Store (Retrieve Documents)
   Collection: user1_docs
   Query: {{ $json.question }}
   Top K: 5
   ↓
3. Code (Format context from retrieved docs)
   ↓
4. Ollama Chat Model
   System: "You are a helpful assistant. Answer based on the context."
   Prompt: "Context:\n{{context}}\n\nQuestion: {{question}}\n\nAnswer:"
   ↓
5. PostgreSQL (Log Q&A)
   ↓
6. Respond to Webhook (return answer)
```

**Nodes**:
- Webhook
- Qdrant Vector Store (Retrieve)
- Code
- Ollama Chat Model
- PostgreSQL (Insert)
- Respond to Webhook

---

## 6. Smart Content Aggregator

**Purpose**: Monitor web sources, summarize with AI, store in knowledge base

**Trigger**: Schedule (every hour)

**Steps**:
```
1. Schedule (hourly)
   ↓
2. HTTP Request to SearXNG (search: "AI news")
   ↓
3. Extract new URLs (check against Redis cache)
   ↓
4. For each new URL:
   a. HTTP Request (fetch content)
   b. HTTP Request to Tika (extract text)
   c. Ollama Chat Model (summarize)
      Prompt: "Summarize this article in 3 bullet points: {{text}}"
   d. Generate embeddings (Ollama)
   e. Insert into Qdrant (news_summaries collection)
   f. Insert into PostgreSQL (articles table)
   g. Store URL in Redis cache (TTL: 7 days)
   ↓
5. Aggregate summaries
   ↓
6. Matrix Notification (daily digest)
```

**Nodes**:
- Schedule
- HTTP Request (SearXNG)
- Redis (Get)
- Code (filter URLs)
- Loop Over Items
- HTTP Request (fetch)
- HTTP Request (Tika)
- Ollama Chat Model
- Ollama Embeddings
- Qdrant Vector Store
- PostgreSQL
- Redis (Set)
- Aggregate
- HTTP Request (Matrix)

---

## 7. Error Monitoring & Auto-Recovery

**Purpose**: Monitor workflows, detect errors, attempt recovery

**Trigger**: Schedule (every 5 minutes)

**Steps**:
```
1. Schedule (every 5 minutes)
   ↓
2. n8n API (GET /executions?status=error)
   ↓
3. IF (errors found)
   ↓
4. For each error:
   a. Extract error details
   b. Check if retryable (Code node logic)
   c. IF retryable:
      - n8n API (retry execution)
   d. ELSE:
      - PostgreSQL (log error)
      - Matrix Notification (alert team)
   ↓
5. Update Redis (error_count counter)
```

**Nodes**:
- Schedule
- HTTP Request (n8n API)
- IF
- Loop Over Items
- Code
- IF
- HTTP Request (n8n API retry)
- PostgreSQL
- HTTP Request (Matrix)
- Redis

---

## Configuration Checklist

Before running workflows, ensure all credentials are configured:

- [ ] PostgreSQL credentials (10.0.5.102)
- [ ] S3 credentials for MinIO (10.0.5.104)
- [ ] Ollama API (10.0.5.100)
- [ ] Qdrant API (10.0.5.101)
- [ ] Redis credentials (10.0.5.103)
- [ ] Nextcloud WebDAV credentials (10.0.5.26)
- [ ] Gitea API token (10.0.5.120)
- [ ] Matrix access token (10.0.5.142)

## Testing Workflows

Test each workflow individually:

1. **Start with simple operations**: Test single nodes (e.g., PostgreSQL query)
2. **Verify connectivity**: Ensure all services are reachable
3. **Check error handling**: Test what happens on failures
4. **Monitor performance**: Check execution times
5. **Validate outputs**: Ensure data is correctly processed and stored

## Best Practices

1. **Use descriptive node names**: Makes debugging easier
2. **Add error handling**: Use IF nodes and Error Trigger
3. **Log important actions**: Store in PostgreSQL for audit trail
4. **Use Redis for caching**: Avoid redundant API calls
5. **Implement rate limiting**: Don't overwhelm services
6. **Version control workflows**: Backup to Gitea regularly
7. **Monitor execution times**: Set reasonable timeouts
8. **Use environment variables**: Don't hardcode credentials
9. **Test with sample data first**: Before production use
10. **Document custom code**: Add comments in Code nodes

---

## Next Steps

1. Import these workflow examples into n8n
2. Configure all credentials
3. Test each workflow individually
4. Monitor via n8n execution log
5. Set up alerting for failed executions
6. Create custom workflows for your specific use cases

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Workflow Templates](https://n8n.io/workflows/)
- [n8n Community Forum](https://community.n8n.io/)
