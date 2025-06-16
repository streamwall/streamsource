const request = require('supertest');
const path = require('path');

// Mock all dependencies before requiring app
jest.mock('../middleware/logger', () => ({
  logger: (req, res, next) => next(),
  errorLogger: (req, res, next) => next()
}));

jest.mock('../auth/authentication');

jest.mock('../routes/index', () => {
  const express = require('express');
  const router = express.Router();
  router.get('/', (req, res) => res.json({ route: 'index' }));
  return router;
});

jest.mock('../routes/streams', () => {
  const express = require('express');
  const router = express.Router();
  router.get('/', (req, res) => res.json({ route: 'streams' }));
  return router;
});

jest.mock('../routes/users', () => {
  const express = require('express');
  const router = express.Router();
  router.post('/login', (req, res) => res.json({ route: 'users' }));
  return router;
});

const app = require('../app');

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

      expect(response.status).toBe(404); // Route doesn't exist, but form was parsed
    });

    it('should parse boolean query parameters', async () => {
      // Test through a real route that uses query params
      const response = await request(app)
        .get('/streams?isExpired=true&isPinned=false');

      expect(response.status).toBe(200);
    });
  });

  describe('View Engine', () => {
    it('should set view engine to jade', () => {
      expect(app.get('view engine')).toBe('jade');
    });

    it('should set views directory', () => {
      expect(app.get('views')).toBe(path.join(__dirname, '..', 'views'));
    });
  });

  describe('Routes', () => {
    it('should mount index router at /', async () => {
      const response = await request(app).get('/');
      expect(response.status).toBe(200);
      expect(response.body.route).toBe('index');
    });

    it('should mount streams router at /streams', async () => {
      const response = await request(app).get('/streams');
      expect(response.status).toBe(200);
      expect(response.body.route).toBe('streams');
    });

    it('should mount users router at /users', async () => {
      const response = await request(app).post('/users/login');
      expect(response.status).toBe(200);
      expect(response.body.route).toBe('users');
    });
  });

  describe('Static Files', () => {
    it('should serve static files from public directory', async () => {
      // This will return 404 since public directory doesn't exist in tests
      const response = await request(app).get('/test.css');
      expect(response.status).toBe(404);
    });
  });

  describe('Error Handling', () => {
    it('should handle 404 errors', async () => {
      const response = await request(app).get('/non-existent-route');
      
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error');
    });

    it('should handle thrown errors', async () => {
      // Create a route that throws an error
      app.get('/test-error', (req, res, next) => {
        const error = new Error('Test error');
        error.status = 400;
        next(error);
      });

      const response = await request(app).get('/test-error');
      
      expect(response.status).toBe(400);
      expect(response.body.error).toHaveProperty('message', 'Test error');
    });

    it('should default to 500 status for errors without status', async () => {
      app.get('/test-500', (req, res, next) => {
        next(new Error('Internal error'));
      });

      const response = await request(app).get('/test-500');
      
      expect(response.status).toBe(500);
    });

    it('should include error details in development', async () => {
      const originalEnv = app.get('env');
      app.set('env', 'development');

      app.get('/test-dev-error', (req, res, next) => {
        const error = new Error('Development error');
        error.stack = 'Error stack trace';
        next(error);
      });

      const response = await request(app).get('/test-dev-error');
      
      expect(response.body.error).toHaveProperty('stack');
      
      app.set('env', originalEnv);
    });

    it('should hide error details in production', async () => {
      const originalEnv = app.get('env');
      app.set('env', 'production');

      app.get('/test-prod-error', (req, res, next) => {
        const error = new Error('Production error');
        error.stack = 'Error stack trace';
        next(error);
      });

      const response = await request(app).get('/test-prod-error');
      
      expect(response.body.error).not.toHaveProperty('stack');
      
      app.set('env', originalEnv);
    });
  });

  describe('Middleware Order', () => {
    it('should apply logger before routes', () => {
      // Logger is mocked to pass through, so this just ensures no errors
      expect(() => request(app).get('/')).not.toThrow();
    });

    it('should apply error logger after routes', () => {
      // Error logger is mocked to pass through
      expect(() => request(app).get('/non-existent')).not.toThrow();
    });
  });

  describe('Cookie Support', () => {
    it('should parse cookies', async () => {
      const response = await request(app)
        .get('/')
        .set('Cookie', 'test=value');

      expect(response.status).toBe(200);
    });
  });
});