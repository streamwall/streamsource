const request = require('supertest');
const express = require('express');
const passport = require('passport');
const { Stream } = require('../../models');
const { Op } = require('sequelize');

// Mock dependencies
jest.mock('../../models', () => ({
  Stream: {
    findAll: jest.fn(),
    findOne: jest.fn(),
    findByPk: jest.fn(),
    create: jest.fn()
  }
}));

jest.mock('passport', () => ({
  authenticate: jest.fn((strategy, options) => {
    return (req, res, next) => {
      // Mock user for authenticated routes
      req.user = req.headers.authorization ? {
        id: 1,
        email: 'test@example.com',
        role: req.headers['x-test-role'] || 'editor'
      } : null;
      next();
    };
  })
}));

// Create test app
const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Load routes
const streamsRouter = require('../../routes/streams');
app.use('/streams', streamsRouter);

// Error handler
app.use((err, req, res, next) => {
  res.status(err.status || 500).json({ error: err.message });
});

describe('Streams Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /streams', () => {
    it('should return all non-expired streams with default ordering', async () => {
      const mockStreams = [
        { id: 1, source: 'stream1', isExpired: false },
        { id: 2, source: 'stream2', isExpired: false }
      ];
      Stream.findAll.mockResolvedValue(mockStreams);

      const response = await request(app)
        .get('/streams');

      expect(response.status).toBe(200);
      expect(response.body).toEqual({ data: mockStreams });
      expect(Stream.findAll).toHaveBeenCalledWith({
        where: { isExpired: { [Op.not]: true } },
        order: [['createdAt', 'DESC']]
      });
    });

    it('should return array format when format=array', async () => {
      const mockStreams = [{ id: 1 }, { id: 2 }];
      Stream.findAll.mockResolvedValue(mockStreams);

      const response = await request(app)
        .get('/streams?format=array');

      expect(response.status).toBe(200);
      expect(response.body).toEqual(mockStreams);
    });

    describe('Filtering', () => {
      it('should filter by source', async () => {
        Stream.findAll.mockResolvedValue([]);

        await request(app).get('/streams?source=test');

        expect(Stream.findAll).toHaveBeenCalledWith({
          where: {
            isExpired: { [Op.not]: true },
            source: { [Op.iLike]: '%test%' }
          },
          order: [['createdAt', 'DESC']]
        });
      });

      it('should filter by notSource', async () => {
        Stream.findAll.mockResolvedValue([]);

        await request(app).get('/streams?notSource=bad');

        expect(Stream.findAll).toHaveBeenCalledWith({
          where: {
            isExpired: { [Op.not]: true },
            source: { [Op.notILike]: '%bad%' }
          },
          order: [['createdAt', 'DESC']]
        });
      });

      it('should filter by platform', async () => {
        Stream.findAll.mockResolvedValue([]);

        await request(app).get('/streams?platform=Twitch');

        expect(Stream.findAll).toHaveBeenCalledWith({
          where: {
            isExpired: { [Op.not]: true },
            platform: { [Op.eq]: 'Twitch' }
          },
          order: [['createdAt', 'DESC']]
        });
      });

      it('should filter by status', async () => {
        Stream.findAll.mockResolvedValue([]);

        await request(app).get('/streams?status=Live');

        expect(Stream.findAll).toHaveBeenCalledWith({
          where: {
            isExpired: { [Op.not]: true },
            status: { [Op.eq]: 'Live' }
          },
          order: [['createdAt', 'DESC']]
        });
      });

      it('should filter by isExpired=true', async () => {
        Stream.findAll.mockResolvedValue([]);

        await request(app).get('/streams?isExpired=true');

        expect(Stream.findAll).toHaveBeenCalledWith({
          where: {
            isExpired: { [Op.is]: true }
          },
          order: [['createdAt', 'DESC']]
        });
      });

      it('should filter by isPinned', async () => {
        Stream.findAll.mockResolvedValue([]);

        await request(app).get('/streams?isPinned=true');

        expect(Stream.findAll).toHaveBeenCalledWith({
          where: {
            isExpired: { [Op.not]: true },
            isPinned: { [Op.is]: true }
          },
          order: [['createdAt', 'DESC']]
        });
      });

      it('should filter by city', async () => {
        Stream.findAll.mockResolvedValue([]);

        await request(app).get('/streams?city=Seattle');

        expect(Stream.findAll).toHaveBeenCalledWith({
          where: {
            isExpired: { [Op.not]: true },
            city: { [Op.iLike]: '%Seattle%' }
          },
          order: [['createdAt', 'DESC']]
        });
      });

      it('should handle multiple filters', async () => {
        Stream.findAll.mockResolvedValue([]);

        await request(app).get('/streams?city=Seattle&platform=Twitch&status=Live');

        expect(Stream.findAll).toHaveBeenCalledWith({
          where: {
            isExpired: { [Op.not]: true },
            city: { [Op.iLike]: '%Seattle%' },
            platform: { [Op.eq]: 'Twitch' },
            status: { [Op.eq]: 'Live' }
          },
          order: [['createdAt', 'DESC']]
        });
      });

      it('should handle date range filters with both from and to', async () => {
        Stream.findAll.mockResolvedValue([]);

        await request(app).get('/streams?createdAtFrom=2023-01-01&createdAtTo=2023-12-31');

        const call = Stream.findAll.mock.calls[0][0];
        expect(call.where.createdAt).toBeDefined();
      });

      it('should handle date range filter with only from date', async () => {
        Stream.findAll.mockResolvedValue([]);

        await request(app).get('/streams?createdAtFrom=2023-01-01');

        const call = Stream.findAll.mock.calls[0][0];
        expect(call.where.createdAt).toBeDefined();
      });

      it('should handle date range filter with only to date', async () => {
        Stream.findAll.mockResolvedValue([]);

        await request(app).get('/streams?createdAtTo=2023-12-31');

        const call = Stream.findAll.mock.calls[0][0];
        expect(call.where.createdAt).toBeDefined();
      });
    });

    describe('Ordering', () => {
      it('should order by specified fields', async () => {
        Stream.findAll.mockResolvedValue([]);

        await request(app).get('/streams?orderFields=source,createdAt&orderDirections=ASC,DESC');

        expect(Stream.findAll).toHaveBeenCalledWith({
          where: { isExpired: { [Op.not]: true } },
          order: [['source', 'ASC'], ['createdAt', 'DESC']]
        });
      });

      it('should return error if only orderFields provided', async () => {
        const response = await request(app)
          .get('/streams?orderFields=source');

        expect(response.status).toBe(400);
        expect(response.body.error).toBe('Ordering requires both orderFields and orderDirections params to be sent');
        expect(Stream.findAll).not.toHaveBeenCalled();
      });

      it('should return error if only orderDirections provided', async () => {
        const response = await request(app)
          .get('/streams?orderDirections=ASC');

        expect(response.status).toBe(400);
        expect(response.body.error).toBe('Ordering requires both orderFields and orderDirections params to be sent');
        expect(Stream.findAll).not.toHaveBeenCalled();
      });

      it('should return error if orderFields and orderDirections have different lengths', async () => {
        const response = await request(app)
          .get('/streams?orderFields=source,platform&orderDirections=ASC');

        expect(response.status).toBe(400);
        expect(response.body.error).toContain('must have the same length');
      });

      it('should return error for invalid order fields', async () => {
        const response = await request(app)
          .get('/streams?orderFields=invalidField&orderDirections=ASC');

        expect(response.status).toBe(400);
        expect(response.body.error).toContain('Cannot order by fields: invalidField');
      });
    });
  });

  describe('POST /streams', () => {
    it('should create stream with editor role', async () => {
      const mockStream = {
        id: 1,
        link: 'https://example.com/stream',
        source: 'test_source'
      };
      Stream.findOne.mockResolvedValue(null);
      Stream.create.mockResolvedValue(mockStream);

      const response = await request(app)
        .post('/streams')
        .set('Authorization', 'Bearer token')
        .send({
          link: 'https://example.com/stream',
          source: 'test_source',
          city: 'Seattle'
        });

      expect(response.status).toBe(201);
      expect(response.body).toEqual({ data: mockStream });
    });

    it('should return 303 for duplicate active stream', async () => {
      const existingStream = {
        id: 1,
        link: 'https://example.com/stream'
      };
      Stream.findOne.mockResolvedValue(existingStream);

      const response = await request(app)
        .post('/streams')
        .set('Authorization', 'Bearer token')
        .send({
          link: 'https://example.com/stream'
        });

      expect(response.status).toBe(303);
      expect(response.body).toEqual({ data: existingStream });
    });

    it('should return 401 for unauthenticated request', async () => {
      const response = await request(app)
        .post('/streams')
        .send({
          link: 'https://example.com/stream'
        });

      expect(response.status).toBe(401);
    });

    it('should return 401 for default role', async () => {
      const response = await request(app)
        .post('/streams')
        .set('Authorization', 'Bearer token')
        .set('X-Test-Role', 'default')
        .send({
          link: 'https://example.com/stream'
        });

      expect(response.status).toBe(401);
    });

    it('should normalize links for duplicate detection', async () => {
      Stream.findOne.mockResolvedValue(null);
      Stream.create.mockResolvedValue({ id: 1 });

      await request(app)
        .post('/streams')
        .set('Authorization', 'Bearer token')
        .send({
          link: 'https://www.example.com/stream/'
        });

      expect(Stream.findOne).toHaveBeenCalledWith({
        where: {
          link: { [Op.iLike]: '%example.com/stream%' },
          isExpired: false
        }
      });
    });
  });

  describe('GET /streams/:id', () => {
    it('should return stream by id', async () => {
      const mockStream = { id: 1, source: 'test' };
      Stream.findByPk.mockResolvedValue(mockStream);

      const response = await request(app)
        .get('/streams/1');

      expect(response.status).toBe(200);
      expect(response.body).toEqual({ data: mockStream });
    });

    it('should return 404 for non-existent stream', async () => {
      Stream.findByPk.mockResolvedValue(null);

      const response = await request(app)
        .get('/streams/999');

      expect(response.status).toBe(404);
    });
  });

  describe('PATCH /streams/:id', () => {
    it('should update stream with editor role', async () => {
      const mockStream = {
        id: 1,
        status: 'Live',
        isPinned: false,
        update: jest.fn().mockResolvedValue({
          id: 1,
          status: 'Offline'
        })
      };
      Stream.findByPk.mockResolvedValue(mockStream);

      const response = await request(app)
        .patch('/streams/1')
        .set('Authorization', 'Bearer token')
        .send({
          status: 'Offline'
        });

      expect(response.status).toBe(200);
      expect(mockStream.update).toHaveBeenCalled();
    });

    it('should return 409 when trying to change pinned stream status', async () => {
      const mockStream = {
        id: 1,
        status: 'Live',
        isPinned: true,
        isExpired: false
      };
      Stream.findByPk.mockResolvedValue(mockStream);

      const response = await request(app)
        .patch('/streams/1')
        .set('Authorization', 'Bearer token')
        .send({
          status: 'Offline'
        });

      expect(response.status).toBe(409);
      expect(response.body.error.message).toContain('Stream is pinned');
    });

    it('should return 409 when trying to change pinned stream isExpired', async () => {
      const mockStream = {
        id: 1,
        status: 'Live',
        isPinned: true,
        isExpired: false
      };
      Stream.findByPk.mockResolvedValue(mockStream);

      const response = await request(app)
        .patch('/streams/1')
        .set('Authorization', 'Bearer token')
        .send({
          isExpired: true
        });

      expect(response.status).toBe(409);
      expect(response.body.error.message).toContain('Stream is pinned');
    });

    it('should allow non-state changes on pinned streams', async () => {
      const mockStream = {
        id: 1,
        isPinned: true,
        update: jest.fn().mockResolvedValue({ id: 1 })
      };
      Stream.findByPk.mockResolvedValue(mockStream);

      const response = await request(app)
        .patch('/streams/1')
        .set('Authorization', 'Bearer token')
        .send({
          title: 'New Title'
        });

      expect(response.status).toBe(200);
      expect(mockStream.update).toHaveBeenCalled();
    });

    it('should return 401 for unauthenticated request', async () => {
      const response = await request(app)
        .patch('/streams/1')
        .send({
          status: 'Offline'
        });

      expect(response.status).toBe(401);
    });

    it('should handle validation errors from update', async () => {
      const { ValidationError } = require('sequelize');
      const validationError = new ValidationError('Invalid data');
      
      const mockStream = {
        id: 1,
        isPinned: false,
        update: jest.fn().mockResolvedValue(validationError)
      };
      Stream.findByPk.mockResolvedValue(mockStream);

      const response = await request(app)
        .patch('/streams/1')
        .set('Authorization', 'Bearer token')
        .send({
          link: 'invalid-url'
        });

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });
  });

  describe('PUT /streams/:id/pin', () => {
    it('should pin stream with editor role', async () => {
      const mockStream = {
        id: 1,
        update: jest.fn()
      };
      Stream.findByPk.mockResolvedValue(mockStream);

      const response = await request(app)
        .put('/streams/1/pin')
        .set('Authorization', 'Bearer token');

      expect(response.status).toBe(204);
      expect(mockStream.update).toHaveBeenCalledWith({ isPinned: true });
    });

    it('should return 404 for non-existent stream', async () => {
      Stream.findByPk.mockResolvedValue(null);

      const response = await request(app)
        .put('/streams/999/pin')
        .set('Authorization', 'Bearer token');

      expect(response.status).toBe(404);
    });

    it('should return 401 for unauthorized user', async () => {
      const response = await request(app)
        .put('/streams/1/pin');

      expect(response.status).toBe(401);
    });

    it('should return 401 for default role user', async () => {
      const response = await request(app)
        .put('/streams/1/pin')
        .set('Authorization', 'Bearer token')
        .set('X-Test-Role', 'default');

      expect(response.status).toBe(401);
    });
  });

  describe('DELETE /streams/:id/pin', () => {
    it('should unpin stream with editor role', async () => {
      const mockStream = {
        id: 1,
        update: jest.fn()
      };
      Stream.findByPk.mockResolvedValue(mockStream);

      const response = await request(app)
        .delete('/streams/1/pin')
        .set('Authorization', 'Bearer token');

      expect(response.status).toBe(204);
      expect(mockStream.update).toHaveBeenCalledWith({ isPinned: false });
    });

    it('should return 404 for non-existent stream', async () => {
      Stream.findByPk.mockResolvedValue(null);

      const response = await request(app)
        .delete('/streams/999/pin')
        .set('Authorization', 'Bearer token');

      expect(response.status).toBe(404);
    });

    it('should return 401 for unauthorized user', async () => {
      const response = await request(app)
        .delete('/streams/1/pin');

      expect(response.status).toBe(401);
    });

    it('should return 401 for default role user', async () => {
      const response = await request(app)
        .delete('/streams/1/pin')
        .set('Authorization', 'Bearer token')
        .set('X-Test-Role', 'default');

      expect(response.status).toBe(401);
    });
  });

  describe('DELETE /streams/:id', () => {
    it('should expire stream with editor role', async () => {
      const mockStream = {
        id: 1,
        isPinned: false,
        update: jest.fn()
      };
      Stream.findByPk.mockResolvedValue(mockStream);

      const response = await request(app)
        .delete('/streams/1')
        .set('Authorization', 'Bearer token');

      expect(response.status).toBe(204);
      expect(mockStream.update).toHaveBeenCalledWith({ isExpired: true });
    });

    it('should return 409 when trying to expire pinned stream', async () => {
      const mockStream = {
        id: 1,
        isPinned: true
      };
      Stream.findByPk.mockResolvedValue(mockStream);

      const response = await request(app)
        .delete('/streams/1')
        .set('Authorization', 'Bearer token');

      expect(response.status).toBe(409);
    });

    it('should return 404 for non-existent stream', async () => {
      Stream.findByPk.mockResolvedValue(null);

      const response = await request(app)
        .delete('/streams/999')
        .set('Authorization', 'Bearer token');

      expect(response.status).toBe(404);
    });

    it('should return 401 for unauthorized user', async () => {
      const response = await request(app)
        .delete('/streams/1');

      expect(response.status).toBe(401);
    });

    it('should return 401 for default role user', async () => {
      const response = await request(app)
        .delete('/streams/1')
        .set('Authorization', 'Bearer token')
        .set('X-Test-Role', 'default');

      expect(response.status).toBe(401);
    });
  });
});