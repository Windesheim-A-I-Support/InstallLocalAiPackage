# Authentication Strategy

## Current State: Individual Service Auth

Each service currently has its own authentication:
- Open WebUI: JWT (WEBUI_SECRET_KEY)
- Nextcloud: Built-in user management
- Supabase: Built-in auth with JWT
- n8n: Built-in user management
- Gitea: Built-in user management
- etc.

## Recommended: Unified SSO with Authentik

### Why Authentik?
- Open source SSO/OAuth2/SAML provider
- Integrates with most services
- LDAP provider for legacy apps
- User management dashboard
- Works with Open WebUI and other services

### Architecture

```
                    [Authentik SSO]
                    10.0.5.24:9000
                           |
        +------------------+------------------+
        |                  |                  |
   [Open WebUI]       [Gitea]           [n8n]
   [Nextcloud]      [Grafana]      [BookStack]
   [Supabase]       [Metabase]      [Portainer]
```

### Integration Status

**Native OAuth2/OIDC Support** (Easy):
- ✅ Nextcloud
- ✅ Grafana
- ✅ Gitea
- ✅ n8n
- ✅ Metabase
- ✅ Portainer
- ✅ BookStack

**LDAP Support** (Medium):
- ✅ Many services support LDAP fallback

**No SSO Support** (Keep individual auth):
- Open WebUI (individual instances need separate auth)
- Some simple services

## Implementation Plan

### Option 1: Deploy Authentik (Recommended)
1. Deploy Authentik on 10.0.5.24:9000
2. Configure as OAuth2 provider
3. Add applications for each service
4. Update service configs to use Authentik

### Option 2: Use Existing Solutions
- Keycloak (heavier, more enterprise)
- Authelia (lighter, simpler)
- Zitadel (modern, good UI)

### Option 3: Keep Individual Auth (Current)
- Simpler to maintain
- No single point of failure
- More passwords to manage
- Users create account per service

## Recommended Approach

**Phase 1: Individual Auth** (Current)
- Each service has own user management
- Document default credentials
- Use strong passwords from `generate_env_secrets.sh`

**Phase 2: Deploy Authentik** (Future)
- Add Authentik as service 36
- Start with non-critical services (Grafana, Gitea)
- Gradually migrate services

**Phase 3: Full SSO** (Future)
- All compatible services use Authentik
- Single sign-on across platform
- Centralized user management

## Service-Specific Auth Notes

### Open WebUI
- **Auth**: JWT with WEBUI_SECRET_KEY
- **Config**: `WEBUI_AUTH=true`
- **SSO**: Not currently supported
- **Solution**: Each instance maintains own users

### Nextcloud
- **Auth**: Built-in + OAuth2
- **SSO**: Yes (OAuth2, SAML)
- **LDAP**: Yes
- **Recommendation**: Integrate with Authentik

### Gitea
- **Auth**: Built-in + OAuth2
- **SSO**: Yes (OAuth2, OpenID)
- **LDAP**: Yes
- **Recommendation**: Integrate with Authentik

### Grafana
- **Auth**: Built-in + OAuth2
- **SSO**: Yes (OAuth2, SAML)
- **LDAP**: Yes
- **Recommendation**: Integrate with Authentik

### n8n
- **Auth**: Built-in + OAuth2
- **SSO**: Yes (OAuth2, SAML)
- **LDAP**: No
- **Recommendation**: Integrate with Authentik

### Supabase
- **Auth**: Built-in auth service (provides auth for other apps)
- **SSO**: Can be auth provider itself
- **Recommendation**: Keep as separate auth service for apps

### PostgreSQL
- **Auth**: Username/password
- **SSO**: Via pg_hba.conf + PAM
- **Recommendation**: Keep service accounts, no SSO needed

### Redis
- **Auth**: Password (requirepass)
- **SSO**: No
- **Recommendation**: Keep password auth

## Current Credentials Reference

**Default Passwords** (change in production):
```bash
# PostgreSQL
User: dbadmin
Pass: (generated in .env)

# Redis
Pass: (generated in .env)

# MinIO
Access Key: minioadmin
Secret Key: minioadmin

# Grafana
User: admin
Pass: admin (change on first login)

# BookStack
Email: admin@admin.com
Pass: password (change on first login)

# Open WebUI
Created on first signup
```

**Security Best Practices**:
1. All secrets generated via `generate_env_secrets.sh`
2. Passwords stored in service-specific .env files
3. Never commit .env files to git
4. Use strong passwords (32+ characters)
5. Rotate secrets periodically

## Decision Required

**Choose authentication approach:**

1. **Keep Current** (Individual auth per service)
   - ✅ Simpler to maintain
   - ✅ Already working
   - ❌ More passwords
   - ❌ No SSO

2. **Deploy Authentik** (Unified SSO)
   - ✅ Single sign-on
   - ✅ Centralized users
   - ✅ Better UX
   - ❌ More complex
   - ❌ Single point of failure

3. **Hybrid Approach** (Recommended for now)
   - Individual auth for Open WebUI instances
   - Authentik for shared services (Gitea, Grafana, n8n, etc.)
   - Best of both worlds
