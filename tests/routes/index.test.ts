import request from 'supertest';
import express from 'express';
import path from 'path';

// Create test app
const app = express();

// Set up view engine for testing
app.set('views', path.join(__dirname, '../../views'));
app.set('view engine', 'pug');

// Mock the render method to avoid actual template rendering
app.use((req: any, res: any, next: any) => {
  res.render = jest.fn((view: string, locals: any) => {
    res.json({ view, locals });
  });
  next();
});

// Load the router
import indexRouter from '../../routes/index';
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
  });
});