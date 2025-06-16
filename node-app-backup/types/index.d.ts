// Type definitions for StreamSource

export interface User {
  id: number;
  email: string;
  password: string;
  role: string; // Prisma returns string, we'll validate at runtime
  createdAt: Date;
  updatedAt: Date;
  isValidPassword?: (password: string) => Promise<boolean>;
}

export interface Stream {
  id: number;
  source?: string | null;
  platform?: string | null;
  link: string;
  status: string; // Prisma returns string
  title?: string | null;
  isExpired: boolean;
  checkedAt?: Date | null;
  liveAt?: Date | null;
  embedLink?: string | null;
  postedBy?: string | null;
  isPinned: boolean;
  city?: string | null;
  region?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface JWTPayload {
  user: {
    _id: number;
    email: string;
  };
  iat?: number;
  exp?: number;
}

import { Request } from 'express';

export interface AuthRequest extends Request {
  user?: User;
}

export interface StreamQuery {
  source?: string;
  notSource?: string;
  platform?: string;
  notPlatform?: string;
  link?: string;
  status?: string;
  notStatus?: string;
  isExpired?: boolean;
  isPinned?: boolean;
  title?: string;
  notTitle?: string;
  postedBy?: string;
  notPostedBy?: string;
  city?: string;
  notCity?: string;
  region?: string;
  notRegion?: string;
  createdAtFrom?: string;
  createdAtTo?: string;
  updatedAtFrom?: string;
  updatedAtTo?: string;
  liveAtFrom?: string;
  liveAtTo?: string;
  checkedAtFrom?: string;
  checkedAtTo?: string;
  orderFields?: string;
  orderDirections?: string;
  format?: 'array';
}