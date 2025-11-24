Here is the extensive list of **Standalone Applications** for your Research Lab & AI Stack.

This table combines the **Scientific Tools** (for your humans) and the **AI Capability Tools** (for your agents) into one master list, with no overlap.

| Tool Name | Description |
| :--- | :--- |
| **Open WebUI** | The central "Operating System" for your AI. Provides a ChatGPT-like interface that connects to all your LLMs, agents, and documents. |
| **N8N** | A workflow automation platform. Acts as the "nervous system" connecting your AI agents to external APIs, databases, and instruments. |
| **Flowise** | A low-code drag-and-drop builder for creating complex AI agents and RAG pipelines without writing code. |
| **eLabFTW** | A secure Electronic Lab Notebook (ELN) for documenting experiments. Entries are cryptographically timestamped to prove discovery dates. |
| **JupyterHub** | A multi-user server for Jupyter Notebooks. Allows the whole research team to run Python/R data analysis on shared server resources. |
| **Label Studio** | A data annotation interface. Used to manually label raw data (images, audio, text) to create "Ground Truth" datasets for training AI models. |
| **Overleaf** (ShareLaTeX) | A real-time collaborative LaTeX editor. Essential for drafting and formatting complex scientific papers and technical journals. |
| **BookStack** | A structured documentation platform (Books > Chapters > Pages). Stores SOPs, safety protocols, and equipment manuals in an organized format. |
| **Nextcloud** | A secure, self-hosted replacement for Dropbox/Google Drive. Manages raw research data, syncs team calendars, and handles file sharing. |
| **Gitea** | A lightweight Git server. Provides version control for research code, analysis scripts, and simulation software, keeping IP on-premise. |
| **Metabase** | A business intelligence tool. Visualizes database data into dashboards, perfect for tracking lab metrics or experiment results. |
| **Kanboard** | A minimalist Kanban board. Tracks the lifecycle of research projects (e.g., Literature Review → Data Collection → Drafting → Published). |
| **Browserless** | A headless web browser API. Allows AI agents to visit websites, render JavaScript, click buttons, and take screenshots for advanced scraping. |
| **ChangeDetection.io** | A website monitor. Watches specific URLs for visual or text changes (e.g., new grant postings) and triggers alerts or webhooks. |
| **Apache Tika** | A universal content extraction toolkit. Parses text and metadata from over 1,000+ file formats (messy PDFs, Excel, old emails) for clean RAG ingestion. |
| **Gotenberg** | A stateless PDF generator. Converts Markdown, HTML, and Office documents into professionally formatted PDFs via API. |
| **Piston** | A secure code execution sandbox. Allows the AI to write and run Python/JS code to solve math or logic problems accurately without hallucinating. |
| **AllTalk** | A text-to-speech engine. Generates high-quality, deep-learning based AI voices (with cloning support) to give your agents a human voice. |
| **Whisper** (Webservice) | A speech-to-text engine. Processes microphone audio locally, allowing users to speak verbal commands to the AI. |
| **Stirling-PDF** | A full-featured PDF manipulation suite. Merges, splits, rotates, watermarks, and OCRs documents via a GUI. |
| **ComfyUI** | A node-based Stable Diffusion engine. Enables the AI to generate complex diagrams and images from text prompts (runs on CPU). |
| **SearXNG** | A private meta-search engine. Aggregates results from Google, Bing, and Reddit without tracking, giving the AI "current events" knowledge. |
| **Langfuse** | An LLM engineering platform. Tracks AI usage, costs, latency, and quality of responses for debugging agent performance. |
| **MinIO** | A high-performance object storage server (S3 compatible). Acts as a "Data Lake" for massive raw instrument files that don't fit in standard databases. |
| **Draw.io** | A diagramming tool. Allows researchers to create flowcharts, circuit diagrams, and biological pathways for publications. |

---

## **🔧 Infrastructure & DevOps Tools**

| Tool Name | Description |
| :--- | :--- |
| **Portainer** | A Docker management UI. Provides web-based control panel for managing containers, images, networks, and volumes across your AI stack. |
| **Dozzle** | Real-time Docker log viewer. Lightweight dashboard for tailing container logs without SSH access - essential for debugging AI services. |
| **Watchtower** | Automatic Docker container updater. Monitors and updates running containers to latest versions, ensuring security patches are applied. |
| **Grafana** | Metrics visualization platform. Creates beautiful dashboards from Prometheus/InfluxDB data to monitor CPU, RAM, GPU, and API latency. |
| **Prometheus** | Time-series metrics database. Scrapes and stores performance data from all services, enabling historical analysis and alerting. |
| **Uptime Kuma** | Self-hosted uptime monitoring. Tracks service availability, SSL certificate expiry, and sends alerts via Discord/Slack/Email. |
| **Traefik** | Modern reverse proxy and load balancer. Automatically discovers containers, manages SSL certificates, and routes traffic with zero downtime. |

