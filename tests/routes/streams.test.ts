import request from 'supertest';
import express from 'express';
import passport from 'passport';
import { prisma } from '../../lib/prisma';
import type { Stream, User } from '../../types';

// Mock Prisma
jest.mock('../../lib/prisma', () => ({
  prisma: {
    stream: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn()
    }
  },
  Stream: {
    create: jest.fn(),
    inferLocation: jest.fn((data) => Promise.resolve(data)),
    normalizeLink: jest.fn((link) => link.toLowerCase())
  }
}));

// Mock passport
jest.mock('passport', () => ({
  authenticate: jest.fn((strategy, options) => {
    return (req: any, res: any, next: any) => {
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

// Mock validation middleware
jest.mock('../../middleware/validation', () => ({
  streamValidationRules: {
    create: [(req: any, res: any, next: any) => next()],
    update: [(req: any, res: any, next: any) => next()],
    list: []
  },
  handleValidationErrors: (req: any, res: any, next: any) => next()
}));

// Create test app
const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Import routes after mocks
import streamsRouter from '../../routes/streams';
app.use('/streams', streamsRouter);

// Error handler
app.use((err: any, req: any, res: any, next: any) => {
  res.status(err.status || 500).json({ error: err.message });
});

describe('Streams Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /streams', () => {
    it('should return all non-expired streams with default ordering', async () => {
      const mockStreams: Stream[] = [
        {
          id: 1,
          source: 'stream1',
          platform: 'youtube',
          link: 'https://youtube.com/1',
          status: 'live',
          title: 'Stream 1',
          isExpired: false,
          isPinned: false,
          checkedAt: null,
          liveAt: null,
          embedLink: null,
          postedBy: null,
          city: null,
          region: null,
          createdAt: new Date(),
          updatedAt: new Date()
        },
        {
          id: 2,
          source: 'stream2',
          platform: 'twitch',
          link: 'https://twitch.tv/2',
          status: 'live',
          title: 'Stream 2',
          isExpired: false,
          isPinned: false,
          checkedAt: null,
          liveAt: null,
          embedLink: null,
          postedBy: null,
          city: null,
          region: null,
          createdAt: new Date(),
          updatedAt: new Date()
        }
      ];
      
      (prisma.stream.findMany as jest.Mock).mockResolvedValue(mockStreams);

      const response = await request(app)
        .get('/streams');

      expect(response.status).toBe(200);
      expect(response.body).toEqual({ 
        streams: mockStreams,
        count: 2
      });
      expect(prisma.stream.findMany).toHaveBeenCalledWith({
        where: { isExpired: false },
        orderBy: [{ createdAt: 'desc' }]
      });
    });

    it('should return array format when format=array', async () => {
      const mockStreams: Stream[] = [
        {
          id: 1,
          link: 'https://example.com',
          status: 'live',
          isExpired: false,
          isPinned: false,
          source: null,
          platform: null,
          title: null,
          checkedAt: null,
          liveAt: null,
          embedLink: null,
          postedBy: null,
          city: null,
          region: null,
          createdAt: new Date(),
          updatedAt: new Date()
        }
      ];
      
      (prisma.stream.findMany as jest.Mock).mockResolvedValue(mockStreams);

      const response = await request(app)
        .get('/streams?format=array');

      expect(response.status).toBe(200);
      expect(response.body).toEqual(mockStreams);
    });

    describe('Filtering', () => {
      it('should filter by source', async () => {
        (prisma.stream.findMany as jest.Mock).mockResolvedValue([]);

        await request(app).get('/streams?source=test');

        expect(prisma.stream.findMany).toHaveBeenCalledWith({
          where: {
            isExpired: false,
            source: { contains: 'test' }
          },
          orderBy: [{ createdAt: 'desc' }]
        });
      });

      it('should filter by platform', async () => {
        (prisma.stream.findMany as jest.Mock).mockResolvedValue([]);

        await request(app).get('/streams?platform=youtube');

        expect(prisma.stream.findMany).toHaveBeenCalledWith({
          where: {
            isExpired: false,
            platform: 'youtube'
          },
          orderBy: [{ createdAt: 'desc' }]
        });
      });

      it('should filter by status', async () => {
        (prisma.stream.findMany as jest.Mock).mockResolvedValue([]);

        await request(app).get('/streams?status=live');

        expect(prisma.stream.findMany).toHaveBeenCalledWith({
          where: {
            isExpired: false,
            status: 'live'
          },
          orderBy: [{ createdAt: 'desc' }]
        });
      });

      it('should filter by isPinned', async () => {
        (prisma.stream.findMany as jest.Mock).mockResolvedValue([]);

        await request(app).get('/streams?isPinned=true');

        expect(prisma.stream.findMany).toHaveBeenCalledWith({
          where: {
            isExpired: false,
            isPinned: true
          },
          orderBy: [{ createdAt: 'desc' }]
        });
      });

      it('should support date range filters', async () => {
        (prisma.stream.findMany as jest.Mock).mockResolvedValue([]);

        const fromDate = '2023-01-01T00:00:00Z';
        const toDate = '2023-12-31T23:59:59Z';

        await request(app).get(`/streams?createdAtFrom=${fromDate}&createdAtTo=${toDate}`);

        expect(prisma.stream.findMany).toHaveBeenCalledWith({
          where: {
            isExpired: false,
            createdAt: {
              gte: new Date(fromDate),
              lte: new Date(toDate)
            }
          },
          orderBy: [{ createdAt: 'desc' }]
        });
      });

      it('should support custom ordering', async () => {
        (prisma.stream.findMany as jest.Mock).mockResolvedValue([]);

        await request(app).get('/streams?orderFields=title,createdAt&orderDirections=asc,desc');

        expect(prisma.stream.findMany).toHaveBeenCalledWith({
          where: { isExpired: false },
          orderBy: [
            { title: 'asc' },
            { createdAt: 'desc' }
          ]
        });
      });
    });
  });

  describe('GET /streams/:id', () => {
    it('should return a single stream', async () => {
      const mockStream: Stream = {
        id: 1,
        link: 'https://example.com',
        status: 'live',
        isExpired: false,
        isPinned: false,
        source: null,
        platform: null,
        title: null,
        checkedAt: null,
        liveAt: null,
        embedLink: null,
        postedBy: null,
        city: null,
        region: null,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      (prisma.stream.findUnique as jest.Mock).mockResolvedValue(mockStream);

      const response = await request(app).get('/streams/1');

      expect(response.status).toBe(200);
      expect(response.body).toEqual({ stream: mockStream });
      expect(prisma.stream.findUnique).toHaveBeenCalledWith({
        where: { id: 1 }
      });
    });

    it('should return 404 if stream not found', async () => {
      (prisma.stream.findUnique as jest.Mock).mockResolvedValue(null);

      const response = await request(app).get('/streams/999');

      expect(response.status).toBe(404);
      expect(response.body).toEqual({ error: 'Stream not found' });
    });
  });

  describe('POST /streams', () => {
    it('should create a new stream for authorized users', async () => {
      const newStream = {
        link: 'https://youtube.com/watch?v=123',
        source: 'Test Source',
        platform: 'youtube',
        status: 'live'
      };

      const createdStream: Stream = {
        id: 1,
        ...newStream,
        link: 'https://youtube.com/watch?v=123', // normalized
        isExpired: false,
        isPinned: false,
        title: null,
        checkedAt: null,
        liveAt: null,
        embedLink: null,
        postedBy: null,
        city: null,
        region: null,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      (prisma.stream.create as jest.Mock).mockResolvedValue(createdStream);

      const response = await request(app)
        .post('/streams')
        .set('Authorization', 'Bearer token')
        .send(newStream);

      expect(response.status).toBe(201);
      expect(response.body).toEqual({ stream: createdStream });
    });

    it('should require authentication', async () => {
      const response = await request(app)
        .post('/streams')
        .send({ link: 'https://example.com' });

      expect(response.status).toBe(403);
    });

    it('should restrict default role from creating', async () => {
      const response = await request(app)
        .post('/streams')
        .set('Authorization', 'Bearer token')
        .set('x-test-role', 'default')
        .send({ link: 'https://example.com' });

      expect(response.status).toBe(403);
    });
  });

  describe('PATCH /streams/:id', () => {
    it('should update a stream', async () => {
      const existingStream: Stream = {
        id: 1,
        link: 'https://example.com',
        status: 'live',
        isExpired: false,
        isPinned: false,
        source: null,
        platform: null,
        title: null,
        checkedAt: null,
        liveAt: null,
        embedLink: null,
        postedBy: null,
        city: null,
        region: null,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      const updatedStream = { ...existingStream, status: 'offline' };

      (prisma.stream.findUnique as jest.Mock).mockResolvedValue(existingStream);
      (prisma.stream.update as jest.Mock).mockResolvedValue(updatedStream);

      const response = await request(app)
        .patch('/streams/1')
        .set('Authorization', 'Bearer token')
        .send({ status: 'offline' });

      expect(response.status).toBe(200);
      expect(response.body).toEqual({ stream: updatedStream });
    });

    it('should not update pinned streams', async () => {
      const pinnedStream: Stream = {
        id: 1,
        link: 'https://example.com',
        status: 'live',
        isExpired: false,
        isPinned: true,
        source: null,
        platform: null,
        title: null,
        checkedAt: null,
        liveAt: null,
        embedLink: null,
        postedBy: null,
        city: null,
        region: null,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      (prisma.stream.findUnique as jest.Mock).mockResolvedValue(pinnedStream);

      const response = await request(app)
        .patch('/streams/1')
        .set('Authorization', 'Bearer token')
        .send({ status: 'offline' });

      expect(response.status).toBe(403);
      expect(response.body).toEqual({ error: 'Cannot update a pinned stream' });
    });
  });

  describe('DELETE /streams/:id', () => {
    it('should delete a stream', async () => {
      const stream: Stream = {
        id: 1,
        link: 'https://example.com',
        status: 'live',
        isExpired: false,
        isPinned: false,
        source: null,
        platform: null,
        title: null,
        checkedAt: null,
        liveAt: null,
        embedLink: null,
        postedBy: null,
        city: null,
        region: null,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      (prisma.stream.findUnique as jest.Mock).mockResolvedValue(stream);
      (prisma.stream.delete as jest.Mock).mockResolvedValue(stream);

      const response = await request(app)
        .delete('/streams/1')
        .set('Authorization', 'Bearer token');

      expect(response.status).toBe(204);
    });

    it('should not delete pinned streams', async () => {
      const pinnedStream: Stream = {
        id: 1,
        link: 'https://example.com',
        status: 'live',
        isExpired: false,
        isPinned: true,
        source: null,
        platform: null,
        title: null,
        checkedAt: null,
        liveAt: null,
        embedLink: null,
        postedBy: null,
        city: null,
        region: null,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      (prisma.stream.findUnique as jest.Mock).mockResolvedValue(pinnedStream);

      const response = await request(app)
        .delete('/streams/1')
        .set('Authorization', 'Bearer token');

      expect(response.status).toBe(403);
      expect(response.body).toEqual({ error: 'Cannot delete a pinned stream' });
    });
  });

  describe('PUT /streams/:id/pin', () => {
    it('should pin a stream', async () => {
      const stream: Stream = {
        id: 1,
        link: 'https://example.com',
        status: 'live',
        isExpired: false,
        isPinned: false,
        source: null,
        platform: null,
        title: null,
        checkedAt: null,
        liveAt: null,
        embedLink: null,
        postedBy: null,
        city: null,
        region: null,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      const pinnedStream = { ...stream, isPinned: true };

      (prisma.stream.update as jest.Mock).mockResolvedValue(pinnedStream);

      const response = await request(app)
        .put('/streams/1/pin')
        .set('Authorization', 'Bearer token');

      expect(response.status).toBe(200);
      expect(response.body).toEqual({ stream: pinnedStream });
      expect(prisma.stream.update).toHaveBeenCalledWith({
        where: { id: 1 },
        data: { isPinned: true }
      });
    });
  });

  describe('DELETE /streams/:id/pin', () => {
    it('should unpin a stream', async () => {
      const pinnedStream: Stream = {
        id: 1,
        link: 'https://example.com',
        status: 'live',
        isExpired: false,
        isPinned: true,
        source: null,
        platform: null,
        title: null,
        checkedAt: null,
        liveAt: null,
        embedLink: null,
        postedBy: null,
        city: null,
        region: null,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      const unpinnedStream = { ...pinnedStream, isPinned: false };

      (prisma.stream.update as jest.Mock).mockResolvedValue(unpinnedStream);

      const response = await request(app)
        .delete('/streams/1/pin')
        .set('Authorization', 'Bearer token');

      expect(response.status).toBe(200);
      expect(response.body).toEqual({ stream: unpinnedStream });
      expect(prisma.stream.update).toHaveBeenCalledWith({
        where: { id: 1 },
        data: { isPinned: false }
      });
    });
  });
});