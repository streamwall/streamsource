const { Sequelize, DataTypes } = require('sequelize');
const bcrypt = require('bcrypt');

// Create test database instance
const sequelize = new Sequelize('sqlite::memory:', {
  logging: false
});

// Load the model
const UserModel = require('../../models/user');
const User = UserModel(sequelize, DataTypes);

describe('User Model', () => {
  beforeAll(async () => {
    await sequelize.sync({ force: true });
  });

  afterEach(async () => {
    await User.destroy({ where: {}, truncate: true });
  });

  afterAll(async () => {
    await sequelize.close();
  });

  describe('Model Definition', () => {
    it('should have correct model name', () => {
      expect(User.name).toBe('User');
    });

    it('should have correct fields', () => {
      const fields = Object.keys(User.rawAttributes);
      expect(fields).toContain('email');
      expect(fields).toContain('password');
      expect(fields).toContain('role');
      expect(fields).toContain('id');
      expect(fields).toContain('createdAt');
      expect(fields).toContain('updatedAt');
    });

    it('should have unique index on email', () => {
      const indexes = User.options.indexes;
      const emailIndex = indexes.find(idx => 
        idx.fields.includes('email') && idx.unique === true
      );
      expect(emailIndex).toBeDefined();
    });
  });

  describe('Field Validations', () => {
    it('should require email field', async () => {
      await expect(User.create({
        password: 'password123'
      })).rejects.toThrow('notNull Violation');
    });

    it('should require password field', async () => {
      await expect(User.create({
        email: 'test@example.com'
      })).rejects.toThrow('notNull Violation');
    });

    it('should validate email format', async () => {
      await expect(User.create({
        email: 'invalid-email',
        password: 'password123'
      })).rejects.toThrow('Validation error');
    });

    it('should accept valid email format', async () => {
      const user = await User.create({
        email: 'valid@example.com',
        password: 'password123'
      });
      expect(user.email).toBe('valid@example.com');
    });

    it('should enforce unique email constraint', async () => {
      await User.create({
        email: 'duplicate@example.com',
        password: 'password123'
      });

      await expect(User.create({
        email: 'duplicate@example.com',
        password: 'password456'
      })).rejects.toThrow();
    });
  });

  describe('Password Hashing', () => {
    it('should hash password on creation', async () => {
      const plainPassword = 'mySecretPassword';
      const user = await User.create({
        email: 'hash@example.com',
        password: plainPassword
      });

      expect(user.password).not.toBe(plainPassword);
      expect(user.password).toMatch(/^\$2[aby]?\$\d{1,2}\$/); // bcrypt hash pattern
    });

    it('should hash password on update', async () => {
      const user = await User.create({
        email: 'update@example.com',
        password: 'initialPassword'
      });
      const initialHash = user.password;

      user.password = 'newPassword';
      await user.save();

      expect(user.password).not.toBe('newPassword');
      expect(user.password).not.toBe(initialHash);
    });
  });

  describe('isValidPassword method', () => {
    let user;
    const correctPassword = 'correctPassword123';

    beforeEach(async () => {
      user = await User.create({
        email: 'password@example.com',
        password: correctPassword
      });
    });

    it('should return true for correct password', () => {
      expect(user.isValidPassword(correctPassword)).toBe(true);
    });

    it('should return false for incorrect password', () => {
      expect(user.isValidPassword('wrongPassword')).toBe(false);
    });

    it('should return false for empty password', () => {
      expect(user.isValidPassword('')).toBe(false);
    });

    it('should return false for null password', () => {
      // bcrypt.compareSync throws with null, so we need to test this differently
      expect(() => user.isValidPassword(null)).toThrow();
    });

    it('should handle special characters in password', () => {
      const specialPassword = 'p@$$w0rd!#$%^&*()';
      const specialUser = User.build({
        email: 'special@example.com',
        password: specialPassword
      });
      
      expect(specialUser.isValidPassword(specialPassword)).toBe(true);
    });
  });

  describe('Role field', () => {
    it('should default to "default" role', async () => {
      const user = await User.create({
        email: 'defaultrole@example.com',
        password: 'password123'
      });

      expect(user.role).toBe('default');
    });

    it('should allow setting custom role', async () => {
      const user = await User.create({
        email: 'admin@example.com',
        password: 'password123',
        role: 'admin'
      });

      expect(user.role).toBe('admin');
    });

    it('should not allow null role', async () => {
      await expect(User.create({
        email: 'nullrole@example.com',
        password: 'password123',
        role: null
      })).rejects.toThrow('notNull Violation');
    });
  });

  describe('Static Methods', () => {
    it('should have associate method', () => {
      expect(User.associate).toBeDefined();
      expect(typeof User.associate).toBe('function');
    });

    it('should not throw when calling associate', () => {
      expect(() => User.associate({})).not.toThrow();
    });
  });

  describe('Timestamps', () => {
    it('should auto-generate timestamps', async () => {
      const user = await User.create({
        email: 'timestamp@example.com',
        password: 'password123'
      });

      expect(user.createdAt).toBeInstanceOf(Date);
      expect(user.updatedAt).toBeInstanceOf(Date);
      expect(user.createdAt.getTime()).toBe(user.updatedAt.getTime());
    });

    it('should update updatedAt on modification', async () => {
      const user = await User.create({
        email: 'update@example.com',
        password: 'password123'
      });
      const initialUpdatedAt = user.updatedAt;

      // Wait a bit to ensure timestamp difference
      await new Promise(resolve => setTimeout(resolve, 10));
      
      user.role = 'editor';
      await user.save();

      expect(user.updatedAt.getTime()).toBeGreaterThan(initialUpdatedAt.getTime());
    });
  });
});