---

## **📊 Data & Analytics Infrastructure**

| Tool Name | Description |
| :--- | :--- |
| **Apache Superset** | Modern BI platform. Creates interactive dashboards and visualizations from databases - more powerful than Metabase with Python extensibility. |
| **PostHog** | Product analytics with session replay. Tracks how users interact with Open WebUI, records sessions, and provides A/B testing capabilities. |
| **Plausible Analytics** | Privacy-focused web analytics. Lightweight, GDPR-compliant alternative to Google Analytics for tracking AI interface usage. |
| **Apache Airflow** | Workflow orchestration platform. Schedules and monitors complex data pipelines, ETL jobs, and ML model training workflows. |
| **Prefect** | Modern data workflow engine. Python-native alternative to Airflow with better error handling and dynamic DAG generation. |
| **Druid** | Real-time analytics database. Handles massive datasets with sub-second query times - perfect for analyzing millions of LLM interactions. |

---

## **🤖 AI/ML Enhancement Tools**

| Tool Name | Description |
| :--- | :--- |
| **Dify** | LLM application development platform. Visual builder for creating AI apps, agents, and chatbots with prompt engineering tools. |
| **Anything LLM** | All-in-one AI app. Combines chat interface, RAG, agents, and workspace organization - alternative to Open WebUI. |
| **vLLM** | High-throughput LLM serving engine. Optimized inference server supporting paged attention and continuous batching for 10x faster inference. |
| **Text Generation WebUI** | Feature-rich LLM interface. Supports model quantization, LoRA adapters, multimodal models, and advanced sampling parameters. |
| **LiteLLM** | Unified LLM proxy. Load balances across Ollama, OpenAI, Anthropic, and 100+ providers with OpenAI-compatible API. |
| **BentoML** | ML model serving framework. Packages models as production-ready APIs with auto-scaling, batching, and multi-framework support. |
| **MLflow** | End-to-end ML lifecycle platform. Tracks experiments, packages models, and deploys to production with versioning and A/B testing. |
| **Label Studio** | Already listed - but worth emphasizing for creating training datasets from PDFs, images, and text for fine-tuning models. |

---

## **📚 Knowledge Management & RAG Enhancement**

| Tool Name | Description |
| :--- | :--- |
| **Outline** | Modern wiki and knowledge base. Beautiful, fast alternative to BookStack with real-time collaboration and powerful search. |
| **Wiki.js** | Feature-rich wiki engine. Supports Markdown, diagrams, math equations, and integrates with Git for version control. |
| **Memos** | Lightweight note-taking service. Think Twitter for your thoughts - quick knowledge capture with tagging and full-text search. |
| **Obsidian Livesync** (CouchDB) | Self-hosted Obsidian sync. Enables your research team to sync their local Obsidian vaults for networked note-taking. |
| **Paperless-ngx** | Document management system. OCRs and indexes scanned papers, invoices, and receipts with full-text search and tagging. |
| **Tika** | Already listed - Apache content extraction. Complements Paperless-ngx for parsing obscure file formats. |
| **Calibre-Web** | eBook library manager. Organizes research papers, textbooks, and technical manuals with OPDS support for e-readers. |

---

## **🔬 Scientific & Research Specific**

| Tool Name | Description |
| :--- | :--- |
| **OpenRefine** | Data cleaning and transformation tool. Cleans messy CSV/Excel datasets, reconciles entities, and prepares data for ML training. |
| **RStudio Server** | Web-based R IDE. Statistical computing environment for data analysis, essential for biostatistics and research reproducibility. |
| **Apache Zeppelin** | Multi-language notebook. Supports Python, R, Scala, and SQL in one interface with built-in visualization libraries. |
| **Redash** | SQL query and visualization platform. Connects to 18+ data sources, schedules queries, and shares dashboards with your team. |
| **Dagster** | Data orchestration platform. Modern alternative to Airflow focused on data quality, testing, and observability. |
| **Seafile** | High-performance file sync. Faster than Nextcloud for large datasets with file versioning and selective sync. |

---

## **💬 Communication & Collaboration**

