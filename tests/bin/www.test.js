// Mock modules before requiring www
jest.mock('http');
jest.mock('debug', () => jest.fn(() => jest.fn()));
jest.mock('../../app', () => ({
  set: jest.fn()
}));

const http = require('http');
const debug = require('debug');
const app = require('../../app');

describe('bin/www', () => {
  let mockServer;
  let originalEnv;
  let originalExit;
  let originalConsoleError;

  beforeEach(() => {
    jest.clearAllMocks();
    
    // Save original values
    originalEnv = process.env.PORT;
    originalExit = process.exit;
    originalConsoleError = console.error;
    
    // Mock process.exit and console.error
    process.exit = jest.fn();
    console.error = jest.fn();
    
    // Mock server
    mockServer = {
      listen: jest.fn(),
      on: jest.fn(),
      address: jest.fn()
    };
    http.createServer.mockReturnValue(mockServer);
  });

  afterEach(() => {
    // Restore original values
    process.env.PORT = originalEnv;
    process.exit = originalExit;
    console.error = originalConsoleError;
  });

  describe('Server initialization', () => {
    it('should use default port 3000 when PORT env is not set', () => {
      delete process.env.PORT;
      
      require('../../bin/www');
      
      expect(app.set).toHaveBeenCalledWith('port', 3000);
      expect(mockServer.listen).toHaveBeenCalledWith(3000);
    });

    it('should use PORT from environment variable', () => {
      process.env.PORT = '8080';
      
      jest.resetModules();
      require('../../bin/www');
      
      expect(app.set).toHaveBeenCalledWith('port', 8080);
      expect(mockServer.listen).toHaveBeenCalledWith(8080);
    });

    it('should handle named pipe', () => {
      process.env.PORT = 'mypipe';
      
      jest.resetModules();
      require('../../bin/www');
      
      expect(app.set).toHaveBeenCalledWith('port', 'mypipe');
      expect(mockServer.listen).toHaveBeenCalledWith('mypipe');
    });

    it('should return false for negative port', () => {
      process.env.PORT = '-1';
      
      jest.resetModules();
      require('../../bin/www');
      
      expect(app.set).toHaveBeenCalledWith('port', false);
      expect(mockServer.listen).toHaveBeenCalledWith(false);
    });

    it('should create HTTP server with app', () => {
      require('../../bin/www');
      
      expect(http.createServer).toHaveBeenCalledWith(app);
    });

    it('should register error and listening event handlers', () => {
      require('../../bin/www');
      
      expect(mockServer.on).toHaveBeenCalledWith('error', expect.any(Function));
      expect(mockServer.on).toHaveBeenCalledWith('listening', expect.any(Function));
    });
  });

  describe('Error handling', () => {
    let onError;

    beforeEach(() => {
      require('../../bin/www');
      onError = mockServer.on.mock.calls.find(call => call[0] === 'error')[1];
    });

    it('should throw error if syscall is not listen', () => {
      const error = new Error('Some error');
      error.syscall = 'connect';
      
      expect(() => onError(error)).toThrow(error);
    });

    it('should handle EACCES error', () => {
      const error = new Error('Permission denied');
      error.syscall = 'listen';
      error.code = 'EACCES';
      
      onError(error);
      
      expect(console.error).toHaveBeenCalledWith('Port 3000 requires elevated privileges');
      expect(process.exit).toHaveBeenCalledWith(1);
    });

    it('should handle EADDRINUSE error', () => {
      const error = new Error('Address in use');
      error.syscall = 'listen';
      error.code = 'EADDRINUSE';
      
      onError(error);
      
      expect(console.error).toHaveBeenCalledWith('Port 3000 is already in use');
      expect(process.exit).toHaveBeenCalledWith(1);
    });

    it('should handle string port in error message', () => {
      process.env.PORT = 'mypipe';
      jest.resetModules();
      require('../../bin/www');
      
      onError = mockServer.on.mock.calls.find(call => call[0] === 'error')[1];
      
      const error = new Error('Permission denied');
      error.syscall = 'listen';
      error.code = 'EACCES';
      
      onError(error);
      
      expect(console.error).toHaveBeenCalledWith('Pipe mypipe requires elevated privileges');
    });

    it('should throw other errors', () => {
      const error = new Error('Unknown error');
      error.syscall = 'listen';
      error.code = 'UNKNOWN';
      
      expect(() => onError(error)).toThrow(error);
    });
  });

  describe('Listening event', () => {
    let onListening;
    let debugLog;

    beforeEach(() => {
      debugLog = jest.fn();
      debug.mockReturnValue(debugLog);
      
      jest.resetModules();
      require('../../bin/www');
      
      onListening = mockServer.on.mock.calls.find(call => call[0] === 'listening')[1];
    });

    it('should log port when listening on numeric port', () => {
      mockServer.address.mockReturnValue({ port: 3000 });
      
      onListening();
      
      expect(debugLog).toHaveBeenCalledWith('Listening on port 3000');
    });

    it('should log pipe name when listening on named pipe', () => {
      mockServer.address.mockReturnValue('/tmp/app.sock');
      
      onListening();
      
      expect(debugLog).toHaveBeenCalledWith('Listening on pipe /tmp/app.sock');
    });
  });

  describe('normalizePort function', () => {
    it('should handle all port normalization cases', () => {
      // This is tested implicitly through the server initialization tests
      // but we ensure all branches are covered:
      // - Valid numeric port (default case)
      // - Named pipe (non-numeric string)
      // - Negative port number
      // - Zero port number
      
      process.env.PORT = '0';
      jest.resetModules();
      require('../../bin/www');
      
      expect(app.set).toHaveBeenCalledWith('port', 0);
    });
  });
});