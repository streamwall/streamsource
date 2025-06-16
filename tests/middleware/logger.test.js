const winston = require('winston');
const LogdnaWinston = require('logdna-winston');
const expressWinston = require('express-winston');

// Mock all the dependencies
jest.mock('winston', () => ({
  format: {
    prettyPrint: jest.fn(() => 'prettyPrintFormat')
  },
  transports: {
    Console: jest.fn()
  }
}));

jest.mock('logdna-winston');
jest.mock('express-winston', () => ({
  logger: jest.fn(() => 'loggerMiddleware'),
  errorLogger: jest.fn(() => 'errorLoggerMiddleware')
}));

// Clear module cache to ensure fresh import
beforeEach(() => {
  jest.clearAllMocks();
  jest.resetModules();
  // Set required env var
  process.env.LOGDNA_INGESTION_KEY = 'test-key';
});

describe('Logger Middleware', () => {
  it('should create logger with console and LogDNA transports', () => {
    const { logger } = require('../../middleware/logger');

    expect(expressWinston.logger).toHaveBeenCalledWith({
      transports: expect.arrayContaining([
        expect.any(winston.transports.Console),
        expect.any(LogdnaWinston)
      ]),
      exitOnError: false
    });

    expect(logger).toBe('loggerMiddleware');
  });

  it('should create error logger with console and LogDNA transports', () => {
    const { errorLogger } = require('../../middleware/logger');

    expect(expressWinston.errorLogger).toHaveBeenCalledWith({
      transports: expect.arrayContaining([
        expect.any(winston.transports.Console),
        expect.any(LogdnaWinston)
      ]),
      exitOnError: false
    });

    expect(errorLogger).toBe('errorLoggerMiddleware');
  });

  it('should configure Console transport with correct options', () => {
    require('../../middleware/logger');

    expect(winston.transports.Console).toHaveBeenCalledWith({
      level: 'debug',
      handleExceptions: true,
      format: 'prettyPrintFormat'
    });

    expect(winston.format.prettyPrint).toHaveBeenCalledWith({ colorize: true });
  });

  it('should configure LogDNA transport with correct options', () => {
    require('../../middleware/logger');

    expect(LogdnaWinston).toHaveBeenCalledWith({
      key: 'test-key',
      app: 'StreamSource',
      handleExceptions: true
    });
  });

  it('should use LOGDNA_INGESTION_KEY from environment', () => {
    process.env.LOGDNA_INGESTION_KEY = 'custom-ingestion-key';
    
    require('../../middleware/logger');

    expect(LogdnaWinston).toHaveBeenCalledWith(
      expect.objectContaining({
        key: 'custom-ingestion-key'
      })
    );
  });

  it('should export both logger and errorLogger', () => {
    const loggerModule = require('../../middleware/logger');

    expect(loggerModule).toHaveProperty('logger');
    expect(loggerModule).toHaveProperty('errorLogger');
    expect(loggerModule.logger).toBe('loggerMiddleware');
    expect(loggerModule.errorLogger).toBe('errorLoggerMiddleware');
  });

  it('should create exactly 2 transports for logger', () => {
    require('../../middleware/logger');

    expect(expressWinston.logger).toHaveBeenCalled();
    const loggerCall = expressWinston.logger.mock.calls[0];
    if (loggerCall && loggerCall[0]) {
      expect(loggerCall[0].transports).toHaveLength(2);
    }
  });

  it('should create exactly 2 transports for errorLogger', () => {
    require('../../middleware/logger');

    expect(expressWinston.errorLogger).toHaveBeenCalled();
    const errorLoggerCall = expressWinston.errorLogger.mock.calls[0];
    if (errorLoggerCall && errorLoggerCall[0]) {
      expect(errorLoggerCall[0].transports).toHaveLength(2);
    }
  });

  it('should set exitOnError to false for both loggers', () => {
    require('../../middleware/logger');

    expect(expressWinston.logger).toHaveBeenCalled();
    expect(expressWinston.errorLogger).toHaveBeenCalled();
    
    const loggerCall = expressWinston.logger.mock.calls[0];
    const errorLoggerCall = expressWinston.errorLogger.mock.calls[0];

    if (loggerCall && loggerCall[0]) {
      expect(loggerCall[0].exitOnError).toBe(false);
    }
    if (errorLoggerCall && errorLoggerCall[0]) {
      expect(errorLoggerCall[0].exitOnError).toBe(false);
    }
  });
});