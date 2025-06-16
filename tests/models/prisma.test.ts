import { prisma, User, Stream } from '../../lib/prisma';
import bcrypt from 'bcrypt';

// Mock bcrypt
jest.mock('bcrypt', () => ({
  hash: jest.fn((password, rounds) => Promise.resolve(`hashed_${password}`)),
  compare: jest.fn((password, hash) => Promise.resolve(hash === `hashed_${password}`))
}));

// Mock Prisma client
jest.mock('@prisma/client', () => ({
  PrismaClient: jest.fn().mockImplementation(() => ({
    user: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn()
    },
    stream: {
      create: jest.fn(),
      findFirst: jest.fn()
    }
  }))
}));

describe('Prisma Models', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('User Model Extensions', () => {
    describe('create', () => {
      it('should hash password before creating user', async () => {
        const userData = {
          email: 'test@example.com',
          password: 'plainPassword',
          role: 'default'
        };

        const expectedUser = {
          id: 1,
          ...userData,
          password: 'hashed_plainPassword',
          createdAt: new Date(),
          updatedAt: new Date()
        };

        (prisma.user.create as jest.Mock).mockResolvedValue(expectedUser);

        const result = await User.create(userData);

        expect(bcrypt.hash).toHaveBeenCalledWith('plainPassword', 10);
        expect(prisma.user.create).toHaveBeenCalledWith({
          data: {
            ...userData,
            password: 'hashed_plainPassword'
          }
        });
        expect(result).toEqual(expectedUser);
      });
    });

    describe('update', () => {
      it('should hash password if provided in update', async () => {
        const updateData = {
          password: 'newPassword'
        };

        const expectedUser = {
          id: 1,
          email: 'test@example.com',
          password: 'hashed_newPassword',
          role: 'default',
          createdAt: new Date(),
          updatedAt: new Date()
        };

        (prisma.user.update as jest.Mock).mockResolvedValue(expectedUser);

        const result = await User.update({ id: 1 }, updateData);

        expect(bcrypt.hash).toHaveBeenCalledWith('newPassword', 10);
        expect(prisma.user.update).toHaveBeenCalledWith({
          where: { id: 1 },
          data: {
            password: 'hashed_newPassword'
          }
        });
      });

      it('should use email as unique identifier if id not provided', async () => {
        const expectedUser = {
          id: 1,
          email: 'test@example.com',
          password: 'hashed',
          role: 'default',
          createdAt: new Date(),
          updatedAt: new Date()
        };

        (prisma.user.update as jest.Mock).mockResolvedValue(expectedUser);

        await User.update({ email: 'test@example.com' }, { role: 'editor' });

        expect(prisma.user.update).toHaveBeenCalledWith({
          where: { email: 'test@example.com' },
          data: { role: 'editor' }
        });
      });
    });

    describe('validatePassword', () => {
      it('should validate correct password', async () => {
        const user = {
          id: 1,
          email: 'test@example.com',
          password: 'hashed_correctPassword',
          role: 'default',
          createdAt: new Date(),
          updatedAt: new Date()
        };

        const isValid = await User.validatePassword(user, 'correctPassword');

        expect(bcrypt.compare).toHaveBeenCalledWith('correctPassword', 'hashed_correctPassword');
        expect(isValid).toBe(true);
      });

      it('should reject incorrect password', async () => {
        const user = {
          id: 1,
          email: 'test@example.com',
          password: 'hashed_correctPassword',
          role: 'default',
          createdAt: new Date(),
          updatedAt: new Date()
        };

        const isValid = await User.validatePassword(user, 'wrongPassword');

        expect(isValid).toBe(false);
      });
    });
  });

  describe('Stream Model Extensions', () => {
    describe('inferLocation', () => {
      it('should return stream data if location already provided', async () => {
        const streamData = {
          link: 'https://example.com/stream',
          city: 'New York',
          region: 'NY'
        };

        const result = await Stream.inferLocation(streamData);

        expect(result).toEqual(streamData);
        expect(prisma.stream.findFirst).not.toHaveBeenCalled();
      });

      it('should infer location from past streams with same link', async () => {
        const streamData = {
          link: 'https://example.com/stream'
        };

        const pastStream = {
          id: 1,
          link: 'https://example.com/stream',
          city: 'Los Angeles',
          region: 'CA',
          source: null,
          platform: null,
          status: 'offline',
          title: null,
          isExpired: false,
          isPinned: false,
          checkedAt: null,
          liveAt: null,
          embedLink: null,
          postedBy: null,
          createdAt: new Date(),
          updatedAt: new Date()
        };

        (prisma.stream.findFirst as jest.Mock).mockResolvedValue(pastStream);

        const result = await Stream.inferLocation(streamData);

        expect(prisma.stream.findFirst).toHaveBeenCalledWith({
          where: {
            OR: [
              { link: 'https://example.com/stream' }
            ],
            AND: [
              {
                OR: [
                  { city: { not: null } },
                  { region: { not: null } }
                ]
              }
            ]
          },
          orderBy: { createdAt: 'desc' }
        });

        expect(result).toEqual({
          ...streamData,
          city: 'Los Angeles',
          region: 'CA'
        });
      });

      it('should include source in location inference if provided', async () => {
        const streamData = {
          link: 'https://example.com/stream',
          source: 'TestSource'
        };

        (prisma.stream.findFirst as jest.Mock).mockResolvedValue(null);

        await Stream.inferLocation(streamData);

        expect(prisma.stream.findFirst).toHaveBeenCalledWith({
          where: {
            OR: [
              { link: 'https://example.com/stream' },
              { source: 'TestSource' }
            ],
            AND: [
              {
                OR: [
                  { city: { not: null } },
                  { region: { not: null } }
                ]
              }
            ]
          },
          orderBy: { createdAt: 'desc' }
        });
      });
    });

    describe('normalizeLink', () => {
      it('should remove trailing slash', () => {
        const result = Stream.normalizeLink('https://example.com/stream/');
        expect(result).toBe('https://example.com/stream');
      });

      it('should remove protocol and www', () => {
        const result = Stream.normalizeLink('https://www.example.com/stream');
        expect(result).toBe('example.com/stream');
      });

      it('should handle http protocol', () => {
        const result = Stream.normalizeLink('http://example.com/stream');
        expect(result).toBe('example.com/stream');
      });

      it('should handle multiple transformations', () => {
        const result = Stream.normalizeLink('https://www.example.com/stream/');
        expect(result).toBe('example.com/stream');
      });
    });

    describe('create', () => {
      it('should create stream with location inference', async () => {
        const streamData = {
          link: 'https://example.com/stream',
          status: 'live'
        };

        const inferredData = {
          ...streamData,
          city: 'Boston',
          region: 'MA'
        };

        const createdStream = {
          id: 1,
          ...inferredData,
          source: null,
          platform: null,
          title: null,
          isExpired: false,
          isPinned: false,
          checkedAt: null,
          liveAt: null,
          embedLink: null,
          postedBy: null,
          createdAt: new Date(),
          updatedAt: new Date()
        };

        jest.spyOn(Stream, 'inferLocation').mockResolvedValue(inferredData);
        (prisma.stream.create as jest.Mock).mockResolvedValue(createdStream);

        const result = await Stream.create(streamData);

        expect(Stream.inferLocation).toHaveBeenCalledWith(streamData);
        expect(prisma.stream.create).toHaveBeenCalledWith({
          data: inferredData
        });
        expect(result).toEqual(createdStream);
      });
    });
  });
});