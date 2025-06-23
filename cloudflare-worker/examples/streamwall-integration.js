/**
 * Example Streamwall integration with StreamSource Cloudflare Worker
 * This shows how Streamwall can fetch and display active streams
 */

// Streamwall configuration
const STREAMSOURCE_API = 'https://your-worker.workers.dev/api/streams';
const REFRESH_INTERVAL = 30000; // 30 seconds

// Fetch active streams from StreamSource
async function fetchActiveStreams() {
  try {
    const response = await fetch(STREAMSOURCE_API);
    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }
    
    const data = await response.json();
    return data.streams;
  } catch (error) {
    console.error('Failed to fetch streams:', error);
    return [];
  }
}

// Transform StreamSource format to Streamwall format if needed
function transformForStreamwall(streams) {
  return streams.map(stream => ({
    // Streamwall expected format
    id: stream.id,
    title: stream.title,
    link: stream.embed || stream.link, // Prefer embed URL
    type: stream.platform,
    description: stream.description,
    location: stream.location,
    coordinates: {
      lat: stream.latitude,
      lng: stream.longitude
    },
    pinned: stream.isPinned,
    viewers: stream.viewerCount,
    tags: stream.tags,
    startedAt: stream.startTime,
    
    // Additional Streamwall properties
    muted: true, // Start muted
    aspectRatio: '16:9',
    thumbnail: `https://img.youtube.com/vi/${extractVideoId(stream.link)}/maxresdefault.jpg`
  }));
}

// Helper to extract YouTube video ID
function extractVideoId(url) {
  if (!url) return null;
  const match = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\s]+)/);
  return match ? match[1] : null;
}

// Main Streamwall integration
class StreamSourceIntegration {
  constructor() {
    this.streams = [];
    this.updateCallbacks = [];
  }

  // Subscribe to stream updates
  onUpdate(callback) {
    this.updateCallbacks.push(callback);
  }

  // Start fetching streams
  async start() {
    // Initial fetch
    await this.updateStreams();
    
    // Set up periodic updates
    setInterval(() => this.updateStreams(), REFRESH_INTERVAL);
  }

  // Fetch and update streams
  async updateStreams() {
    const rawStreams = await fetchActiveStreams();
    this.streams = transformForStreamwall(rawStreams);
    
    // Notify subscribers
    this.updateCallbacks.forEach(cb => cb(this.streams));
    
    console.log(`Updated ${this.streams.length} active streams`);
  }

  // Get current streams
  getStreams() {
    return this.streams;
  }

  // Get featured/pinned streams
  getFeaturedStreams() {
    return this.streams.filter(s => s.pinned);
  }

  // Get streams by tag
  getStreamsByTag(tag) {
    return this.streams.filter(s => s.tags.includes(tag));
  }

  // Get streams by location
  getStreamsByLocation(city, state) {
    return this.streams.filter(s => 
      s.location.city === city || s.location.state === state
    );
  }
}

// Usage in Streamwall
const streamSource = new StreamSourceIntegration();

// Subscribe to updates
streamSource.onUpdate((streams) => {
  console.log('New streams available:', streams.length);
  // Update Streamwall UI
  updateStreamwallGrid(streams);
});

// Start integration
streamSource.start();

// Example Streamwall UI update function
function updateStreamwallGrid(streams) {
  // Sort streams: featured first, then by viewer count
  const sortedStreams = streams.sort((a, b) => {
    if (a.pinned && !b.pinned) return -1;
    if (!a.pinned && b.pinned) return 1;
    return b.viewers - a.viewers;
  });

  // Render streams in grid
  sortedStreams.forEach(stream => {
    // Create stream tile
    console.log(`Rendering: ${stream.title} (${stream.viewers} viewers)`);
  });
}

// Export for use in Streamwall
export default StreamSourceIntegration;