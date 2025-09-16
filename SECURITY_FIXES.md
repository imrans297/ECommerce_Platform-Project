# Security Remediation Required Before GitHub Push

## Critical Issues to Fix

### 1. Hardcoded Credentials
**Files affected:**
- `ci-cd/jenkins/create-pipeline-job.sh` (lines 7-8)
- `infrastructure/ansible/playbook.yml` (line 48-49)
- `DEPLOYMENT_GUIDE.md` (lines 32-33)

**Fix:** Replace with environment variables:
```bash
# Instead of: JENKINS_USER="admin"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_PASSWORD="${JENKINS_PASSWORD}"
```

### 2. JWT Secrets in Code
**Files affected:**
- `applications/user-service/src/models/User.js` (line 101-102)
- `applications/user-service/src/middleware/auth.js` (line 101-102)

**Fix:** Use environment variables:
```javascript
// Instead of: const secret = "hardcoded-secret"
const secret = process.env.JWT_SECRET || 'fallback-secret';
```

### 3. Package Vulnerabilities
**Files affected:**
- `applications/product-service/requirements.txt`

**Fix:** Update dependencies:
```bash
pip install --upgrade gunicorn>=21.0.0 requests>=2.32.0
```

### 4. Security Headers & CSRF
**Files affected:**
- `applications/user-service/src/app.js`
- `applications/user-service/src/routes/users.js`

**Fix:** Enable CSRF protection and secure headers.

## Steps to Secure Before Push

1. **Copy environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Update all hardcoded credentials with environment variables**

3. **Update vulnerable dependencies**

4. **Add security middleware**

5. **Test all services work with environment variables**

6. **Verify .gitignore excludes sensitive files**

## Safe to Push After:
- [ ] All hardcoded credentials removed
- [ ] Environment variables configured
- [ ] Dependencies updated
- [ ] Security middleware added
- [ ] .env files in .gitignore
- [ ] All services tested