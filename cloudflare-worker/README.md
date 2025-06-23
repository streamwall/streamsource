# StreamSource Cloudflare Worker

A lightweight livestream management API using Notion as database and Cloudflare Workers for the API layer.

## Why Cloudflare Workers?

- **Global edge network**: Sub-50ms response times worldwide
- **No cold starts**: Always warm, instant responses
- **Generous free tier**: 100,000 requests/day free
- **Built-in KV storage**: Fast caching without Redis
- **Simple deployment**: One command to deploy globally
- **No servers to manage**: True serverless

## Quick Start

### 1. Setup Notion

1. Create a Notion integration at https://www.notion.so/my-integrations
2. Create a new database in Notion with this schema:

```
- Stream ID (title)
- Title (text)
- Platform (select: twitch, youtube, facebook, instagram, tiktok)
- Status (select: live, offline, ended, archived)
- Stream URL (url)
- Embed URL (url)
- Location (text)
- Latitude (number)
- Longitude (number)
- Started At (date with time)
- Ended At (date with time)
- Is Featured (checkbox)
- Viewer Count (number)
- Tags (multi-select)
- Notes (text)
- Last Health Check (date with time)
- Archive Links (text - stores JSON)
```

3. Share the database with your integration

### 2. Deploy to Cloudflare

```bash
# Clone and setup
git clone <your-repo>
cd cloudflare-worker
npm install

# Login to Cloudflare
npx wrangler login

# Create KV namespace for caching
npm run kv:create
npm run kv:create-preview

# Update wrangler.toml with the KV namespace IDs from above commands

# Set secrets
npm run secret:notion      # Enter your Notion API key
npm run secret:database    # Enter your Notion database ID
npm run secret:api         # Enter your API key for microservices

# Deploy
npm run deploy
```

### 3. Test the API

```bash
# List active streams
curl https://your-worker.workers.dev/api/streams

# Update stream status (requires API key)
curl -X PATCH https://your-worker.workers.dev/api/streams/STREAM_ID \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"status": "ended", "viewerCount": 1523}'

# Archive stream
curl -X POST https://your-worker.workers.dev/api/streams/STREAM_ID/archive \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"archiveUrl": "https://youtube.com/watch?v=xxx"}'
```

## API Documentation

### Public Endpoints

#### GET /api/streams
Returns all active (live) streams in Streamwall-compatible format.

**Response:**
```json
{
  "streams": [
    {
      "id": "notion-page-id",
      "title": "Breaking News Stream",
      "link": "https://youtube.com/watch?v=xxx",
      "embed": "https://youtube.com/embed/xxx",
      "platform": "youtube",
      "description": "Live coverage of...",
      "location": {
        "city": "New York",
        "state": "NY"
      },
      "latitude": 40.7128,
      "longitude": -74.0060,
      "startTime": "2024-01-20T15:30:00Z",
      "viewerCount": 1523,
      "isPinned": true,
      "tags": ["news", "breaking"],
      "lastUpdated": "2024-01-20T16:45:00Z"
    }
  ]
}
```

### Protected Endpoints (Require API Key)

#### PATCH /api/streams/:id
Update stream status and metrics.

**Headers:**
```
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json
```

**Body:**
```json
{
  "status": "live|offline|ended|archived",
  "viewerCount": 1234,
  "endedAt": "2024-01-20T17:00:00Z"
}
```

#### POST /api/streams/:id/archive
Archive a stream and add video URL.

**Headers:**
```
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json
```

**Body:**
```json
{
  "archiveUrl": "https://youtube.com/watch?v=xxx",
  "endedAt": "2024-01-20T17:00:00Z"
}
```

## Development

```bash
# Start local dev server
npm run dev

# View logs
npm run tail

# Deploy to production
npm run deploy
```

## Performance

- **Caching**: Active streams cached for 30 seconds in KV
- **Response time**: <50ms globally (after cache warm)
- **Rate limits**: 100k requests/day on free tier
- **Notion limits**: 3 requests/second

## Cost

**Free tier includes:**
- 100,000 requests per day
- 10ms CPU time per request
- Unlimited KV reads
- 1,000 KV writes per day

For most use cases, this will run completely free.

## Monitoring

View metrics in Cloudflare dashboard:
1. Workers & Pages > your-worker
2. View metrics, logs, and errors
3. Set up alerts for errors

## Integration Examples

### Streamwall Configuration
```javascript
// In Streamwall config
const STREAM_SOURCE_URL = 'https://your-worker.workers.dev/api/streams';
```

### Microservice Health Checker
```javascript
setInterval(async () => {
  const streams = await getActiveStreams();
  
  for (const stream of streams) {
    const isLive = await checkPlatformAPI(stream.link);
    
    if (!isLive) {
      await updateStreamStatus(stream.id, 'ended');
    }
  }
}, 60000); // Check every minute
```

## Troubleshooting

### "Notion API Error"
- Verify your Notion API key is correct
- Ensure database is shared with integration
- Check Notion API status

### "Unauthorized"
- Verify API_KEY is set correctly
- Include "Bearer " prefix in Authorization header

### Cache not updating
- Cache TTL is 30 seconds
- Force refresh by updating any stream
- Check KV namespace binding in wrangler.toml