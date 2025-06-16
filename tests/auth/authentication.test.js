const passport = require('passport');
const { User } = require('../../models');
require('../../auth/authentication');

// Mock the User model
jest.mock('../../models', () => ({
  User: {
    findOne: jest.fn(),
    create: jest.fn()
  }
}));

describe('Authentication Strategies', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('JWT Strategy', () => {
    let jwtStrategy;
    
    beforeAll(() => {
      // Get the JWT strategy
      jwtStrategy = passport._strategies.jwt;
    });

    it('should authenticate valid JWT token', async () => {
      const mockUser = { id: 1, email: 'test@example.com', role: 'default' };
      const mockToken = { user: { email: 'test@example.com' } };
      const done = jest.fn();

      User.findOne.mockResolvedValue(mockUser);

      await jwtStrategy._verify(mockToken, done);

      expect(User.findOne).toHaveBeenCalledWith({ where: { email: 'test@example.com' } });
      expect(done).toHaveBeenCalledWith(null, mockUser);
    });

    it('should handle user not found', async () => {
      const mockToken = { user: { email: 'notfound@example.com' } };
      const done = jest.fn();

      User.findOne.mockResolvedValue(null);

      await jwtStrategy._verify(mockToken, done);

      expect(User.findOne).toHaveBeenCalledWith({ where: { email: 'notfound@example.com' } });
      expect(done).toHaveBeenCalledWith(null, null);
    });

    it('should handle database error', async () => {
      const mockToken = { user: { email: 'test@example.com' } };
      const done = jest.fn();
      const error = new Error('Database error');

      User.findOne.mockRejectedValue(error);

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
    let signupStrategy;

    beforeAll(() => {
      signupStrategy = passport._strategies.signup;
    });

    it('should create new user successfully', async () => {
      const mockUser = { 
        id: 1, 
        email: 'newuser@example.com',
        password: 'hashedPassword' 
      };
      const done = jest.fn();

      User.create.mockResolvedValue(mockUser);

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

      User.create.mockRejectedValue(error);

      await signupStrategy._verify('duplicate@example.com', 'password123', done);

      expect(done).toHaveBeenCalledWith(error);
    });
  });

  describe('Login Strategy', () => {
    let loginStrategy;

    beforeAll(() => {
      loginStrategy = passport._strategies.login;
    });

    it('should login user with valid credentials', async () => {
      const mockUser = {
        id: 1,
        email: 'user@example.com',
        isValidPassword: jest.fn().mockResolvedValue(true)
      };
      const done = jest.fn();

      User.findOne.mockResolvedValue(mockUser);

      await loginStrategy._verify('user@example.com', 'correctpassword', done);

      expect(User.findOne).toHaveBeenCalledWith({ where: { email: 'user@example.com' } });
      expect(mockUser.isValidPassword).toHaveBeenCalledWith('correctpassword');
      expect(done).toHaveBeenCalledWith(null, mockUser, { message: 'Logged in Successfully' });
    });

    it('should reject login with invalid password', async () => {
      const mockUser = {
        id: 1,
        email: 'user@example.com',
        isValidPassword: jest.fn().mockResolvedValue(false)
      };
      const done = jest.fn();

      User.findOne.mockResolvedValue(mockUser);

      await loginStrategy._verify('user@example.com', 'wrongpassword', done);

      expect(mockUser.isValidPassword).toHaveBeenCalledWith('wrongpassword');
      expect(done).toHaveBeenCalledWith(null, false, { message: 'Wrong Password' });
    });

    it('should reject login for non-existent user', async () => {
      const done = jest.fn();

      User.findOne.mockResolvedValue(null);

      await loginStrategy._verify('nonexistent@example.com', 'password', done);

      expect(done).toHaveBeenCalledWith(null, false, { message: 'User not found' });
    });

    it('should handle database error during login', async () => {
      const done = jest.fn();
      const error = new Error('Database connection failed');

      User.findOne.mockRejectedValue(error);

      await loginStrategy._verify('user@example.com', 'password', done);

      expect(done).toHaveBeenCalledWith(error);
    });
  });
});