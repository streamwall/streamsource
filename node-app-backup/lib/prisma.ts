import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
import type { User, Stream } from '../types';

// Create a single instance of PrismaClient
const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'info', 'warn', 'error'] : ['error'],
});

// User model extensions
const userExtensions = {
  // Hash password before creating/updating
  async create(data: Partial<User>): Promise<User> {
    if (data.password) {
      data.password = await bcrypt.hash(data.password, 10);
    }
    return prisma.user.create({ data: data as any });
  },

  async update(where: { id?: number; email?: string }, data: Partial<User>): Promise<User> {
    if (data.password) {
      data.password = await bcrypt.hash(data.password, 10);
    }
    // Ensure we have a valid unique identifier
    const uniqueWhere = where.id ? { id: where.id } : { email: where.email! };
    return prisma.user.update({ where: uniqueWhere, data: data as any });
  },

  // Validate password
  async validatePassword(user: User, password: string): Promise<boolean> {
    return bcrypt.compare(password, user.password);
  }
};

// Stream model extensions
const streamExtensions = {
  // Infer location from past streams
  async inferLocation(stream: Partial<Stream>): Promise<Partial<Stream>> {
    if (stream.city || stream.region) {
      return stream;
    }

    const pastStream = await prisma.stream.findFirst({
      where: {
        OR: [
          { link: stream.link },
          ...(stream.source ? [{ source: stream.source }] : [])
        ],
        AND: [
          {
            OR: [
              { city: { not: null } },
              { region: { not: null } }
            ]
          }
        ]
      },
      orderBy: { createdAt: 'desc' }
    });

    if (pastStream) {
      stream.city = pastStream.city || '';
      stream.region = pastStream.region || '';
    }

    return stream;
  },

  // Create with location inference
  async create(data: Partial<Stream>): Promise<Stream> {
    const inferredData = await this.inferLocation(data);
    return prisma.stream.create({ data: inferredData as any });
  },

  // Normalize link
  normalizeLink(link: string): string {
    let normalizedLink = link;
    normalizedLink = normalizedLink.replace(/\/$/, '');
    normalizedLink = normalizedLink.replace(/https?:\/\/(www\.)?/i, '');
    return normalizedLink;
  }
};

// Export extended Prisma client
export {
  prisma,
  userExtensions as User,
  streamExtensions as Stream
};