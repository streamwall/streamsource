const dotenv = require('dotenv');
const path = require('path');

// Load test environment variables
dotenv.config({ path: path.join(__dirname, '..', '.env.test') });

// Set NODE_ENV to test
process.env.NODE_ENV = 'test';

// Disable console logging during tests
if (process.env.NODE_ENV === 'test') {
  global.console = {
    ...console,
    log: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    info: jest.fn(),
    debug: jest.fn(),
  };
}

// Global test timeout
jest.setTimeout(10000);

// Clean up after all tests
afterAll(async () => {
  try {
    // Close any open database connections
    const db = require('../models');
    if (db && db.sequelize && typeof db.sequelize.close === 'function') {
      await db.sequelize.close();
    }
  } catch (error) {
    // Ignore errors during cleanup
  }
});