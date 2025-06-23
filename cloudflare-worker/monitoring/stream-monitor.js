#!/usr/bin/env node

/**
 * Production Stream Monitoring Service
 * Monitors live streams and updates their status via the StreamSource API
 */

import { checkStreamHealth } from '../src/platform-monitors.js';

class StreamMonitor {
  constructor(config) {
    this.apiUrl = config.apiUrl;
    this.apiKey = config.apiKey;
    this.checkInterval = config.checkInterval || 60000; // 1 minute default
    this.platformKeys = config.platformKeys || {};
    this.isRunning = false;
    this.healthChecks = new Map(); // Track last check time per stream
  }

  async start() {
    console.log('🚀 Starting Stream Monitor Service');
    console.log(`API URL: ${this.apiUrl}`);
    console.log(`Check interval: ${this.checkInterval}ms`);
    
    this.isRunning = true;
    
    // Initial check
    await this.checkAllStreams();
    
    // Set up interval
    this.interval = setInterval(() => {
      if (this.isRunning) {
        this.checkAllStreams().catch(console.error);
      }
    }, this.checkInterval);
  }

  stop() {
    console.log('🛑 Stopping Stream Monitor Service');
    this.isRunning = false;
    if (this.interval) {
      clearInterval(this.interval);
    }
  }

  async checkAllStreams() {
    try {
      console.log(`\n⏰ ${new Date().toISOString()} - Checking streams...`);
      
      // Fetch active streams
      const response = await fetch(`${this.apiUrl}/api/streams`);
      if (!response.ok) {
        throw new Error(`Failed to fetch streams: ${response.status}`);
      }
      
      const { streams } = await response.json();
      console.log(`📊 Found ${streams.length} active streams`);
      
      // Check each stream in parallel (with concurrency limit)
      const BATCH_SIZE = 5;
      for (let i = 0; i < streams.length; i += BATCH_SIZE) {
        const batch = streams.slice(i, i + BATCH_SIZE);
        await Promise.all(batch.map(stream => this.checkStream(stream)));
      }
      
      // Clean up old health checks
      this.cleanupHealthChecks(streams);
      
    } catch (error) {
      console.error('❌ Error checking streams:', error.message);
    }
  }

  async checkStream(stream) {
    const streamKey = `${stream.platform}:${stream.id}`;
    
    // Skip if checked recently (within 30 seconds)
    const lastCheck = this.healthChecks.get(streamKey);
    if (lastCheck && Date.now() - lastCheck < 30000) {
      return;
    }
    
    try {
      console.log(`🔍 Checking ${stream.platform} stream: ${stream.title}`);
      
      // Mock environment object with platform API keys
      const env = {
        YOUTUBE_API_KEY: this.platformKeys.youtube,
        TWITCH_CLIENT_ID: this.platformKeys.twitchClientId,
        TWITCH_CLIENT_SECRET: this.platformKeys.twitchClientSecret,
        FACEBOOK_ACCESS_TOKEN: this.platformKeys.facebook
      };
      
      // Check stream health
      const health = await checkStreamHealth(stream.link, stream.platform, env);
      
      // Prepare update
      const updates = {};
      let needsUpdate = false;
      
      // Update status if stream ended
      if (!health.isLive && stream.endTime === null) {
        updates.status = 'ended';
        updates.endedAt = new Date().toISOString();
        needsUpdate = true;
        console.log(`  📴 Stream ended: ${stream.title}`);
      }
      
      // Update viewer count if changed significantly (>10% change or >100 viewers)
      if (health.viewerCount !== null) {
        const viewerDiff = Math.abs(health.viewerCount - (stream.viewerCount || 0));
        const percentChange = stream.viewerCount ? viewerDiff / stream.viewerCount : 1;
        
        if (viewerDiff > 100 || percentChange > 0.1) {
          updates.viewerCount = health.viewerCount;
          needsUpdate = true;
          console.log(`  👥 Viewers: ${stream.viewerCount || 0} → ${health.viewerCount}`);
        }
      }
      
      // Send update if needed
      if (needsUpdate) {
        await this.updateStream(stream.id, updates);
      } else {
        console.log(`  ✅ No changes needed`);
      }
      
      // Record health check time
      this.healthChecks.set(streamKey, Date.now());
      
      // If stream health check failed, log the error
      if (health.error) {
        console.log(`  ⚠️  Health check warning: ${health.error}`);
      }
      
    } catch (error) {
      console.error(`  ❌ Error checking stream ${stream.id}:`, error.message);
    }
  }

