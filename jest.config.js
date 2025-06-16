module.exports = {
  testEnvironment: 'node',
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    '**/*.js',
    '!coverage/**',
    '!jest.config.js',
    '!**/node_modules/**',
    '!migrations/**',
    '!config/**',
    '!tests/**',
    '!**/*.test.js',
    '!**/*.spec.js',
    '!bin/www'
  ],
  testMatch: [
    '**/tests/**/*.test.js',
    '**/?(*.)+(spec|test).js'
  ],
  testPathIgnorePatterns: [
    '/node_modules/'
  ],
  coverageThreshold: {
    global: {
      branches: 95,
      functions: 95,
      lines: 99,
      statements: 99
    }
  },
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],
  testTimeout: 10000
};