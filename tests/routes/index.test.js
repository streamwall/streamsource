const request = require('supertest');
const express = require('express');
const path = require('path');

// Create test app
const app = express();

// Set up view engine for testing
app.set('views', path.join(__dirname, '../../views'));
app.set('view engine', 'jade');

// Mock the render method to avoid actual template rendering
app.use((req, res, next) => {
  res.render = jest.fn((view, locals) => {
    res.json({ view, locals });
  });
  next();
});

// Load the router
const indexRouter = require('../../routes/index');
app.use('/', indexRouter);

describe('Index Route', () => {
  describe('GET /', () => {
    it('should render index view with title', async () => {
      const response = await request(app).get('/');

      expect(response.status).toBe(200);
      expect(response.body).toEqual({
        view: 'index',
        locals: {
          title: 'Express'
        }
      });
    });

    it('should handle next parameter', async () => {
      // The route accepts next parameter even though it doesn't use it
      const mockNext = jest.fn();
      const req = { method: 'GET', url: '/' };
      const res = {
        render: jest.fn()
      };

      const route = indexRouter.stack.find(layer => layer.route?.path === '/');
      route.route.stack[0].handle(req, res, mockNext);

      expect(res.render).toHaveBeenCalledWith('index', { title: 'Express' });
      expect(mockNext).not.toHaveBeenCalled();
    });
  });

  describe('Router configuration', () => {
    it('should only have one route defined', () => {
      const routes = indexRouter.stack.filter(layer => layer.route);
      expect(routes).toHaveLength(1);
    });

    it('should only handle GET method', () => {
      const route = indexRouter.stack.find(layer => layer.route?.path === '/');
      const methods = Object.keys(route.route.methods);
      expect(methods).toEqual(['get']);
    });
  });
});