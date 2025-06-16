import promBundle from 'express-prom-bundle';
import * as promClient from 'prom-client';

// Create custom metrics
export const streamCounter = new promClient.Counter({
  name: 'streams_created_total',
  help: 'Total number of streams created',
  labelNames: ['platform', 'status']
});

export const activeStreamsGauge = new promClient.Gauge({
  name: 'streams_active',
  help: 'Number of active streams',
  labelNames: ['platform']
});

export const authAttempts = new promClient.Counter({
  name: 'auth_attempts_total',
  help: 'Total number of authentication attempts',
  labelNames: ['type', 'success']
});

// Prometheus middleware with custom metrics
export const metricsMiddleware = promBundle({
  includeMethod: true,
  includePath: true,
  includeStatusCode: true,
  includeUp: true,
  customLabels: { app: 'streamsource' },
  promClient: {
    collectDefaultMetrics: {
      prefix: 'streamsource_'
    }
  }
});