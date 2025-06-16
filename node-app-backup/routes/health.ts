import express, { Request, Response } from 'express';
import { prisma } from '../lib/prisma';

const router = express.Router();

/**
 * Health check endpoint
 * Returns 200 if service is healthy, 503 if unhealthy
 */
router.get('/', async (req: Request, res: Response) => {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    database: {
      status: 'checking',
      type: 'prisma' as string,
      error: undefined as string | undefined
    }
  };

  try {
    // Check database connectivity with Prisma
    await prisma.$queryRaw`SELECT 1`;
    health.database.status = 'connected';
  } catch (error: any) {
    health.status = 'unhealthy';
    health.database.status = 'disconnected';
    health.database.error = error.message;
  }

  const statusCode = health.status === 'ok' ? 200 : 503;
  res.status(statusCode).json(health);
});

/**
 * Liveness probe - minimal check
 */
router.get('/live', (req: Request, res: Response) => {
  res.status(200).json({ status: 'alive' });
});

/**
 * Readiness probe - checks if app is ready to serve traffic
 */
router.get('/ready', async (req: Request, res: Response) => {
  try {
    // Quick database check with Prisma
    await prisma.$queryRaw`SELECT 1`;
    res.status(200).json({ status: 'ready' });
  } catch (error: any) {
    res.status(503).json({ status: 'not ready', error: error.message });
  }
});

export default router;