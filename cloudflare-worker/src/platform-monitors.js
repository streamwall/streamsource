/**
 * Production-ready platform-specific monitoring functions
 * These check stream health and fetch viewer counts for various platforms
 */

// Platform-specific regex patterns for extracting IDs
const PLATFORM_PATTERNS = {
  youtube: {
    video: /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\s]+)/,
    channel: /youtube\.com\/(?:c\/|channel\/|user\/)([^\/\s]+)/
  },
  twitch: {
    channel: /twitch\.tv\/([^\/\s]+)/,
    video: /twitch\.tv\/videos\/(\d+)/
  },
  facebook: {
    video: /facebook\.com\/(?:watch\/?\?v=|videos\/)(\d+)/,
    live: /facebook\.com\/([^\/]+)\/(?:live|videos)/
  },
  instagram: {
    live: /instagram\.com\/([^\/]+)\/live/,
    tv: /instagram\.com\/tv\/([^\/]+)/
  },
  tiktok: {
    user: /tiktok\.com\/@([^\/]+)/,
    video: /tiktok\.com\/@[^\/]+\/video\/(\d+)/
  }
};

/**
 * Check if a stream is live and get viewer count
 * @param {string} streamUrl - The stream URL
 * @param {string} platform - The platform name
 * @param {Object} env - Cloudflare environment with API keys
 * @returns {Promise<{isLive: boolean, viewerCount: number|null, error: string|null}>}
 */
export async function checkStreamHealth(streamUrl, platform, env) {
  try {
    switch (platform?.toLowerCase()) {
      case 'youtube':
        return await checkYouTubeStream(streamUrl, env);
      case 'twitch':
        return await checkTwitchStream(streamUrl, env);
      case 'facebook':
        return await checkFacebookStream(streamUrl, env);
      case 'instagram':
        return await checkInstagramStream(streamUrl, env);
      case 'tiktok':
        return await checkTikTokStream(streamUrl, env);
      default:
        // For unknown platforms, assume live but no viewer count
        return { isLive: true, viewerCount: null, error: 'Unknown platform' };
    }
  } catch (error) {
    console.error(`Health check failed for ${platform}:`, error);
    return { isLive: false, viewerCount: null, error: error.message };
  }
}

/**
 * YouTube Live Stream Check
 */
async function checkYouTubeStream(streamUrl, env) {
  if (!env.YOUTUBE_API_KEY) {
    return { isLive: true, viewerCount: null, error: 'YouTube API key not configured' };
  }

  const videoMatch = streamUrl.match(PLATFORM_PATTERNS.youtube.video);
  if (!videoMatch) {
    return { isLive: false, viewerCount: null, error: 'Invalid YouTube URL' };
  }

  const videoId = videoMatch[1];
  
  try {
    const response = await fetch(
      `https://www.googleapis.com/youtube/v3/videos?part=liveStreamingDetails,statistics&id=${videoId}&key=${env.YOUTUBE_API_KEY}`
    );
    
    if (!response.ok) {
      throw new Error(`YouTube API error: ${response.status}`);
    }

    const data = await response.json();
    
    if (!data.items || data.items.length === 0) {
      return { isLive: false, viewerCount: null, error: 'Video not found' };
    }

    const video = data.items[0];
    const liveDetails = video.liveStreamingDetails;
    const stats = video.statistics;

    // Check if currently live
    const isLive = liveDetails && 
                   liveDetails.actualStartTime && 
                   !liveDetails.actualEndTime;

    const viewerCount = isLive && liveDetails.concurrentViewers 
                        ? parseInt(liveDetails.concurrentViewers) 
                        : (stats.viewCount ? parseInt(stats.viewCount) : null);

    return { isLive, viewerCount, error: null };
  } catch (error) {
    return { isLive: false, viewerCount: null, error: error.message };
  }
}

/**
 * Twitch Stream Check
 */
async function checkTwitchStream(streamUrl, env) {
  if (!env.TWITCH_CLIENT_ID || !env.TWITCH_CLIENT_SECRET) {
    return { isLive: true, viewerCount: null, error: 'Twitch API credentials not configured' };
  }

  const channelMatch = streamUrl.match(PLATFORM_PATTERNS.twitch.channel);
  if (!channelMatch) {
    return { isLive: false, viewerCount: null, error: 'Invalid Twitch URL' };
  }

  const channelName = channelMatch[1];

  try {
    // Get OAuth token
    const tokenResponse = await fetch('https://id.twitch.tv/oauth2/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: env.TWITCH_CLIENT_ID,
        client_secret: env.TWITCH_CLIENT_SECRET,
        grant_type: 'client_credentials'
      })
    });

    if (!tokenResponse.ok) {
      throw new Error('Failed to get Twitch token');
    }

    const { access_token } = await tokenResponse.json();

    // Check stream status
    const streamResponse = await fetch(
      `https://api.twitch.tv/helix/streams?user_login=${channelName}`,
      {
        headers: {
          'Client-ID': env.TWITCH_CLIENT_ID,
          'Authorization': `Bearer ${access_token}`
        }
      }
    );

    if (!streamResponse.ok) {
      throw new Error(`Twitch API error: ${streamResponse.status}`);
    }

    const { data } = await streamResponse.json();
    
    if (data && data.length > 0) {
      const stream = data[0];
      return {
        isLive: stream.type === 'live',
        viewerCount: stream.viewer_count,
        error: null
      };
    }

    return { isLive: false, viewerCount: null, error: null };
  } catch (error) {
    return { isLive: false, viewerCount: null, error: error.message };
  }
}

