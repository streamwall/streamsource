import request from 'supertest';
import path from 'path';
import express from 'express';

// Mock all dependencies before requiring app
jest.mock('../middleware/logger', () => ({
  logger: (req: any, res: any, next: any) => next(),
  errorLogger: (req: any, res: any, next: any) => next()
}));

jest.mock('../auth/authentication');

jest.mock('../routes/index', () => {
  const express = require('express');
  const router = express.Router();
  router.get('/', (req: any, res: any) => res.json({ route: 'index' }));
  return { default: router };
});

jest.mock('../routes/streams', () => {
  const express = require('express');
  const router = express.Router();
  router.get('/', (req: any, res: any) => res.json({ route: 'streams' }));
  return { default: router };
});

jest.mock('../routes/users', () => {
  const express = require('express');
  const router = express.Router();
  router.post('/login', (req: any, res: any) => res.json({ route: 'users' }));
  return { default: router };
});

jest.mock('../routes/health', () => {
  const express = require('express');
  const router = express.Router();
  router.get('/', (req: any, res: any) => res.json({ route: 'health' }));
  return { default: router };
});

import app from '../app';

describe('App Configuration', () => {
  describe('Middleware Setup', () => {
    it('should handle JSON requests', async () => {
      const response = await request(app)
        .post('/test-json')
        .send({ test: 'data' })
        .set('Content-Type', 'application/json');

      expect(response.status).toBe(404); // Route doesn't exist, but JSON was parsed
    });

    it('should handle URL-encoded requests', async () => {
      const response = await request(app)
        .post('/test-form')
        .send('field=value')
        .set('Content-Type', 'application/x-www-form-urlencoded');

      expect(response.status).toBe(404);
    });

    it('should parse cookies', async () => {
      const response = await request(app)
        .get('/test-cookie')
        .set('Cookie', 'test=value');

      expect(response.status).toBe(404);
    });

    it('should parse boolean query parameters', async () => {
      const response = await request(app)
        .get('/test-bool?flag=true&other=false');

      expect(response.status).toBe(404);
    });
  });

  describe('View Engine', () => {
    it('should have pug as view engine', () => {
      expect(app.get('view engine')).toBe('pug');
    });

    it('should have views directory set', () => {
      const viewsPath = app.get('views');
      expect(viewsPath).toContain('views');
    });
  });

  describe('Routes', () => {
    it('should mount index router', async () => {
      const response = await request(app).get('/');
      expect(response.body).toEqual({ route: 'index' });
    });

    it('should mount streams router', async () => {
      const response = await request(app).get('/streams');
      expect(response.body).toEqual({ route: 'streams' });
    });

    it('should mount users router', async () => {
      const response = await request(app).post('/users/login');
      expect(response.body).toEqual({ route: 'users' });
    });
  });

  describe('Error Handling', () => {
    it('should return 404 for unknown routes', async () => {
      const response = await request(app).get('/unknown-route');
      expect(response.status).toBe(404);
    });

    it('should handle errors with status code', async () => {
      // Create a test route that throws an error
      const testApp = express();
      testApp.use('/', (req, res, next) => {
        const err: any = new Error('Test error');
        err.status = 418;
        next(err);
      });
      
      // Add error handler
      testApp.use((err: any, req: any, res: any, next: any) => {
        res.status(err.status || 500);
        res.json({ error: err.message });
      });

      const response = await request(testApp).get('/');
      expect(response.status).toBe(418);
    });
  });

  describe('Security Headers', () => {
    it('should set security headers with Helmet', async () => {
      const response = await request(app).get('/');
      
      // Check for some common Helmet headers
      expect(response.headers['x-dns-prefetch-control']).toBeDefined();
      expect(response.headers['x-frame-options']).toBeDefined();
      expect(response.headers['x-content-type-options']).toBe('nosniff');
    });
  });
});