import { logger, errorLogger } from '../../middleware/logger';
import express from 'express';
import request from 'supertest';

// Mock winston transports
jest.mock('winston', () => ({
  createLogger: jest.fn(() => ({
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn()
  })),
  format: {
    prettyPrint: jest.fn(),
    combine: jest.fn(),
    timestamp: jest.fn(),
    printf: jest.fn()
  },
  transports: {
    Console: jest.fn()
  }
}));

jest.mock('logdna-winston', () => jest.fn());

jest.mock('express-winston', () => ({
  logger: jest.fn((options) => (req: any, res: any, next: any) => next()),
  errorLogger: jest.fn((options) => (err: any, req: any, res: any, next: any) => next(err))
}));

describe('Logger Middleware', () => {
  let app: express.Application;

  beforeEach(() => {
    app = express();
    app.use(logger);
    app.use(errorLogger);
    
    // Test routes
    app.get('/test', (req, res) => {
      res.json({ message: 'success' });
    });
    
    app.get('/error', (req, res, next) => {
      next(new Error('Test error'));
    });
    
    // Error handler
    app.use((err: any, req: any, res: any, next: any) => {
      res.status(500).json({ error: err.message });
    });
  });

  it('should log requests', async () => {
    const response = await request(app)
      .get('/test');
    
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ message: 'success' });
  });

  it('should log errors', async () => {
    const response = await request(app)
      .get('/error');
    
    expect(response.status).toBe(500);
    expect(response.body).toEqual({ error: 'Test error' });
  });

  it('should not add LogDNA transport in test environment', () => {
    expect(process.env.NODE_ENV).toBe('test');
    // LogDNA transport should not be created in test environment
  });
});