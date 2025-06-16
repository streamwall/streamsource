import request from 'supertest';
import express from 'express';
import jwt from 'jsonwebtoken';
import passport from 'passport';
import { prisma, User } from '../../lib/prisma';
import type { User as UserType } from '../../types';

// Mock dependencies BEFORE requiring anything that uses them
jest.mock('../../lib/prisma', () => ({
  prisma: {
    user: {
      findUnique: jest.fn(),
      create: jest.fn()
    }
  },
  User: {
    create: jest.fn(),
    validatePassword: jest.fn()
  }
}));

jest.mock('passport', () => ({
  authenticate: jest.fn(() => (req: any, res: any, next: any) => next())
}));

// Mock validation middleware
jest.mock('../../middleware/validation', () => ({
  userValidationRules: {
    signup: [(req: any, res: any, next: any) => next()],
    login: [(req: any, res: any, next: any) => next()]
  },
  handleValidationErrors: (req: any, res: any, next: any) => next()
}));

// Create test app
const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Mock req.login
app.use((req: any, res: any, next: any) => {
  req.login = jest.fn((user: any, options: any, callback: any) => {
    callback(null);
  });
  next();
});

// Load routes AFTER setting up mocks
import usersRouter from '../../routes/users';
app.use('/users', usersRouter);

// Error handler
app.use((err: any, req: any, res: any, next: any) => {
  console.error('Test error handler:', err);
  res.status(err.status || 500).json({ error: err.message });
});

describe('Users Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.JWT_SECRET = 'test_secret';
  });

  describe('POST /users/signup', () => {
    beforeEach(() => {
      // Mock passport for signup to pass through to createUser
      (passport.authenticate as jest.Mock) = jest.fn((strategy, options) => {
        return (req: any, res: any, next: any) => {
          if (strategy === 'signup') {
            req.user = { id: 1, email: 'test@example.com', password: 'hashed' };
            next();
          }
        };
      });
    });

    it('should create user successfully', async () => {
      const response = await request(app)
        .post('/users/signup')
        .send({
          email: 'newuser@example.com',
          password: 'Password123'
        });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Signed up successfully');
      expect(response.body).toHaveProperty('user');
    });

    it('should handle validation errors', async () => {
      // Mock validation to fail
      jest.unmock('../../middleware/validation');
      jest.mock('../../middleware/validation', () => ({
        userValidationRules: {
          signup: [(req: any, res: any, next: any) => next()],
          login: [(req: any, res: any, next: any) => next()]
        },
        handleValidationErrors: (req: any, res: any, next: any) => {
          res.status(400).json({ errors: [{ msg: 'Invalid email' }] });
        }
      }));

      const response = await request(app)
        .post('/users/signup')
        .send({
          email: 'invalid',
          password: 'weak'
        });

      expect(response.status).toBe(400);
    });
  });

  describe('POST /users/login', () => {
    it('should login user with valid credentials', async () => {
      const mockUser: UserType = {
        id: 1,
        email: 'user@example.com',
        password: 'hashedPassword',
        role: 'default',
        createdAt: new Date(),
        updatedAt: new Date()
      };

      // Mock passport authenticate for login
      (passport.authenticate as jest.Mock) = jest.fn((strategy, callback) => {
        return (req: any, res: any, next: any) => {
          if (strategy === 'login' && callback) {
            callback(null, mockUser, null)(req, res, next);
          }
        };
      });

      const response = await request(app)
        .post('/users/login')
        .send({
          email: 'user@example.com',
          password: 'password123'
        });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('token');
      
      // Verify JWT token
      const decoded = jwt.verify(response.body.token, 'test_secret') as any;
      expect(decoded.user).toEqual({
        _id: mockUser.id,
        email: mockUser.email
      });
    });

    it('should handle login failure', async () => {
      // Mock passport authenticate to fail
      (passport.authenticate as jest.Mock) = jest.fn((strategy, callback) => {
        return (req: any, res: any, next: any) => {
          if (strategy === 'login' && callback) {
            callback(null, false, { message: 'Invalid credentials' })(req, res, next);
          }
        };
      });

      const response = await request(app)
        .post('/users/login')
        .send({
          email: 'user@example.com',
          password: 'wrongpassword'
        });

      expect(response.status).toBe(500);
    });

    it('should handle passport errors', async () => {
      // Mock passport authenticate to throw error
      (passport.authenticate as jest.Mock) = jest.fn((strategy, callback) => {
        return (req: any, res: any, next: any) => {
          if (strategy === 'login' && callback) {
            callback(new Error('Database error'), null, null)(req, res, next);
          }
        };
      });

      const response = await request(app)
        .post('/users/login')
        .send({
          email: 'user@example.com',
          password: 'password123'
        });

      expect(response.status).toBe(500);
    });
  });

  describe('JWT Token Generation', () => {
    it('should generate valid JWT token', async () => {
      const mockUser: UserType = {
        id: 123,
        email: 'jwt@example.com',
        password: 'hashed',
        role: 'editor',
        createdAt: new Date(),
        updatedAt: new Date()
      };

      (passport.authenticate as jest.Mock) = jest.fn((strategy, callback) => {
        return (req: any, res: any, next: any) => {
          if (strategy === 'login' && callback) {
            callback(null, mockUser, null)(req, res, next);
          }
        };
      });

      const response = await request(app)
        .post('/users/login')
        .send({
          email: 'jwt@example.com',
          password: 'password123'
        });

      expect(response.status).toBe(200);
      const token = response.body.token;
      
      // Verify token structure
      const decoded = jwt.verify(token, 'test_secret') as any;
      expect(decoded).toHaveProperty('user');
      expect(decoded.user._id).toBe(123);
      expect(decoded.user.email).toBe('jwt@example.com');
      expect(decoded).toHaveProperty('iat');
      expect(decoded).toHaveProperty('exp');
      
      // Verify expiration is 24 hours
      const iat = decoded.iat;
      const exp = decoded.exp;
      expect(exp - iat).toBe(24 * 60 * 60); // 24 hours in seconds
    });

    it('should handle missing JWT_SECRET', async () => {
      const originalSecret = process.env.JWT_SECRET;
      delete process.env.JWT_SECRET;

      const mockUser: UserType = {
        id: 1,
        email: 'user@example.com',
        password: 'hashed',
        role: 'default',
        createdAt: new Date(),
        updatedAt: new Date()
      };

      (passport.authenticate as jest.Mock) = jest.fn((strategy, callback) => {
        return (req: any, res: any, next: any) => {
          if (strategy === 'login' && callback) {
            callback(null, mockUser, null)(req, res, next);
          }
        };
      });

      const response = await request(app)
        .post('/users/login')
        .send({
          email: 'user@example.com',
          password: 'password123'
        });

      expect(response.status).toBe(500);
      
      // Restore JWT_SECRET
      process.env.JWT_SECRET = originalSecret;
    });
  });
});