  async updateStream(streamId, updates) {
    try {
      const response = await fetch(`${this.apiUrl}/api/streams/${streamId}`, {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(updates)
      });
      
      if (!response.ok) {
        const error = await response.text();
        throw new Error(`API error ${response.status}: ${error}`);
      }
      
      const result = await response.json();
      console.log(`  ✅ Updated stream ${streamId}`);
      
    } catch (error) {
      console.error(`  ❌ Failed to update stream ${streamId}:`, error.message);
    }
  }

  cleanupHealthChecks(activeStreams) {
    // Remove health checks for streams no longer in the active list
    const activeKeys = new Set(
      activeStreams.map(s => `${s.platform}:${s.id}`)
    );
    
    for (const key of this.healthChecks.keys()) {
      if (!activeKeys.has(key)) {
        this.healthChecks.delete(key);
      }
    }
  }
}

// Archive monitoring service (separate from health monitoring)
class ArchiveMonitor {
  constructor(config) {
    this.apiUrl = config.apiUrl;
    this.apiKey = config.apiKey;
    this.archiveServices = config.archiveServices || {};
  }

  async archiveEndedStream(streamId, platform, streamUrl) {
    console.log(`📦 Archiving stream ${streamId} from ${platform}`);
    
    try {
      // Platform-specific archive URL generation
      let archiveUrl = null;
      
      switch (platform) {
        case 'youtube':
          // YouTube videos remain at the same URL after live ends
          archiveUrl = streamUrl;
          break;
          
        case 'twitch':
          // Would need to use Twitch API to get VOD URL
          archiveUrl = await this.getTwitchVodUrl(streamUrl);
          break;
          
        default:
          console.log(`  ⚠️  No archive strategy for platform: ${platform}`);
          return;
      }
      
      if (archiveUrl) {
        const response = await fetch(`${this.apiUrl}/api/streams/${streamId}/archive`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ archiveUrl })
        });
        
        if (response.ok) {
          console.log(`  ✅ Archived with URL: ${archiveUrl}`);
        } else {
          throw new Error(`Archive failed: ${response.status}`);
        }
      }
      
    } catch (error) {
      console.error(`  ❌ Archive error:`, error.message);
    }
  }
  
  async getTwitchVodUrl(streamUrl) {
    // Implement Twitch VOD lookup
    // This would use Twitch API to find the VOD for a ended stream
    return null; // Placeholder
  }
}

// CLI usage
if (import.meta.url === `file://${process.argv[1]}`) {
  const config = {
    apiUrl: process.env.STREAMSOURCE_API_URL || 'http://localhost:8787',
    apiKey: process.env.STREAMSOURCE_API_KEY || 'test-key',
    checkInterval: parseInt(process.env.CHECK_INTERVAL) || 60000,
    platformKeys: {
      youtube: process.env.YOUTUBE_API_KEY,
      twitchClientId: process.env.TWITCH_CLIENT_ID,
      twitchClientSecret: process.env.TWITCH_CLIENT_SECRET,
      facebook: process.env.FACEBOOK_ACCESS_TOKEN
    }
  };
  
  const monitor = new StreamMonitor(config);
  const archiver = new ArchiveMonitor(config);
  
  // Graceful shutdown
  process.on('SIGINT', () => {
    console.log('\n📴 Received SIGINT, shutting down gracefully...');
    monitor.stop();
    process.exit(0);
  });
  
  // Start monitoring
  monitor.start();
  
  console.log('💡 Stream Monitor is running. Press Ctrl+C to stop.');
}

export { StreamMonitor, ArchiveMonitor };