| Tool Name | Description |
| :--- | :--- |
| **Rocket.Chat** | Self-hosted Slack alternative. Team messaging with channels, threads, video calls, and AI bot integration. |
| **Mattermost** | Enterprise collaboration platform. More mature than Rocket.Chat with advanced permissions and compliance features. |
| **Zulip** | Threaded team chat. Unique topic-based threading model prevents information overload in busy research channels. |
| **Cal.com** | Open-source Calendly. Schedule meetings, equipment reservations, and experiment time slots with team availability. |
| **Jitsi Meet** | Video conferencing platform. Self-hosted Zoom alternative with screen sharing, recording, and no time limits. |

---

## **🔐 Security & Identity**

| Tool Name | Description |
| :--- | :--- |
| **Authentik** | Identity provider (SSO). Single sign-on for all services with LDAP, SAML, OAuth2, and MFA support. |
| **Keycloak** | Enterprise identity and access management. More feature-rich than Authentik with user federation and fine-grained authorization. |
| **Vaultwarden** | Lightweight Bitwarden server. Self-hosted password manager for your research team with secure credential sharing. |
| **Authelia** | Authentication and authorization server. Adds 2FA and SSO to apps that don't natively support it via reverse proxy. |

---

## **🖼️ Media & Content Generation**

| Tool Name | Description |
| :--- | :--- |
| **Stable Diffusion WebUI (AUTOMATIC1111)** | Full-featured image generation. More powerful than ComfyUI with extensions for ControlNet, img2img, and training. |
| **InvokeAI** | Professional AI art generator. Canvas interface for inpainting, outpainting, and iterative image refinement. |
| **Kohya_ss** | LoRA training interface. Fine-tunes Stable Diffusion models on custom datasets (e.g., microscopy images, lab equipment). |
| **Coqui TTS** | Advanced text-to-speech. Multi-speaker, multi-lingual voice generation with voice cloning - alternative to AllTalk. |
| **OpenVoice** | Instant voice cloning. Clones any voice from 3-second sample for generating narrated video content. |

---

## **🔍 Search & Discovery**

| Tool Name | Description |
| :--- | :--- |
| **Meilisearch** | Fast, typo-tolerant search engine. Alternative to Elasticsearch with instant results and minimal resource usage. |
| **Typesense** | Open-source Algolia alternative. Lightning-fast search with typo tolerance and geo-search for lab equipment inventory. |
| **Whoogle** | Privacy-focused Google frontend. Proxies Google searches without tracking - cleaner than SearXNG for personal use. |

---

## **🔄 Integration & Automation**

| Tool Name | Description |
| :--- | :--- |
| **Activepieces** | Open-source Zapier alternative. Similar to n8n but with more pre-built connectors and simpler UI for non-technical users. |
| **Trigger.dev** | Code-first workflow engine. TypeScript-based automation for developers who prefer coding over visual workflows. |
| **Huginn** | Self-hosted IFTTT. Creates agents that monitor websites, perform actions, and chain together complex automation. |
| **Kestra** | Event-driven orchestration. Real-time data pipelines with sub-millisecond latency - perfect for instrument data ingestion. |

---

## **📈 Missing Gaps in Your Current Stack**

Based on analysis, you're missing:

### **Priority 1: Monitoring & Observability**
- ✅ **Langfuse** (already have) - LLM tracing
- ❌ **Grafana + Prometheus** - Infrastructure monitoring
- ❌ **Uptime Kuma** - Service availability monitoring
- ❌ **Dozzle** - Quick log viewing

### **Priority 2: Identity & Access Management**
- ❌ **Authentik** or **Keycloak** - SSO across all services
- ❌ **Vaultwarden** - Team password management

### **Priority 3: Advanced AI Capabilities**
- ❌ **vLLM** - 10x faster inference than Ollama
- ❌ **MLflow** - Experiment tracking and model versioning
- ❌ **LiteLLM** - Multi-provider load balancing

### **Priority 4: Data Pipeline & ETL**
- ❌ **Apache Airflow** or **Dagster** - Scheduled workflows
- ❌ **OpenRefine** - Data cleaning before RAG ingestion

### **Priority 5: Enhanced Collaboration**
- ❌ **Outline** or **Wiki.js** - Better documentation than BookStack
- ❌ **Rocket.Chat** - Team communication
- ❌ **Cal.com** - Resource scheduling

---

## **📚 Sources**

- [Self Hosted AI - Top AI Tools](https://topai.tools/s/self-hosted-ai)
- [Awesome Production Machine Learning](https://github.com/EthicalML/awesome-production-machine-learning)
- [Awesome Selfhosted](https://github.com/awesome-selfhosted/awesome-selfhosted)
- [OpenBestOf Awesome AI](https://github.com/openbestof/awesome-ai)
- [Best Self-Hosted AI Tools 2024](https://www.virtualizationhowto.com/2025/10/best-self-hosted-ai-tools-you-can-actually-run-in-your-home-lab/)