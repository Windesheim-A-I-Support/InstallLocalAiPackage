# Deployment Credentials - 2025-12-08

## Session Summary

Attempted deployments of Neo4j, Docling, and LibreTranslate on containers 107, 112, and 114.

### Deployment Results

#### Neo4j (10.0.5.107)
- **Status**: Deployment status unknown - needs investigation
- **Issue**: Deployment script completed but Neo4j not found installed
- **Container**: 10.0.5.107 (4 CPU, 4GB RAM, 50GB disk)
- **Credentials**: Not generated (deployment incomplete)

#### Docling (10.0.5.112)
- **Status**: Deployment failed - SSH connection reset
- **Issue**: Container became unresponsive during package installation
- **Container**: 10.0.5.112 (2 CPU, 3GB RAM, 15GB disk)
- **Likely Cause**: Container overloaded during compilation of build-essential (~128MB)
- **Credentials**: Not generated (deployment incomplete)

#### LibreTranslate (10.0.5.114)
- **Status**: FAILED - Disk quota exceeded
- **Issue**: Container ran out of disk space while installing PyTorch + CUDA libraries
- **Container**: 10.0.5.114 (2 CPU, 2GB RAM, 10GB disk)
- **Required Disk**: ~25GB minimum (PyTorch 797MB + CUDA 2.5GB + dependencies)
- **Downloaded Successfully**: All packages downloaded before installation failure
- **Credentials**: Not generated (deployment incomplete)

### Package Sizes Downloaded

LibreTranslate dependencies that were successfully downloaded before disk failure:
- torch: 797.3 MB
- nvidia-cudnn-cu12: 664.8 MB
- nvidia-cublas-cu12: 410.6 MB
- triton: 209.4 MB
- nvidia-nccl-cu12: 176.2 MB
- nvidia-cusparse-cu12: 196.0 MB
- nvidia-cusolver-cu12: 124.2 MB
- nvidia-cufft-cu12: 121.6 MB
- nvidia-curand-cu12: 56.5 MB
- nvidia-nvjitlink-cu12: 39.7 MB
- ctranslate2: 37.8 MB
- numpy: 18.3 MB
- Other dependencies: ~200 MB

**Total**: Over 3.5GB of dependencies

### Disk Space Requirements Analysis

Based on deployment attempts:

| Service | Current Disk | Required Disk | Status |
|---------|-------------|---------------|--------|
| LibreTranslate | 10GB | 25GB+ | Too small |
| Docling | 15GB | 20GB+ | Might be tight |
| Neo4j | 50GB | 10GB | Sufficient |

### Recommendations

1. **Increase disk allocations** in Proxmox:
   ```bash
   # From Proxmox host
   pct resize 114 rootfs +15G  # LibreTranslate: 10GB → 25GB
   pct resize 112 rootfs +5G   # Docling: 15GB → 20GB
   ```

2. **Restart affected containers**:
   ```bash
   pct stop 112 && pct start 112  # Docling
   pct stop 114 && pct start 114  # LibreTranslate (after resize)
   ```

3. **Deploy simpler services first** (no ML dependencies):
   - Gitea (120): Binary download, ~100MB
   - Tika (111): Java JAR, ~80MB
   - BookStack (116): PHP + Composer, ~500MB
   - Metabase (117): Java JAR, ~300MB
   - SearXNG (105): Python + deps, ~500MB

### Next Steps

1. Check Neo4j deployment logs on container 107
2. Deploy lighter services (Gitea, Tika, BookStack, Metabase)
3. Increase disk space for ML-heavy services
4. Retry LibreTranslate and Docling after disk resize

### Files Created During Session

- Fixed [26_deploy_shared_libretranslate_native.sh](26_deploy_shared_libretranslate_native.sh) - permission issues resolved
- Updated [DEPLOYMENT_FINAL_STATUS.md](DEPLOYMENT_FINAL_STATUS.md)
- Updated [SHARED_SERVICES_STATUS.csv](SHARED_SERVICES_STATUS.csv)

### Lessons Learned

1. **ML services need significant disk space**: PyTorch-based services require 20GB+ minimum
2. **Check disk allocations before deployment**: Prevent quota exceeded errors
3. **Resource constraints on LXC containers**: Limited CPU/RAM can cause installation failures
4. **Deploy simpler services first**: Build confidence before tackling heavy ML services
