# Production Deployment Guide

This guide covers deploying StreamSource to production with Cloudflare Workers.

## Pre-Deployment Checklist

### 1. Notion Setup
- [ ] Create production Notion integration at https://www.notion.so/my-integrations
- [ ] Create production database with all required properties
- [ ] Share database with integration
- [ ] Test database permissions

### 2. Platform API Keys (Optional but Recommended)
- [ ] YouTube API key for health checks
- [ ] Twitch Client ID & Secret
- [ ] Facebook Access Token (if needed)

### 3. Security
- [ ] Generate strong API key for microservices (min 32 chars)
- [ ] Set appropriate CORS origin for production
- [ ] Review rate limiting needs

## Deployment Steps

### 1. Install Dependencies
```bash
npm install
```

### 2. Login to Cloudflare
```bash
npx wrangler login
```

### 3. Create KV Namespace
```bash
# Create production namespace
npm run kv:create

# Create preview namespace for staging
npm run kv:create-preview
```

Update `wrangler.toml` with the KV namespace IDs returned from above commands.

### 4. Configure Secrets

```bash
# Required secrets
wrangler secret put NOTION_API_KEY
# Enter: secret_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

wrangler secret put NOTION_DATABASE_ID  
# Enter: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

wrangler secret put API_KEY
# Enter: your-strong-api-key-min-32-chars

# Optional platform secrets
wrangler secret put YOUTUBE_API_KEY
wrangler secret put TWITCH_CLIENT_ID
wrangler secret put TWITCH_CLIENT_SECRET
wrangler secret put FACEBOOK_ACCESS_TOKEN
```

### 5. Configure Production Variables

Edit `wrangler.toml`:
```toml
[env.production]
vars = { 
  ENVIRONMENT = "production",
  CORS_ORIGIN = "https://your-streamwall-domain.com"  # Set your actual domain
}
route = "api.yourdomain.com/*"  # Your API domain
zone_id = "your-cloudflare-zone-id"  # From Cloudflare dashboard
```

### 6. Deploy to Production

```bash
# Deploy to production environment
wrangler deploy --env production

# Or just deploy (uses default environment)
wrangler deploy
```

### 7. Verify Deployment

```bash
# Test the API
curl https://your-worker.workers.dev/api/streams

# Check worker logs
wrangler tail --env production
```

## Custom Domain Setup

### 1. Add Custom Domain in Cloudflare Dashboard
1. Go to Workers & Pages > your-worker
2. Settings > Triggers
3. Add Custom Domain
4. Enter: api.yourdomain.com

### 2. Or Use Routes (Advanced)
1. In `wrangler.toml`, uncomment and set:
   ```toml
   route = "api.yourdomain.com/*"
   zone_id = "your-zone-id"
   ```
2. Deploy: `wrangler deploy --env production`

## Monitoring & Analytics

### 1. Enable Analytics Engine (Optional)
```toml
[[analytics_engine_datasets]]
binding = "ANALYTICS"
```

Then in your code:
```javascript
// Track API usage
env.ANALYTICS.writeDataPoint({
  blobs: ['list-streams', request.headers.get('CF-Connecting-IP')],
  doubles: [1]
});
```

### 2. View Metrics
- Workers & Pages > your-worker > Analytics
- Monitor requests, errors, and performance

### 3. Set Up Alerts
1. Go to Notifications in Cloudflare Dashboard
2. Create alert for:
   - Error rate > 1%
   - Average CPU time > 50ms
   - Request rate anomalies

## Security Best Practices

### 1. API Key Rotation
```bash
# Rotate API key quarterly
wrangler secret put API_KEY
# Enter new key, then update all microservices
```

### 2. Rate Limiting
Consider adding rate limiting with Cloudflare Rate Limiting Rules:
- 100 requests per minute per IP for public endpoints
- 1000 requests per minute per API key for authenticated endpoints

### 3. CORS Configuration
Always set specific origins in production:
```javascript
const corsHeaders = {
  'Access-Control-Allow-Origin': env.CORS_ORIGIN || 'https://streamwall.com',
  // ...
};
```

## Performance Optimization

### 1. Cache Configuration
- Current: 30-second cache for active streams
- Adjust based on your needs:
  ```javascript
  const CACHE_TTL = env.CACHE_TTL || 30; // seconds
  ```

### 2. KV Optimization
- Use `cacheTtl` parameter for frequently accessed data
- Consider using Durable Objects for real-time features

### 3. Response Compression
Cloudflare automatically compresses responses, but ensure:
- JSON responses are minified
- Large responses are paginated

## Troubleshooting

### Common Issues

1. **"Notion API Error"**
   - Check API key is correct
   - Verify database is shared with integration
   - Check Notion API status

2. **"Unauthorized" errors**
   - Verify API_KEY secret is set
   - Check Authorization header format: `Bearer YOUR_KEY`

3. **Slow responses**
   - Check cache hit rate in logs
   - Verify KV namespace is configured
   - Monitor Notion API response times

### Debug Commands

```bash
# View real-time logs
wrangler tail --env production

# Test locally with production config
wrangler dev --env production

# Check secret configuration
wrangler secret list
```

## Rollback Procedure

```bash
# List deployments
wrangler deployments list

# Rollback to previous version
wrangler rollback [deployment-id]
```

## Microservice Deployment

Deploy the monitoring service:

```bash
# On your monitoring server
git clone <repo>
cd cloudflare-worker/monitoring

# Install dependencies
npm install

# Configure environment
export STREAMSOURCE_API_URL=https://api.yourdomain.com
export STREAMSOURCE_API_KEY=your-api-key
export YOUTUBE_API_KEY=your-youtube-key
# ... other platform keys

# Run with PM2 (recommended)
pm2 start stream-monitor.js --name streamsource-monitor

# Or with systemd
# Copy the provided systemd service file and enable it
```

## Maintenance

### Regular Tasks
- [ ] Weekly: Check error logs and metrics
- [ ] Monthly: Review cache hit rates
- [ ] Quarterly: Rotate API keys
- [ ] Yearly: Review and update dependencies

### Backup Strategy
Since Notion is your database:
1. Use Notion's built-in version history
2. Export database weekly via Notion UI
3. Consider implementing automated backups via Notion API

## Support

For issues:
1. Check worker logs: `wrangler tail`
2. Review Cloudflare status page
3. Check Notion API status
4. Review this guide's troubleshooting section

Remember: The worker is stateless. All data lives in Notion, and the KV store is just a cache.