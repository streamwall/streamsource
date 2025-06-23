/**
 * StreamSource Cloudflare Worker
 * Lightweight API bridge between Notion database and Streamwall
 */

import { checkStreamHealth, generateThumbnailUrl, generateEmbedUrl } from './platform-monitors.js';

// Input validation schemas
const VALID_PLATFORMS = ['youtube', 'twitch', 'facebook', 'instagram', 'tiktok', 'periscope'];
const VALID_STATUSES = ['live', 'offline', 'ended', 'archived', 'scheduled'];
const MAX_VIEWER_COUNT = 10000000; // 10 million max
const MAX_ARCHIVE_LINKS = 100;

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': env.CORS_ORIGIN || '*',
      'Access-Control-Allow-Methods': 'GET, POST, PATCH, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '86400', // 24 hours
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Route handling
    try {
      // GET /api/streams - List active streams (with caching)
      if (request.method === 'GET' && url.pathname === '/api/streams') {
        return await handleListStreams(env, corsHeaders);
      }

      // PATCH /api/streams/:id - Update stream status
      if (request.method === 'PATCH' && url.pathname.match(/^\/api\/streams\/[\w-]+$/)) {
        const streamId = url.pathname.split('/').pop();
        return await handleUpdateStream(request, env, streamId, corsHeaders);
      }

      // POST /api/streams/:id/archive - Archive stream
      if (request.method === 'POST' && url.pathname.match(/^\/api\/streams\/[\w-]+\/archive$/)) {
        const streamId = url.pathname.split('/')[3];
        return await handleArchiveStream(request, env, streamId, corsHeaders);
      }

      // 404 for unmatched routes
      return new Response(JSON.stringify({ error: 'Not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });

    } catch (error) {
      console.error('Worker error:', error);
      return new Response(JSON.stringify({ error: 'Internal server error' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
  }
};

// List active streams with caching and retry logic
async function handleListStreams(env, corsHeaders) {
  // Try cache first
  const cacheKey = 'active-streams';
  const cached = await env.STREAM_CACHE.get(cacheKey);
  
  if (cached) {
    return new Response(cached, {
      headers: { 
        ...corsHeaders, 
        'Content-Type': 'application/json',
        'X-Cache': 'HIT',
        'Cache-Control': 'public, max-age=30'
      }
    });
  }

  // Fetch from Notion with retry logic
  let lastError;
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      const response = await fetch(`https://api.notion.com/v1/databases/${env.NOTION_DATABASE_ID}/query`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${env.NOTION_API_KEY}`,
          'Notion-Version': '2022-06-28',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          filter: {
            property: 'Status',
            select: { equals: 'live' }
          },
          sorts: [{ property: 'Started At', direction: 'descending' }],
          page_size: 100
        })
      });

      if (response.status === 429) {
        // Rate limited - wait before retry
        const retryAfter = parseInt(response.headers.get('Retry-After') || '1');
        await new Promise(resolve => setTimeout(resolve, retryAfter * 1000));
        continue;
      }

      if (!response.ok) {
        throw new Error(`Notion API error: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();
      
      // Transform and enrich stream data
      const streams = await Promise.all(
        data.results.map(page => transformNotionToStreamwall(page, env))
      );
      
      const responseBody = JSON.stringify({ 
        streams,
        meta: {
          count: streams.length,
          cached_at: new Date().toISOString(),
          cache_ttl: 30
        }
      });

      // Cache for 30 seconds
      await env.STREAM_CACHE.put(cacheKey, responseBody, { expirationTtl: 30 });

      return new Response(responseBody, {
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json',
          'X-Cache': 'MISS',
          'Cache-Control': 'public, max-age=30'
        }
      });
    } catch (error) {
      lastError = error;
      if (attempt < 3) {
        // Exponential backoff
        await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt) * 1000));
      }
    }
  }

  // All retries failed
  throw lastError || new Error('Failed to fetch streams after 3 attempts');
}

