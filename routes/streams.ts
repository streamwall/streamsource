import _ from 'lodash';
import express, { Request, Response, NextFunction } from 'express';
import passport from 'passport';
import { accessControl } from '../auth/authorization';
import { streamValidationRules, handleValidationErrors } from '../middleware/validation';
import { prisma, Stream } from '../lib/prisma';
import { Prisma } from '@prisma/client';
import type { StreamQuery } from '../types';

const router = express.Router();

const ORDERABLE_FIELDS = [
  'source',
  'platform',
  'link',
  'status',
  'isExpired',
  'title',
  'embedLink',
  'postedBy',
  'city',
  'region',
  'checkedAt',
  'liveAt',
  'createdAt',
  'updatedAt',
] as const;

async function getStreams(req: Request<{}, {}, {}, StreamQuery>, res: Response): Promise<void> {
  try {
    const where: Prisma.StreamWhereInput = {
      isExpired: false
    };
    
    let orderBy: Prisma.StreamOrderByWithRelationInput[] = [];
    let format: string | undefined;

    if (req.query) {
      format = req.query.format;

      // String filters with LIKE/ILIKE
      if (req.query.source) {
        where.source = { contains: req.query.source };
      }
      if (req.query.notSource) {
        where.source = { not: { contains: req.query.notSource } };
      }
      if (req.query.platform) {
        where.platform = req.query.platform;
      }
      if (req.query.notPlatform) {
        where.platform = { not: req.query.notPlatform };
      }
      if (req.query.link) {
        where.link = { contains: req.query.link };
      }
      if (req.query.title) {
        where.title = { contains: req.query.title };
      }
      if (req.query.notTitle) {
        where.title = { not: { contains: req.query.notTitle } };
      }
      if (req.query.postedBy) {
        where.postedBy = { contains: req.query.postedBy };
      }
      if (req.query.notPostedBy) {
        where.postedBy = { not: { contains: req.query.notPostedBy } };
      }
      if (req.query.city) {
        where.city = { contains: req.query.city };
      }
      if (req.query.notCity) {
        where.city = { not: { contains: req.query.notCity } };
      }
      if (req.query.region) {
        where.region = { contains: req.query.region };
      }
      if (req.query.notRegion) {
        where.region = { not: { contains: req.query.notRegion } };
      }

      // Status filter
      if (req.query.status && req.query.notStatus) {
        where.status = { not: req.query.notStatus };
      } else if (req.query.status) {
        where.status = req.query.status;
      } else if (req.query.notStatus) {
        where.status = { not: req.query.notStatus };
      }

      // Boolean filters
      if (req.query.isExpired !== undefined) {
        where.isExpired = req.query.isExpired;
      }
      if (req.query.isPinned !== undefined) {
        where.isPinned = req.query.isPinned;
      }

      // Date range filters
      const dateFilters: Array<{ field: keyof Prisma.StreamWhereInput, from?: string, to?: string }> = [
        { field: 'createdAt', from: req.query.createdAtFrom, to: req.query.createdAtTo },
        { field: 'updatedAt', from: req.query.updatedAtFrom, to: req.query.updatedAtTo },
        { field: 'liveAt', from: req.query.liveAtFrom, to: req.query.liveAtTo },
        { field: 'checkedAt', from: req.query.checkedAtFrom, to: req.query.checkedAtTo }
      ];

      dateFilters.forEach(({ field, from, to }) => {
        if (from || to) {
          const dateFilter: any = {};
          if (from) dateFilter.gte = new Date(from);
          if (to) dateFilter.lte = new Date(to);
          where[field] = dateFilter;
        }
      });

      // Order by
      if (req.query.orderFields && req.query.orderDirections) {
        const fields = req.query.orderFields.split(',');
        const directions = req.query.orderDirections.split(',');
        
        fields.forEach((field, index) => {
          if (ORDERABLE_FIELDS.includes(field as any)) {
            const direction = directions[index] === 'desc' ? 'desc' : 'asc';
            orderBy.push({ [field]: direction });
          }
        });
      }
    }

    // Default order if none specified
    if (orderBy.length === 0) {
      orderBy = [{ createdAt: 'desc' }];
    }

    const streams = await prisma.stream.findMany({
      where,
      orderBy
    });

    const data = {
      streams,
      count: streams.length
    };

    if (format === 'array') {
      res.json(streams);
    } else {
      res.json(data);
    }
  } catch (error) {
    console.error('Error fetching streams:', error);
    res.status(500).json({ error: 'Failed to fetch streams' });
  }
}

async function findStream(req: Request<{ id: string }>, res: Response): Promise<void> {
  try {
    const stream = await prisma.stream.findUnique({
      where: { id: parseInt(req.params.id) }
    });

    if (!stream) {
      res.status(404).json({ error: 'Stream not found' });
      return;
    }

    res.json({ stream });
  } catch (error) {
    console.error('Error finding stream:', error);
    res.status(500).json({ error: 'Failed to find stream' });
  }
}

