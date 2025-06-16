// Mock modules before requiring www
jest.mock('http');
jest.mock('debug', () => jest.fn(() => jest.fn()));
jest.mock('../../app', () => ({
  default: {
    set: jest.fn(),
    get: jest.fn()
  }
}));

import http from 'http';
import type { Server } from 'http';

describe('bin/www', () => {
  let mockServer: any;
  let originalEnv: string | undefined;
  let originalExit: any;
  let originalConsoleError: any;

  beforeEach(() => {
    jest.clearAllMocks();
    
    // Save original values
    originalEnv = process.env.PORT;
    originalExit = process.exit;
    originalConsoleError = console.error;
    
    // Mock process.exit and console.error
    process.exit = jest.fn() as any;
    console.error = jest.fn();
    
    // Mock server
    mockServer = {
      listen: jest.fn(),
      on: jest.fn(),
      address: jest.fn()
    };
    (http.createServer as jest.Mock).mockReturnValue(mockServer);
  });

  afterEach(() => {
    // Restore original values
    if (originalEnv !== undefined) {
      process.env.PORT = originalEnv;
    } else {
      delete process.env.PORT;
    }
    process.exit = originalExit;
    console.error = originalConsoleError;
    jest.resetModules();
  });

  describe('Server initialization', () => {
    it('should use default port 3000 when PORT env is not set', () => {
      delete process.env.PORT;
      
      const wwwModule = require('../../bin/www.ts');
      const app = require('../../app').default;
      
      expect(app.set).toHaveBeenCalledWith('port', 3000);
    });

    it('should use PORT from environment variable', () => {
      process.env.PORT = '8080';
      
      jest.resetModules();
      const wwwModule = require('../../bin/www.ts');
      const app = require('../../app').default;
      
      expect(app.set).toHaveBeenCalledWith('port', 8080);
    });

    it('should handle named pipe', () => {
      process.env.PORT = 'mypipe';
      
      jest.resetModules();
      const wwwModule = require('../../bin/www.ts');
      const app = require('../../app').default;
      
      expect(app.set).toHaveBeenCalledWith('port', 'mypipe');
    });

    it('should return false for negative port', () => {
      process.env.PORT = '-1';
      
      jest.resetModules();
      const wwwModule = require('../../bin/www.ts');
      const app = require('../../app').default;
      
      expect(app.set).toHaveBeenCalledWith('port', false);
    });

    it('should create HTTP server with app', () => {
      const wwwModule = require('../../bin/www.ts');
      const app = require('../../app').default;
      
      expect(http.createServer).toHaveBeenCalledWith(app);
    });
  });

  describe('Error handling', () => {
    let onError: (error: NodeJS.ErrnoException) => void;
    let wwwModule: any;

    beforeEach(() => {
      jest.resetModules();
      wwwModule = require('../../bin/www.ts');
      onError = wwwModule.onError;
    });

    it('should throw error if syscall is not listen', () => {
      const error = new Error('Some error') as NodeJS.ErrnoException;
      error.syscall = 'connect';
      
      expect(() => onError(error)).toThrow(error);
    });

    it('should handle EACCES error', () => {
      const error = new Error('Permission denied') as NodeJS.ErrnoException;
      error.syscall = 'listen';
      error.code = 'EACCES';
      
      onError(error);
      
      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('requires elevated privileges'));
      expect(process.exit).toHaveBeenCalledWith(1);
    });

    it('should handle EADDRINUSE error', () => {
      const error = new Error('Address in use') as NodeJS.ErrnoException;
      error.syscall = 'listen';
      error.code = 'EADDRINUSE';
      
      onError(error);
      
      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('is already in use'));
      expect(process.exit).toHaveBeenCalledWith(1);
    });

    it('should throw other errors', () => {
      const error = new Error('Unknown error') as NodeJS.ErrnoException;
      error.syscall = 'listen';
      error.code = 'UNKNOWN';
      
      expect(() => onError(error)).toThrow(error);
    });
  });

  describe('normalizePort function', () => {
    it('should handle all port normalization cases', () => {
      jest.resetModules();
      const wwwModule = require('../../bin/www.ts');
      const normalizePort = wwwModule.normalizePort;
      
      expect(normalizePort('3000')).toBe(3000);
      expect(normalizePort('mypipe')).toBe('mypipe');
      expect(normalizePort('-1')).toBe(false);
      expect(normalizePort('0')).toBe(0);
    });
  });
});