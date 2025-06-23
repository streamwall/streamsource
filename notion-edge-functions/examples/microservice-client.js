// Example microservice client for updating stream status
class StreamSourceClient {
  constructor(apiUrl, apiKey) {
    this.apiUrl = apiUrl;
    this.apiKey = apiKey;
  }

  // Update stream status (called by monitoring service)
  async updateStreamStatus(streamId, status, viewerCount = null) {
    const response = await fetch(`${this.apiUrl}/api/streams/${streamId}`, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        status,
        viewerCount,
        ...(status === 'ended' && { endedAt: new Date().toISOString() })
      })
    });

    return response.json();
  }

  // Archive stream with video URL
  async archiveStream(streamId, archiveUrl) {
    const response = await fetch(`${this.apiUrl}/api/streams/${streamId}/archive`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        archiveUrl,
        endedAt: new Date().toISOString()
      })
    });

    return response.json();
  }

  // Get active streams (public endpoint)
  async getActiveStreams() {
    const response = await fetch(`${this.apiUrl}/api/streams`);
    return response.json();
  }
}

// Usage example
const client = new StreamSourceClient('https://your-app.vercel.app', 'your-api-key');

// Monitor streams and update status
async function monitorStreams() {
  const { streams } = await client.getActiveStreams();
  
  for (const stream of streams) {
    // Check if stream is still live (platform-specific logic)
    const isLive = await checkStreamHealth(stream.link);
    
    if (!isLive) {
      await client.updateStreamStatus(stream.id, 'ended');
    } else {
      // Update viewer count if available
      const viewerCount = await getViewerCount(stream.link);
      await client.updateStreamStatus(stream.id, 'live', viewerCount);
    }
  }
}

// Archive completed streams
async function archiveCompletedStream(streamId, videoUrl) {
  await client.archiveStream(streamId, videoUrl);
  console.log(`Stream ${streamId} archived with video: ${videoUrl}`);
}

// Platform-specific health check (implement based on platform APIs)
async function checkStreamHealth(streamUrl) {
  // Implement platform-specific logic
  // For Twitch: Use Twitch API
  // For YouTube: Use YouTube API
  // etc.
  return true; // placeholder
}

async function getViewerCount(streamUrl) {
  // Implement platform-specific logic
  return Math.floor(Math.random() * 1000); // placeholder
}