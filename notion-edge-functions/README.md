# StreamSource Notion Integration

A lightweight livestream management system using Notion as the database/UI and edge functions for the API.

## Architecture

- **Database & UI**: Notion (for streamers to manage content)
- **API Layer**: Vercel Edge Functions or Cloudflare Workers
- **Authentication**: API keys for microservices
- **Consumer**: Streamwall (https://github.com/streamwall/streamwall)

## Features

- ✅ No infrastructure to manage
- ✅ Built-in UI via Notion
- ✅ Real-time collaboration
- ✅ Mobile apps (iOS/Android)
- ✅ Version history and audit logs
- ✅ Minimal code to maintain
- ✅ Cost-effective (pay per request)

## API Endpoints

- `GET /api/streams` - List active streams (Streamwall compatible)
- `GET /api/streams/:id` - Get single stream
- `PATCH /api/streams/:id` - Update stream status
- `POST /api/streams/:id/archive` - Archive a stream
- `POST /api/streams` - Create new stream

## Setup

1. Create Notion integration at https://www.notion.so/my-integrations
2. Create database in Notion using provided schema
3. Deploy functions to Vercel/Cloudflare
4. Configure environment variables
5. Share Notion database with integration

## Environment Variables

```
NOTION_API_KEY=secret_xxx
NOTION_DATABASE_ID=xxx
API_KEY=your-api-key-for-microservices
```