async function createStream(req: Request, res: Response): Promise<void> {
  try {
    const permission = accessControl.can((req as any).user?.role || 'default').createAny('stream');
    
    if (!permission.granted) {
      res.status(403).json({ error: 'Forbidden' });
      return;
    }

    // Normalize the link
    if (req.body.link) {
      req.body.link = Stream.normalizeLink(req.body.link);
    }

    // Infer location if not provided
    const streamData = await Stream.inferLocation(req.body);

    const stream = await Stream.create(streamData);
    res.status(201).json({ stream });
  } catch (error: any) {
    console.error('Error creating stream:', error);
    
    if (error.code === 'P2002') {
      res.status(409).json({ error: 'A stream with this link already exists' });
      return;
    }
    
    res.status(500).json({ error: 'Failed to create stream' });
  }
}

async function updateStream(req: Request<{ id: string }>, res: Response): Promise<void> {
  try {
    const permission = accessControl.can((req as any).user?.role || 'default').updateAny('stream');
    
    if (!permission.granted) {
      res.status(403).json({ error: 'Forbidden' });
      return;
    }

    const streamId = parseInt(req.params.id);
    
    // Check if stream exists and is pinned
    const existingStream = await prisma.stream.findUnique({
      where: { id: streamId }
    });

    if (!existingStream) {
      res.status(404).json({ error: 'Stream not found' });
      return;
    }

    if (existingStream.isPinned) {
      res.status(403).json({ error: 'Cannot update a pinned stream' });
      return;
    }

    // Normalize the link if provided
    if (req.body.link) {
      req.body.link = Stream.normalizeLink(req.body.link);
    }

    const stream = await prisma.stream.update({
      where: { id: streamId },
      data: req.body
    });

    res.json({ stream });
  } catch (error: any) {
    console.error('Error updating stream:', error);
    
    if (error.code === 'P2002') {
      res.status(409).json({ error: 'A stream with this link already exists' });
      return;
    }
    
    res.status(500).json({ error: 'Failed to update stream' });
  }
}

async function deleteStream(req: Request<{ id: string }>, res: Response): Promise<void> {
  try {
    const permission = accessControl.can((req as any).user?.role || 'default').deleteAny('stream');
    
    if (!permission.granted) {
      res.status(403).json({ error: 'Forbidden' });
      return;
    }

    const streamId = parseInt(req.params.id);
    
    // Check if stream exists and is pinned
    const existingStream = await prisma.stream.findUnique({
      where: { id: streamId }
    });

    if (!existingStream) {
      res.status(404).json({ error: 'Stream not found' });
      return;
    }

    if (existingStream.isPinned) {
      res.status(403).json({ error: 'Cannot delete a pinned stream' });
      return;
    }

    await prisma.stream.delete({
      where: { id: streamId }
    });

    res.status(204).send();
  } catch (error) {
    console.error('Error deleting stream:', error);
    res.status(500).json({ error: 'Failed to delete stream' });
  }
}

async function pinStream(req: Request<{ id: string }>, res: Response): Promise<void> {
  try {
    const permission = accessControl.can((req as any).user?.role || 'default').updateAny('stream');
    
    if (!permission.granted) {
      res.status(403).json({ error: 'Forbidden' });
      return;
    }

    const streamId = parseInt(req.params.id);
    
    const stream = await prisma.stream.update({
      where: { id: streamId },
      data: { isPinned: true }
    });

    res.json({ stream });
  } catch (error) {
    console.error('Error pinning stream:', error);
    res.status(500).json({ error: 'Failed to pin stream' });
  }
}

async function unpinStream(req: Request<{ id: string }>, res: Response): Promise<void> {
  try {
    const permission = accessControl.can((req as any).user?.role || 'default').updateAny('stream');
    
    if (!permission.granted) {
      res.status(403).json({ error: 'Forbidden' });
      return;
    }

    const streamId = parseInt(req.params.id);
    
    const stream = await prisma.stream.update({
      where: { id: streamId },
      data: { isPinned: false }
    });

    res.json({ stream });
  } catch (error) {
    console.error('Error unpinning stream:', error);
    res.status(500).json({ error: 'Failed to unpin stream' });
  }
}

// Routes
router.get('/', getStreams);
router.get('/:id', findStream);
router.post('/', 
  passport.authenticate('jwt', { session: false }),
  ...streamValidationRules.create,
  createStream
);
router.patch('/:id',
  passport.authenticate('jwt', { session: false }),
  ...streamValidationRules.update,
  updateStream
);
router.delete('/:id',
  passport.authenticate('jwt', { session: false }),
  deleteStream
);
router.put('/:id/pin',
  passport.authenticate('jwt', { session: false }),
  pinStream
);
router.delete('/:id/pin',
  passport.authenticate('jwt', { session: false }),
  unpinStream
);

export default router;