// Update stream status (for microservices) with validation
async function handleUpdateStream(request, env, streamId, corsHeaders) {
  // Verify API key
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || authHeader !== `Bearer ${env.API_KEY}`) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }

  // Validate stream ID format
  if (!streamId || !/^[\w-]+$/.test(streamId)) {
    return new Response(JSON.stringify({ error: 'Invalid stream ID format' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }

  let body;
  try {
    body = await request.json();
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }

  const properties = {};
  const errors = [];

  // Validate and set status
  if (body.status) {
    if (!VALID_STATUSES.includes(body.status)) {
      errors.push(`Invalid status: ${body.status}. Must be one of: ${VALID_STATUSES.join(', ')}`);
    } else {
      properties['Status'] = { select: { name: body.status } };
    }
  }
  
  // Validate and set viewer count
  if (body.viewerCount !== undefined) {
    const count = parseInt(body.viewerCount);
    if (isNaN(count) || count < 0 || count > MAX_VIEWER_COUNT) {
      errors.push(`Invalid viewer count: ${body.viewerCount}. Must be between 0 and ${MAX_VIEWER_COUNT}`);
    } else {
      properties['Viewer Count'] = { number: count };
    }
  }
  
  // Validate and set ended time
  if (body.endedAt) {
    const date = new Date(body.endedAt);
    if (isNaN(date.getTime())) {
      errors.push(`Invalid date format for endedAt: ${body.endedAt}`);
    } else {
      properties['Ended At'] = { date: { start: date.toISOString() } };
    }
  }

  if (errors.length > 0) {
    return new Response(JSON.stringify({ error: 'Validation failed', errors }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Update last health check
  properties['Last Health Check'] = { date: { start: new Date().toISOString() } };

  try {
    const response = await fetch(`https://api.notion.com/v1/pages/${streamId}`, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${env.NOTION_API_KEY}`,
        'Notion-Version': '2022-06-28',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ properties })
    });

    if (response.status === 404) {
      return new Response(JSON.stringify({ error: 'Stream not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Notion API error: ${response.status} - ${error}`);
    }

    // Invalidate cache
    await env.STREAM_CACHE.delete('active-streams');

    return new Response(JSON.stringify({ 
      success: true,
      updated: Object.keys(properties).length - 1, // Exclude Last Health Check
      streamId
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Update stream error:', error);
    throw error;
  }
}

// Archive stream with video links
async function handleArchiveStream(request, env, streamId, corsHeaders) {
  // Verify API key
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || authHeader !== `Bearer ${env.API_KEY}`) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }

  const body = await request.json();
  
  // Get existing page to retrieve current archive links
  const pageResponse = await fetch(`https://api.notion.com/v1/pages/${streamId}`, {
    headers: {
      'Authorization': `Bearer ${env.NOTION_API_KEY}`,
      'Notion-Version': '2022-06-28'
    }
  });

  if (!pageResponse.ok) {
    throw new Error(`Notion API error: ${pageResponse.status}`);
  }

  const page = await pageResponse.json();
  const existingLinks = page.properties['Archive Links']?.rich_text?.[0]?.plain_text || '[]';
  const archiveLinks = JSON.parse(existingLinks);
  
  // Add new archive link
  if (body.archiveUrl) {
    archiveLinks.push({
      url: body.archiveUrl,
      addedAt: new Date().toISOString()
    });
  }

  // Update page
  const updateResponse = await fetch(`https://api.notion.com/v1/pages/${streamId}`, {
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${env.NOTION_API_KEY}`,
      'Notion-Version': '2022-06-28',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      properties: {
        'Status': { select: { name: 'archived' } },
        'Archive Links': { 
          rich_text: [{ text: { content: JSON.stringify(archiveLinks) } }] 
        },
        'Ended At': { date: { start: body.endedAt || new Date().toISOString() } }
      }
    })
  });

  if (!updateResponse.ok) {
    throw new Error(`Notion API error: ${updateResponse.status}`);
  }

  // Invalidate cache
  await env.STREAM_CACHE.delete('active-streams');

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

// Transform Notion page to Streamwall format with enrichment
async function transformNotionToStreamwall(page, env) {
  const props = page.properties;
  const platform = props['Platform']?.select?.name || 'unknown';
  const streamUrl = props['Stream URL']?.url || '';
  
  // Generate thumbnail and embed URLs
  const thumbnail = generateThumbnailUrl(streamUrl, platform);
  const embedUrl = generateEmbedUrl(streamUrl, platform);
  
  return {
    id: page.id,
    title: sanitizeText(props['Title']?.rich_text?.[0]?.plain_text || props['Stream ID']?.title?.[0]?.plain_text || ''),
    link: streamUrl,
    embed: embedUrl || props['Embed URL']?.url || streamUrl,
    platform: platform.toLowerCase(),
    description: sanitizeText(props['Notes']?.rich_text?.[0]?.plain_text || ''),
    location: parseLocation(props['Location']?.rich_text?.[0]?.plain_text),
    latitude: validateCoordinate(props['Latitude']?.number, -90, 90),
    longitude: validateCoordinate(props['Longitude']?.number, -180, 180),
    startTime: props['Started At']?.date?.start || null,
    endTime: props['Ended At']?.date?.start || null,
    viewerCount: Math.max(0, props['Viewer Count']?.number || 0),
    isPinned: props['Is Featured']?.checkbox || false,
    tags: props['Tags']?.multi_select?.map(tag => sanitizeText(tag.name)) || [],
    thumbnail,
    lastUpdated: page.last_edited_time,
    lastHealthCheck: props['Last Health Check']?.date?.start || null
  };
}

// Helper functions for validation and sanitization
function sanitizeText(text) {
  if (!text) return '';
  // Remove control characters and trim
  return text.replace(/[\x00-\x1F\x7F]/g, '').trim().substring(0, 1000);
}

function validateCoordinate(value, min, max) {
  if (typeof value !== 'number' || isNaN(value)) return null;
  return Math.max(min, Math.min(max, value));
}

function parseLocation(locationString) {
  if (!locationString) return { city: null, state: null };
  
  const parts = locationString.split(',').map(s => s.trim());
  return {
    city: parts[0] || null,
    state: parts[1] || null
  };
}