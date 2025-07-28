# Production Security Checklist

## ⚠️ CRITICAL - Immediate Actions Required

### 1. API Keys - REGENERATE IMMEDIATELY
- [ ] **Google Geocoding API Key** - The current key is exposed and must be regenerated
- [ ] **Google Maps API Key** - May also be exposed, regenerate as precaution
- [ ] Update all environment variables with new keys

### 2. Django Secret Key
- [ ] Generate new SECRET_KEY for production
- [ ] Ensure it's never committed to version control

## Environment Variables Setup

### Backend (.env in production)
```bash
SECRET_KEY=your-production-secret-key-here
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
DATABASE_URL=postgresql://username:password@host:port/database_name
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
GOOGLE_GEOCODING_API_KEY=your-new-google-api-key-here
```

### Frontend (.env.production)
```bash
NEXT_PUBLIC_API_URL=https://api.yourdomain.com/api
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=your-new-google-maps-api-key-here
```

## Security Features Implemented ✅

### Django Backend Security
- [x] HTTPS/SSL redirect in production
- [x] Secure cookies (HTTPS only)
- [x] CSRF protection
- [x] XSS filtering
- [x] Content type sniffing protection
- [x] HSTS headers
- [x] Secure referrer policy
- [x] File upload size limits (5MB)
- [x] CORS properly configured
- [x] WhiteNoise for secure static file serving

### Frontend Security
- [x] Security headers (X-Frame-Options, X-Content-Type-Options, Referrer-Policy)
- [x] Secure image loading with remotePatterns
- [x] No sensitive data in client-side code

## Database Security
- [x] Production uses PostgreSQL (not SQLite)
- [x] Connection via environment variables
- [x] No hardcoded credentials

## Deployment Security
- [x] .dockerignore files to exclude sensitive files
- [x] Proper .gitignore configuration
- [x] Development files excluded from production builds

## Additional Recommendations

### 1. Monitoring & Logging
- [ ] Set up Sentry for error tracking
- [ ] Configure proper Django logging
- [ ] Set up database connection monitoring

### 2. Infrastructure Security
- [ ] Use AWS Secrets Manager for sensitive data
- [ ] Enable CloudTrail for audit logging
- [ ] Set up WAF (Web Application Firewall)
- [ ] Configure proper VPC security groups

### 3. SSL/TLS
- [ ] Use SSL certificates (Let's Encrypt or AWS Certificate Manager)
- [ ] Configure proper SSL termination at load balancer

### 4. Database Security
- [ ] Enable database encryption at rest
- [ ] Use connection pooling
- [ ] Regular database backups
- [ ] Network isolation for database

### 5. Media Files
- [ ] Consider using AWS S3 for media files in production
- [ ] Set up CDN for better performance and security

## Files to Remove Before Production

### Development Files
- Remove all .pyc files and __pycache__ directories
- Remove db.sqlite3 (development database)
- Remove test files (**/tests.py)
- Remove documentation files (except RDD.md)
- Remove development scripts (*.sh files)

### Build Artifacts
- Remove frontend/node_modules (will be rebuilt)
- Remove frontend/.next and frontend/out
- Remove backend/staticfiles (will be collected)

## Testing Checklist

### Before Deployment
- [ ] Test with DEBUG=False locally
- [ ] Verify all environment variables are set
- [ ] Test image upload functionality
- [ ] Test API endpoints with production-like setup
- [ ] Verify CORS settings work with production frontend URL
- [ ] Test SSL redirect (if applicable)

### After Deployment
- [ ] Verify all pages load correctly
- [ ] Test user registration/login
- [ ] Test image upload and display
- [ ] Check that media files are served correctly
- [ ] Verify security headers are present
- [ ] Test API functionality

## Emergency Contacts
- Document who to contact for:
  - Database issues
  - SSL certificate problems
  - API key regeneration
  - AWS infrastructure issues

---

**Note**: This checklist should be reviewed and updated regularly as the application evolves.