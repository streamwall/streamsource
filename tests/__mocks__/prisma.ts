import { PrismaClient } from '@prisma/client';
import { DeepMockProxy, mockDeep, mockReset } from 'jest-mock-extended';

// Create a deep mock of PrismaClient
export const prismaMock = mockDeep<PrismaClient>();

// Mock the prisma module
jest.mock('../../lib/prisma', () => ({
  __esModule: true,
  prisma: prismaMock,
  User: {
    create: jest.fn(),
    update: jest.fn(),
    validatePassword: jest.fn()
  },
  Stream: {
    create: jest.fn(),
    inferLocation: jest.fn(),
    normalizeLink: jest.fn()
  }
}));

// Reset mocks before each test
beforeEach(() => {
  mockReset(prismaMock);
});