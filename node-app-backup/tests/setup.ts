import dotenv from 'dotenv';
import path from 'path';
import { prisma } from '../lib/prisma';

// Load test environment variables
dotenv.config({ path: path.join(__dirname, '..', '.env.test') });

// Set NODE_ENV to test
process.env.NODE_ENV = 'test';

// Set JWT_SECRET for tests if not already set
if (!process.env.JWT_SECRET) {
  process.env.JWT_SECRET = 'test-secret-key-for-testing-only';
}

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
    // Disconnect Prisma client
    await prisma.$disconnect();
  } catch (error) {
    // Ignore errors during cleanup
  }
});