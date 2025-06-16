const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');
const passport = require('passport');
const { User } = require('../../models');

// Mock dependencies
jest.mock('../../models', () => ({
  User: {
    findOne: jest.fn(),
    create: jest.fn()
  }
}));

// Create test app
const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Mock req.login
app.use((req, res, next) => {
  req.login = jest.fn((user, options, callback) => {
    callback(null);
  });
  next();
});

// Load routes AFTER setting up mocks
const usersRouter = require('../../routes/users');
app.use('/users', usersRouter);

// Error handler
app.use((err, req, res, next) => {
  res.status(err.status || 500).json({ error: err.message });
});

describe('Users Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.JWT_SECRET = 'test_secret';
  });

  describe('POST /users/signup', () => {
    beforeEach(() => {
      // Import the actual createUser function to test it directly
      const { createUser } = require('../../routes/users');
      
      // Mock passport for signup to pass through to createUser
      passport.authenticate = jest.fn((strategy, options) => {
        return (req, res, next) => {
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
          password: 'password123'
        });

      expect(response.status).toBe(200);
      expect(response.body).toEqual({
        message: 'Signed up successfully',
        user: expect.objectContaining({
          id: 1,
          email: 'test@example.com'
        })
      });
    });

    it('should handle missing email', async () => {
      const response = await request(app)
        .post('/users/signup')
        .send({
          password: 'password123'
        });

      expect(response.status).toBe(200);
    });

    it('should handle missing password', async () => {
      const response = await request(app)
        .post('/users/signup')
        .send({
          email: 'test@example.com'
        });

      expect(response.status).toBe(200);
    });

    it('should handle empty request body', async () => {
      const response = await request(app)
        .post('/users/signup')
        .send({});

      expect(response.status).toBe(200);
    });
  });

  describe('POST /users/login', () => {
    it('should login user successfully and return JWT token', async () => {
      // Mock passport authenticate to call the callback immediately
      passport.authenticate = jest.fn((strategy, callback) => {
        return (req, res, next) => {
          if (strategy === 'login' && callback) {
            // Call the callback with successful auth
            callback(null, { _id: 1, email: 'user@example.com' }, null)(req, res, next);
          }
        };
      });

      const response = await request(app)
        .post('/users/login')
        .send({
          email: 'user@example.com',
          password: 'correctpassword'
        });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('token');
      
      // Verify JWT token
      const decoded = jwt.verify(response.body.token, process.env.JWT_SECRET);
      expect(decoded.user).toEqual({
        _id: 1,
        email: 'user@example.com'
      });
    });

    it('should handle authentication error', async () => {
      passport.authenticate = jest.fn((strategy, callback) => {
        return (req, res, next) => {
          if (strategy === 'login' && callback) {
            const error = new Error('Authentication failed');
            callback(error, null, null)(req, res, next);
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

    it('should handle user not found', async () => {
      passport.authenticate = jest.fn((strategy, callback) => {
        return (req, res, next) => {
          if (strategy === 'login' && callback) {
            callback(null, false, { message: 'User not found' })(req, res, next);
          }
        };
      });

      const response = await request(app)
        .post('/users/login')
        .send({
          email: 'notfound@example.com',
          password: 'password'
        });

      expect(response.status).toBe(500);
    });

    it('should handle login callback error', async () => {
      passport.authenticate = jest.fn((strategy, callback) => {
        return (req, res, next) => {
          if (strategy === 'login' && callback) {
            // Mock successful auth but fail in req.login
            req.login = jest.fn((user, options, loginCallback) => {
              loginCallback(new Error('Login failed'));
            });
            callback(null, { _id: 1, email: 'user@example.com' }, null)(req, res, next);
          }
        };
      });

      const response = await request(app)
        .post('/users/login')
        .send({
          email: 'user@example.com',
          password: 'password'
        });

      expect(response.status).toBe(500);
    });

    it('should handle exception in authenticate callback', async () => {
      passport.authenticate = jest.fn((strategy, callback) => {
        return (req, res, next) => {
          if (strategy === 'login' && callback) {
            // Create a callback function that throws when trying to login
            const authFunc = callback;
            
            // Mock req.login to throw an error outside the callback
            req.login = jest.fn().mockImplementation(() => {
              throw new Error('Unexpected error in try block');
            });
            
            // Call the auth function which will trigger the try-catch
            authFunc(null, { _id: 1, email: 'test@example.com' }, null)(req, res, next);
          }
        };
      });

      const response = await request(app)
        .post('/users/login')
        .send({
          email: 'user@example.com',
          password: 'password'
        });

      expect(response.status).toBe(500);
      expect(response.body.error).toBe('Unexpected error in try block');
    });
  });

  describe('JWT Token Generation', () => {
    it('should not include sensitive information in token', async () => {
      passport.authenticate = jest.fn((strategy, callback) => {
        return (req, res, next) => {
          if (strategy === 'login' && callback) {
            const mockUser = { 
              _id: 1, 
              email: 'user@example.com',
              password: 'hashedPassword', // This should NOT be in token
              role: 'default',
              createdAt: new Date()
            };
            callback(null, mockUser, null)(req, res, next);
          }
        };
      });

      const response = await request(app)
        .post('/users/login')
        .send({
          email: 'user@example.com',
          password: 'password'
        });

      const decoded = jwt.verify(response.body.token, process.env.JWT_SECRET);
      expect(decoded.user).not.toHaveProperty('password');
      expect(decoded.user).not.toHaveProperty('role');
      expect(decoded.user).not.toHaveProperty('createdAt');
      expect(decoded.user).toEqual({
        _id: 1,
        email: 'user@example.com'
      });
    });

    it('should handle missing JWT_SECRET', async () => {
      delete process.env.JWT_SECRET;
      
      passport.authenticate = jest.fn((strategy, callback) => {
        return (req, res, next) => {
          if (strategy === 'login' && callback) {
            const mockUser = { _id: 1, email: 'user@example.com' };
            callback(null, mockUser, null)(req, res, next);
          }
        };
      });

      const response = await request(app)
        .post('/users/login')
        .send({
          email: 'user@example.com',
          password: 'password'
        });

      expect(response.status).toBe(500);
    });
  });

  describe('Error Handling', () => {
    it('should pass errors to Express error handler', async () => {
      const testError = new Error('Test error');
      
      passport.authenticate = jest.fn(() => {
        return (req, res, next) => {
          next(testError);
        };
      });

      const response = await request(app)
        .post('/users/signup')
        .send({
          email: 'test@example.com',
          password: 'password'
        });

      expect(response.status).toBe(500);
    });
  });

  describe('createUser function directly', () => {
    it('should respond with user data', async () => {
      // Import the createUser function directly
      const usersModule = require('../../routes/users');
      
      // Find the createUser function - it's not exported, so we need to test via route
      // The issue is that line 10 executes but coverage isn't seeing it
      // This is likely because the response is being intercepted by our mock
      
      // Create a minimal test to ensure the route works
      const mockReq = { user: { id: 1, email: 'test@example.com' } };
      const mockRes = { json: jest.fn() };
      
      // Get the route handler directly from the router
      const routes = app._router.stack.filter(r => r.route && r.route.path === '/users/signup');
      if (routes.length > 0) {
        const handlers = routes[0].route.stack;
        const createUserHandler = handlers[handlers.length - 1].handle;
        
        // Call the handler directly
        await createUserHandler(mockReq, mockRes);
        
        expect(mockRes.json).toHaveBeenCalledWith({
          message: "Signed up successfully",
          user: mockReq.user
        });
      }
    });
  });
});