/**
 * Facebook Stream Check
 * Note: Facebook's API is restrictive; this is a best-effort implementation
 */
async function checkFacebookStream(streamUrl, env) {
  if (!env.FACEBOOK_ACCESS_TOKEN) {
    return { isLive: true, viewerCount: null, error: 'Facebook API token not configured' };
  }

  // Facebook live video detection is complex due to API restrictions
  // This is a simplified implementation
  const videoMatch = streamUrl.match(PLATFORM_PATTERNS.facebook.video);
  if (!videoMatch) {
    return { isLive: true, viewerCount: null, error: 'Cannot parse Facebook URL' };
  }

  const videoId = videoMatch[1];

  try {
    const response = await fetch(
      `https://graph.facebook.com/v18.0/${videoId}?fields=live_status,live_views&access_token=${env.FACEBOOK_ACCESS_TOKEN}`
    );

    if (!response.ok) {
      // Facebook often restricts access; assume live if we can't check
      return { isLive: true, viewerCount: null, error: 'Facebook API restricted' };
    }

    const data = await response.json();
    
    return {
      isLive: data.live_status === 'LIVE',
      viewerCount: data.live_views || null,
      error: null
    };
  } catch (error) {
    return { isLive: true, viewerCount: null, error: error.message };
  }
}

/**
 * Instagram Stream Check
 * Note: Instagram's API is very restrictive for live content
 */
async function checkInstagramStream(streamUrl, env) {
  // Instagram doesn't provide public API for live streams
  // Best we can do is assume it's live if it's in the database
  return { 
    isLive: true, 
    viewerCount: null, 
    error: 'Instagram API does not support live stream checks' 
  };
}

/**
 * TikTok Stream Check
 * Note: TikTok's API is limited for live content
 */
async function checkTikTokStream(streamUrl, env) {
  // TikTok doesn't provide easy API access for live streams
  // Assume live if URL is valid
  const userMatch = streamUrl.match(PLATFORM_PATTERNS.tiktok.user);
  if (!userMatch) {
    return { isLive: false, viewerCount: null, error: 'Invalid TikTok URL' };
  }

  return { 
    isLive: true, 
    viewerCount: null, 
    error: 'TikTok API does not support live stream checks' 
  };
}

/**
 * Generate thumbnail URL for a stream
 * @param {string} streamUrl - The stream URL
 * @param {string} platform - The platform name
 * @returns {string|null} Thumbnail URL or null
 */
export function generateThumbnailUrl(streamUrl, platform) {
  try {
    switch (platform?.toLowerCase()) {
      case 'youtube': {
        const match = streamUrl.match(PLATFORM_PATTERNS.youtube.video);
        if (match) {
          const videoId = match[1];
          // Use maxresdefault for best quality, with fallbacks
          return `https://i.ytimg.com/vi/${videoId}/maxresdefault.jpg`;
        }
        break;
      }
      
      case 'twitch': {
        const match = streamUrl.match(PLATFORM_PATTERNS.twitch.channel);
        if (match) {
          const channel = match[1];
          // Twitch preview images update every few minutes
          const timestamp = Math.floor(Date.now() / 300000) * 300000; // 5-min cache
          return `https://static-cdn.jtvnw.net/previews-ttv/live_user_${channel}-1280x720.jpg?t=${timestamp}`;
        }
        break;
      }
      
      case 'facebook': {
        // Facebook doesn't provide easy thumbnail access
        return null;
      }
      
      case 'instagram': {
        // Instagram doesn't provide public thumbnail access
        return null;
      }
      
      case 'tiktok': {
        // TikTok doesn't provide easy thumbnail access
        return null;
      }
    }
  } catch (error) {
    console.error('Thumbnail generation error:', error);
  }
  
  return null;
}

/**
 * Extract clean embed URL for iframe embedding
 * @param {string} streamUrl - The stream URL
 * @param {string} platform - The platform name
 * @returns {string|null} Embed URL or null
 */
export function generateEmbedUrl(streamUrl, platform) {
  try {
    switch (platform?.toLowerCase()) {
      case 'youtube': {
        const match = streamUrl.match(PLATFORM_PATTERNS.youtube.video);
        if (match) {
          const videoId = match[1];
          return `https://www.youtube.com/embed/${videoId}?autoplay=1&mute=1`;
        }
        break;
      }
      
      case 'twitch': {
        const match = streamUrl.match(PLATFORM_PATTERNS.twitch.channel);
        if (match) {
          const channel = match[1];
          return `https://player.twitch.tv/?channel=${channel}&parent=${new URL(streamUrl).hostname}&muted=true`;
        }
        break;
      }
      
      case 'facebook': {
        // Facebook embeds require the full URL
        return `https://www.facebook.com/plugins/video.php?href=${encodeURIComponent(streamUrl)}&show_text=false&mute=1`;
      }
      
      case 'instagram': {
        // Instagram doesn't support live embeds
        return null;
      }
      
      case 'tiktok': {
        // TikTok embed support is limited
        return null;
      }
    }
  } catch (error) {
    console.error('Embed URL generation error:', error);
  }
  
  return streamUrl; // Fallback to original URL
}