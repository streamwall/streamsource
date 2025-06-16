const fs = require('fs');
const path = require('path');
const Sequelize = require('sequelize');

// Mock fs module
jest.mock('fs');

// Mock Sequelize
jest.mock('sequelize');

// Mock the config
jest.mock('../../config/config.js', () => ({
  development: {
    database: 'test_db',
    username: 'test_user',
    password: 'test_pass',
    dialect: 'postgres'
  },
  test: {
    use_env_variable: 'DATABASE_URL'
  },
  production: {
    database: 'prod_db',
    username: 'prod_user',
    password: 'prod_pass'
  }
}));

// Clear module cache before each test
beforeEach(() => {
  jest.clearAllMocks();
  jest.resetModules();
  // Reset environment
  delete process.env.NODE_ENV;
  delete process.env.DATABASE_URL;
});

describe('Models Index', () => {
  it('should load models in development environment', () => {
    // Setup mocks
    const mockFiles = ['index.js', 'user.js', 'stream.js', '.hidden', 'notajs.txt'];
    fs.readdirSync.mockReturnValue(mockFiles);

    const mockUserModel = { name: 'User', associate: jest.fn() };
    const mockStreamModel = { name: 'Stream', associate: jest.fn() };

    // Mock require for model files
    jest.doMock(path.join(__dirname, '../../models/user.js'), () => 
      jest.fn(() => mockUserModel)
    );
    jest.doMock(path.join(__dirname, '../../models/stream.js'), () => 
      jest.fn(() => mockStreamModel)
    );

    // Load the module
    const db = require('../../models/index');

    // Verify Sequelize was initialized with correct config
    expect(Sequelize).toHaveBeenCalledWith('test_db', 'test_user', 'test_pass', {
      database: 'test_db',
      username: 'test_user',
      password: 'test_pass',
      dialect: 'postgres'
    });

    // Verify models were loaded
    expect(db.User).toBe(mockUserModel);
    expect(db.Stream).toBe(mockStreamModel);

    // Verify associates were called
    expect(mockUserModel.associate).toHaveBeenCalledWith(db);
    expect(mockStreamModel.associate).toHaveBeenCalledWith(db);

    // Verify sequelize instances are exported
    expect(db.sequelize).toBeDefined();
    expect(db.Sequelize).toBe(Sequelize);
  });

  it('should use environment variable in test environment', () => {
    process.env.NODE_ENV = 'test';
    process.env.DATABASE_URL = 'postgres://user:pass@localhost:5432/testdb';

    fs.readdirSync.mockReturnValue(['index.js']);

    const db = require('../../models/index');

    expect(Sequelize).toHaveBeenCalledWith('postgres://user:pass@localhost:5432/testdb', {
      use_env_variable: 'DATABASE_URL'
    });
  });

  it('should filter out non-JS files and hidden files', () => {
    const mockFiles = [
      'index.js',
      '.gitignore',
      'README.md',
      'model.json',
      'user.js',
      '.DS_Store'
    ];
    fs.readdirSync.mockReturnValue(mockFiles);

    const mockUserModel = { name: 'User' };
    jest.doMock(path.join(__dirname, '../../models/user.js'), () => 
      jest.fn(() => mockUserModel)
    );

    const db = require('../../models/index');

    // Only user.js should be loaded
    expect(db.User).toBe(mockUserModel);
    expect(Object.keys(db).filter(key => key !== 'sequelize' && key !== 'Sequelize')).toHaveLength(1);
  });

  it('should handle models without associate method', () => {
    fs.readdirSync.mockReturnValue(['index.js', 'simple.js']);

    const mockSimpleModel = { name: 'Simple' }; // No associate method
    jest.doMock(path.join(__dirname, '../../models/simple.js'), () => 
      jest.fn(() => mockSimpleModel)
    );

    const db = require('../../models/index');

    expect(db.Simple).toBe(mockSimpleModel);
    // Should not throw when model has no associate method
  });

  it('should use production config when NODE_ENV is production', () => {
    process.env.NODE_ENV = 'production';
    fs.readdirSync.mockReturnValue(['index.js']);

    const db = require('../../models/index');

    expect(Sequelize).toHaveBeenCalledWith('prod_db', 'prod_user', 'prod_pass', {
      database: 'prod_db',
      username: 'prod_user',
      password: 'prod_pass'
    });
  });

  it('should handle empty models directory', () => {
    fs.readdirSync.mockReturnValue(['index.js']); // Only index.js

    const db = require('../../models/index');

    // Should only have sequelize and Sequelize properties
    expect(Object.keys(db)).toEqual(['sequelize', 'Sequelize']);
  });

  it('should pass DataTypes to model functions', () => {
    fs.readdirSync.mockReturnValue(['index.js', 'test.js']);

    const modelFactory = jest.fn(() => ({ name: 'Test' }));
    jest.doMock(path.join(__dirname, '../../models/test.js'), () => modelFactory);

    const db = require('../../models/index');

    expect(modelFactory).toHaveBeenCalledWith(
      expect.any(Object), // sequelize instance
      Sequelize.DataTypes
    );
  });

  it('should handle multiple models with associations', () => {
    fs.readdirSync.mockReturnValue(['index.js', 'user.js', 'stream.js', 'comment.js']);

    const models = {
      User: { name: 'User', associate: jest.fn() },
      Stream: { name: 'Stream', associate: jest.fn() },
      Comment: { name: 'Comment', associate: jest.fn() }
    };

    jest.doMock(path.join(__dirname, '../../models/user.js'), () => 
      jest.fn(() => models.User)
    );
    jest.doMock(path.join(__dirname, '../../models/stream.js'), () => 
      jest.fn(() => models.Stream)
    );
    jest.doMock(path.join(__dirname, '../../models/comment.js'), () => 
      jest.fn(() => models.Comment)
    );

    const db = require('../../models/index');

    // All associates should be called with the db object
    expect(models.User.associate).toHaveBeenCalledWith(db);
    expect(models.Stream.associate).toHaveBeenCalledWith(db);
    expect(models.Comment.associate).toHaveBeenCalledWith(db);

    // Each model should have access to all other models
    expect(db.User).toBe(models.User);
    expect(db.Stream).toBe(models.Stream);
    expect(db.Comment).toBe(models.Comment);
  });
});