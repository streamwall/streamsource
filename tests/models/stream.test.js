const { Sequelize, DataTypes, Op } = require('sequelize');

// Create test database instance
const sequelize = new Sequelize('sqlite::memory:', {
  logging: false
});

// Load the model
const StreamModel = require('../../models/stream');
const Stream = StreamModel(sequelize, DataTypes);

describe('Stream Model', () => {
  beforeAll(async () => {
    await sequelize.sync({ force: true });
  });

  afterEach(async () => {
    await Stream.destroy({ where: {}, truncate: true });
  });

  afterAll(async () => {
    await sequelize.close();
  });

  describe('Model Definition', () => {
    it('should have correct model name', () => {
      expect(Stream.name).toBe('Stream');
    });

    it('should have correct fields', () => {
      const fields = Object.keys(Stream.rawAttributes);
      expect(fields).toContain('source');
      expect(fields).toContain('platform');
      expect(fields).toContain('link');
      expect(fields).toContain('status');
      expect(fields).toContain('title');
      expect(fields).toContain('isExpired');
      expect(fields).toContain('checkedAt');
      expect(fields).toContain('liveAt');
      expect(fields).toContain('embedLink');
      expect(fields).toContain('postedBy');
      expect(fields).toContain('isPinned');
      expect(fields).toContain('city');
      expect(fields).toContain('region');
      expect(fields).toContain('state');
    });
  });

  describe('Field Validations', () => {
    it('should require link field', async () => {
      await expect(Stream.create({
        source: 'test_source'
      })).rejects.toThrow('notNull Violation');
    });

    it('should validate link is a URL', async () => {
      await expect(Stream.create({
        link: 'not-a-url'
      })).rejects.toThrow('Validation error');
    });

    it('should accept valid URL for link', async () => {
      const stream = await Stream.create({
        link: 'https://example.com/stream'
      });
      expect(stream.link).toBe('https://example.com/stream');
    });

    it('should validate embedLink is a URL when provided', async () => {
      await expect(Stream.create({
        link: 'https://example.com/stream',
        embedLink: 'not-a-url'
      })).rejects.toThrow('Validation error');
    });

    it('should accept valid URL for embedLink', async () => {
      const stream = await Stream.create({
        link: 'https://example.com/stream',
        embedLink: 'https://example.com/embed'
      });
      expect(stream.embedLink).toBe('https://example.com/embed');
    });
  });

  describe('Default Values', () => {
    it('should default status to "Unknown"', async () => {
      const stream = await Stream.create({
        link: 'https://example.com/stream'
      });
      expect(stream.status).toBe('Unknown');
    });

    it('should default isExpired to false', async () => {
      const stream = await Stream.create({
        link: 'https://example.com/stream'
      });
      expect(stream.isExpired).toBe(false);
    });

    it('should allow null values for optional fields', async () => {
      const stream = await Stream.create({
        link: 'https://example.com/stream'
      });
      
      expect(stream.source).toBeUndefined();
      expect(stream.platform).toBeUndefined();
      expect(stream.title).toBeUndefined();
      expect(stream.embedLink).toBeUndefined();
      expect(stream.postedBy).toBeUndefined();
      expect(stream.isPinned).toBeUndefined();
      expect(stream.city).toBeUndefined();
      expect(stream.region).toBeUndefined();
      expect(stream.checkedAt).toBeUndefined();
      expect(stream.liveAt).toBeUndefined();
    });
  });

  describe('Virtual State Field', () => {
    it('should return region value when accessing state', async () => {
      const stream = await Stream.create({
        link: 'https://example.com/stream',
        region: 'California'
      });
      expect(stream.state).toBe('California');
    });

    it('should throw error when trying to set state', async () => {
      const stream = await Stream.create({
        link: 'https://example.com/stream'
      });
      
      expect(() => {
        stream.state = 'New York';
      }).toThrow('Stream.state is deprecated and read-only. Use Stream.region instead.');
    });
  });

  describe('inferLocation Method', () => {
    it('should not infer location if city is already set', async () => {
      const stream = Stream.build({
        link: 'https://example.com/stream',
        source: 'test_source',
        city: 'Seattle'
      });

      await stream.inferLocation();
      expect(stream.city).toBe('Seattle');
      expect(stream.region).toBeUndefined();
    });

    it('should not infer location if region is already set', async () => {
      const stream = Stream.build({
        link: 'https://example.com/stream',
        source: 'test_source',
        region: 'WA'
      });

      await stream.inferLocation();
      expect(stream.city).toBeUndefined();
      expect(stream.region).toBe('WA');
    });

    it('should infer location from past stream with same link', async () => {
      // Create past stream
      await Stream.create({
        link: 'https://example.com/stream',
        source: 'different_source',
        city: 'Portland',
        region: 'OR'
      });

      // Create new stream with same link
      const newStream = Stream.build({
        link: 'https://example.com/stream',
        source: 'new_source'
      });

      await newStream.inferLocation();
      expect(newStream.city).toBe('Portland');
      expect(newStream.region).toBe('OR');
    });

    it('should infer location from past stream with same source', async () => {
      // Create past stream
      await Stream.create({
        link: 'https://example.com/old-stream',
        source: 'same_source',
        city: 'Chicago',
        region: 'IL'
      });

      // Create new stream with same source
      const newStream = Stream.build({
        link: 'https://example.com/new-stream',
        source: 'same_source'
      });

      await newStream.inferLocation();
      expect(newStream.city).toBe('Chicago');
      expect(newStream.region).toBe('IL');
    });

    it('should use most recent stream for location inference', async () => {
      // Create older stream
      await Stream.create({
        link: 'https://example.com/stream1',
        source: 'moving_source',
        city: 'Boston',
        region: 'MA',
        createdAt: new Date('2020-01-01')
      });

      // Create newer stream
      await Stream.create({
        link: 'https://example.com/stream2',
        source: 'moving_source',
        city: 'New York',
        region: 'NY',
        createdAt: new Date('2021-01-01')
      });

      // Create new stream
      const newStream = Stream.build({
        link: 'https://example.com/stream3',
        source: 'moving_source'
      });

      await newStream.inferLocation();
      expect(newStream.city).toBe('New York');
      expect(newStream.region).toBe('NY');
    });

    it('should set empty strings if no past stream found', async () => {
      const stream = Stream.build({
        link: 'https://example.com/unique-stream',
        source: 'unique_source'
      });

      await stream.inferLocation();
      expect(stream.city).toBe('');
      expect(stream.region).toBe('');
    });

    it('should not match streams without location data', async () => {
      // Create stream without location
      await Stream.create({
        link: 'https://example.com/stream',
        source: 'no_location_source'
      });

      // Create new stream
      const newStream = Stream.build({
        link: 'https://example.com/new-stream',
        source: 'no_location_source'
      });

      await newStream.inferLocation();
      expect(newStream.city).toBe('');
      expect(newStream.region).toBe('');
    });

    it('should handle null source when inferring location', async () => {
      // Create past stream
      await Stream.create({
        link: 'https://example.com/stream',
        city: 'Denver',
        region: 'CO'
      });

      // Create new stream with null source
      const newStream = Stream.build({
        link: 'https://example.com/stream',
        source: null
      });

      await newStream.inferLocation();
      expect(newStream.city).toBe('Denver');
      expect(newStream.region).toBe('CO');
    });
  });

  describe('Hooks', () => {
    it('should call inferLocation before save', async () => {
      // Create past stream
      await Stream.create({
        link: 'https://example.com/stream',
        source: 'hook_test',
        city: 'Miami',
        region: 'FL'
      });

      // Create new stream - inferLocation should be called automatically
      const newStream = await Stream.create({
        link: 'https://example.com/new-stream',
        source: 'hook_test'
      });

      expect(newStream.city).toBe('Miami');
      expect(newStream.region).toBe('FL');
    });

    it('should call inferLocation on update', async () => {
      // Create stream without location
      const stream = await Stream.create({
        link: 'https://example.com/stream',
        source: 'update_test'
      });

      expect(stream.city).toBe('');
      expect(stream.region).toBe('');

      // Create another stream with location
      await Stream.create({
        link: 'https://example.com/other-stream',
        source: 'update_test',
        city: 'Austin',
        region: 'TX'
      });

      // Update first stream - should trigger inferLocation
      stream.title = 'Updated Title';
      await stream.save();

      expect(stream.city).toBe('Austin');
      expect(stream.region).toBe('TX');
    });
  });

  describe('Static Methods', () => {
    it('should have associate method', () => {
      expect(Stream.associate).toBeDefined();
      expect(typeof Stream.associate).toBe('function');
    });

    it('should not throw when calling associate', () => {
      expect(() => Stream.associate({})).not.toThrow();
    });
  });

  describe('Date Fields', () => {
    it('should accept valid dates for checkedAt and liveAt', async () => {
      const checkedAt = new Date('2023-01-01T12:00:00Z');
      const liveAt = new Date('2023-01-01T11:00:00Z');
      
      const stream = await Stream.create({
        link: 'https://example.com/stream',
        checkedAt,
        liveAt
      });

      expect(stream.checkedAt).toEqual(checkedAt);
      expect(stream.liveAt).toEqual(liveAt);
    });
  });

  describe('Boolean Fields', () => {
    it('should handle isPinned boolean values', async () => {
      const pinnedStream = await Stream.create({
        link: 'https://example.com/pinned',
        isPinned: true
      });
      expect(pinnedStream.isPinned).toBe(true);

      const unpinnedStream = await Stream.create({
        link: 'https://example.com/unpinned',
        isPinned: false
      });
      expect(unpinnedStream.isPinned).toBe(false);
    });

    it('should handle isExpired boolean values', async () => {
      const expiredStream = await Stream.create({
        link: 'https://example.com/expired',
        isExpired: true
      });
      expect(expiredStream.isExpired).toBe(true);
    });
  });
});