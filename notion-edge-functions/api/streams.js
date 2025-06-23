import { Client } from '@notionhq/client';

const notion = new Client({ auth: process.env.NOTION_API_KEY });
const databaseId = process.env.NOTION_DATABASE_ID;

// CORS headers for Streamwall
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Content-Type': 'application/json',
};

export const config = {
  runtime: 'edge',
};

export default async function handler(request) {
  // Handle CORS preflight
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  const url = new URL(request.url);
  const pathParts = url.pathname.split('/').filter(Boolean);

  try {
    // GET /api/streams - List active streams
    if (request.method === 'GET' && pathParts.length === 2) {
      const response = await notion.databases.query({
        database_id: databaseId,
        filter: {
          property: 'Status',
          select: { equals: 'live' }
        },
        sorts: [
          {
            property: 'Started At',
            direction: 'descending'
          }
        ]
      });

      const streams = response.results.map(page => transformNotionToStreamwall(page));
      
      return new Response(JSON.stringify({ streams }), {
        status: 200,
        headers: corsHeaders
      });
    }

    // PATCH /api/streams/:id - Update stream (for microservices)
    if (request.method === 'PATCH' && pathParts.length === 3) {
      // Check API key for microservice authentication
      const apiKey = request.headers.get('Authorization')?.replace('Bearer ', '');
      if (apiKey !== process.env.API_KEY) {
        return new Response(JSON.stringify({ error: 'Unauthorized' }), {
          status: 401,
          headers: corsHeaders
        });
      }

      const streamId = pathParts[2];
      const body = await request.json();
      
      const properties = {};
      
      if (body.status) {
        properties['Status'] = { select: { name: body.status } };
      }
      
      if (body.viewerCount !== undefined) {
        properties['Viewer Count'] = { number: body.viewerCount };
      }
      
      if (body.endedAt) {
        properties['Ended At'] = { date: { start: body.endedAt } };
      }
      
      // Update last health check
      properties['Last Health Check'] = { date: { start: new Date().toISOString() } };

      await notion.pages.update({
        page_id: streamId,
        properties
      });

      return new Response(JSON.stringify({ success: true }), {
        status: 200,
        headers: corsHeaders
      });
    }

    // POST /api/streams/:id/archive - Archive stream with video links
    if (request.method === 'POST' && pathParts.length === 4 && pathParts[3] === 'archive') {
      const apiKey = request.headers.get('Authorization')?.replace('Bearer ', '');
      if (apiKey !== process.env.API_KEY) {
        return new Response(JSON.stringify({ error: 'Unauthorized' }), {
          status: 401,
          headers: corsHeaders
        });
      }

      const streamId = pathParts[2];
      const body = await request.json();
      
      // Get existing archive links
      const page = await notion.pages.retrieve({ page_id: streamId });
      const existingLinks = page.properties['Archive Links']?.rich_text?.[0]?.plain_text || '[]';
      const archiveLinks = JSON.parse(existingLinks);
      
      // Add new archive link
      if (body.archiveUrl) {
        archiveLinks.push({
          url: body.archiveUrl,
          addedAt: new Date().toISOString()
        });
      }

      await notion.pages.update({
        page_id: streamId,
        properties: {
          'Status': { select: { name: 'archived' } },
          'Archive Links': { 
            rich_text: [{ text: { content: JSON.stringify(archiveLinks) } }] 
          },
          'Ended At': { date: { start: body.endedAt || new Date().toISOString() } }
        }
      });

      return new Response(JSON.stringify({ success: true }), {
        status: 200,
        headers: corsHeaders
      });
    }

    return new Response(JSON.stringify({ error: 'Not found' }), {
      status: 404,
      headers: corsHeaders
    });

  } catch (error) {
    console.error('Notion API error:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: corsHeaders
    });
  }
}

// Transform Notion page to Streamwall format
function transformNotionToStreamwall(page) {
  const props = page.properties;
  
  return {
    id: page.id,
    title: props['Title']?.rich_text?.[0]?.plain_text || props['Stream ID']?.title?.[0]?.plain_text || '',
    link: props['Stream URL']?.url || '',
    embed: props['Embed URL']?.url || props['Stream URL']?.url || '',
    platform: props['Platform']?.select?.name || 'unknown',
    description: props['Notes']?.rich_text?.[0]?.plain_text || '',
    location: parseLocation(props['Location']?.rich_text?.[0]?.plain_text),
    latitude: props['Latitude']?.number || null,
    longitude: props['Longitude']?.number || null,
    startTime: props['Started At']?.date?.start || null,
    endTime: props['Ended At']?.date?.start || null,
    viewerCount: props['Viewer Count']?.number || 0,
    isPinned: props['Is Featured']?.checkbox || false,
    tags: props['Tags']?.multi_select?.map(tag => tag.name) || [],
    lastUpdated: page.last_edited_time
  };
}

function parseLocation(locationString) {
  if (!locationString) return { city: null, state: null };
  
  const parts = locationString.split(',').map(s => s.trim());
  return {
    city: parts[0] || null,
    state: parts[1] || null
  };
}