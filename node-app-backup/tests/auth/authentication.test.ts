import passport from 'passport';
import { prisma, User } from '../../lib/prisma';
import type { User as UserType } from '../../types';

// Import to register strategies
import '../../auth/authentication';

// Mock the prisma module
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

describe('Authentication Strategies', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('JWT Strategy', () => {
    let jwtStrategy: any;
    
    beforeAll(() => {
      // Get the JWT strategy
      jwtStrategy = (passport as any)._strategies.jwt;
    });

    it('should authenticate valid JWT token', async () => {
      const mockUser: UserType = { 
        id: 1, 
        email: 'test@example.com', 
        password: 'hashed',
        role: 'default',
        createdAt: new Date(),
        updatedAt: new Date()
      };
      const mockToken = { user: { _id: 1, email: 'test@example.com' } };
      const done = jest.fn();

      (prisma.user.findUnique as jest.Mock).mockResolvedValue(mockUser);

      await jwtStrategy._verify(mockToken, done);

      expect(prisma.user.findUnique).toHaveBeenCalledWith({ where: { email: 'test@example.com' } });
      expect(done).toHaveBeenCalledWith(null, mockUser);
    });

    it('should handle user not found', async () => {
      const mockToken = { user: { _id: 1, email: 'notfound@example.com' } };
      const done = jest.fn();

      (prisma.user.findUnique as jest.Mock).mockResolvedValue(null);

      await jwtStrategy._verify(mockToken, done);

      expect(prisma.user.findUnique).toHaveBeenCalledWith({ where: { email: 'notfound@example.com' } });
      expect(done).toHaveBeenCalledWith(null, null);
    });

    it('should handle database error', async () => {
      const mockToken = { user: { _id: 1, email: 'test@example.com' } };
      const done = jest.fn();
      const error = new Error('Database error');

      (prisma.user.findUnique as jest.Mock).mockRejectedValue(error);

      await jwtStrategy._verify(mockToken, done);

      expect(done).toHaveBeenCalledWith(error);
    });

    it('should extract JWT from Bearer token', () => {
      const req = {
        headers: {
          authorization: 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        }
      };

      const token = jwtStrategy._jwtFromRequest(req);
      expect(token).toBe('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9');
    });
  });

  describe('Signup Strategy', () => {
    let signupStrategy: any;

    beforeAll(() => {
      signupStrategy = (passport as any)._strategies.signup;
    });

    it('should create new user successfully', async () => {
      const mockUser: UserType = { 
        id: 1, 
        email: 'newuser@example.com',
        password: 'hashedPassword',
        role: 'default',
        createdAt: new Date(),
        updatedAt: new Date()
      };
      const done = jest.fn();

      (User.create as jest.Mock).mockResolvedValue(mockUser);

      await signupStrategy._verify('newuser@example.com', 'password123', done);

      expect(User.create).toHaveBeenCalledWith({
        email: 'newuser@example.com',
        password: 'password123'
      });
      expect(done).toHaveBeenCalledWith(null, mockUser);
    });

    it('should handle user creation error', async () => {
      const done = jest.fn();
      const error = new Error('Duplicate email');

      (User.create as jest.Mock).mockRejectedValue(error);

      await signupStrategy._verify('duplicate@example.com', 'password123', done);

      expect(done).toHaveBeenCalledWith(error);
    });
  });

  describe('Login Strategy', () => {
    let loginStrategy: any;

    beforeAll(() => {
      loginStrategy = (passport as any)._strategies.login;
    });

    it('should login user with valid credentials', async () => {
      const mockUser: UserType = {
        id: 1,
        email: 'user@example.com',
        password: 'hashedPassword',
        role: 'default',
        createdAt: new Date(),
        updatedAt: new Date()
      };
      const done = jest.fn();

      (prisma.user.findUnique as jest.Mock).mockResolvedValue(mockUser);
      (User.validatePassword as jest.Mock).mockResolvedValue(true);

      await loginStrategy._verify('user@example.com', 'correctpassword', done);

      expect(prisma.user.findUnique).toHaveBeenCalledWith({ where: { email: 'user@example.com' } });
      expect(User.validatePassword).toHaveBeenCalledWith(mockUser, 'correctpassword');
      expect(done).toHaveBeenCalledWith(null, mockUser, { message: 'Logged in Successfully' });
    });

    it('should reject login with invalid password', async () => {
      const mockUser: UserType = {
        id: 1,
        email: 'user@example.com',
        password: 'hashedPassword',
        role: 'default',
        createdAt: new Date(),
        updatedAt: new Date()
      };
      const done = jest.fn();

      (prisma.user.findUnique as jest.Mock).mockResolvedValue(mockUser);
      (User.validatePassword as jest.Mock).mockResolvedValue(false);

      await loginStrategy._verify('user@example.com', 'wrongpassword', done);

      expect(User.validatePassword).toHaveBeenCalledWith(mockUser, 'wrongpassword');
      expect(done).toHaveBeenCalledWith(null, false, { message: 'Wrong Password' });
    });

    it('should reject login for non-existent user', async () => {
      const done = jest.fn();

      (prisma.user.findUnique as jest.Mock).mockResolvedValue(null);

      await loginStrategy._verify('nonexistent@example.com', 'password', done);

      expect(done).toHaveBeenCalledWith(null, false, { message: 'User not found' });
    });

    it('should handle database error during login', async () => {
      const done = jest.fn();
      const error = new Error('Database connection failed');

      (prisma.user.findUnique as jest.Mock).mockRejectedValue(error);

      await loginStrategy._verify('user@example.com', 'password', done);

      expect(done).toHaveBeenCalledWith(error);
    });
  });
});