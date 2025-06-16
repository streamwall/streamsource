import { body, query, param, validationResult, ValidationChain } from 'express-validator';
import { Request, Response, NextFunction } from 'express';

// Validation middleware
export const handleValidationErrors = (req: Request, res: Response, next: NextFunction): void => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res.status(400).json({ errors: errors.array() });
    return;
  }
  next();
};

// Stream validation rules
export const streamValidationRules = {
  create: [
    body('link').isURL().withMessage('Link must be a valid URL'),
    body('source').optional().isString().trim().escape(),
    body('platform').optional().isString().trim().escape(),
    body('title').optional().isString().trim().escape(),
    body('postedBy').optional().isString().trim().escape(),
    body('city').optional().isString().trim().escape(),
    body('region').optional().isString().trim().escape(),
    body('status').optional().isIn(['Live', 'Offline', 'Unknown']).withMessage('Invalid status'),
    handleValidationErrors
  ] as ValidationChain[],
  
  update: [
    param('id').isInt().withMessage('Invalid stream ID'),
    body('link').optional().isURL().withMessage('Link must be a valid URL'),
    body('source').optional().isString().trim().escape(),
    body('platform').optional().isString().trim().escape(),
    body('title').optional().isString().trim().escape(),
    body('embedLink').optional().isURL().withMessage('Embed link must be a valid URL'),
    body('postedBy').optional().isString().trim().escape(),
    body('city').optional().isString().trim().escape(),
    body('region').optional().isString().trim().escape(),
    body('status').optional().isIn(['Live', 'Offline', 'Unknown']).withMessage('Invalid status'),
    body('isExpired').optional().isBoolean(),
    body('isPinned').optional().isBoolean(),
    body('checkedAt').optional().isISO8601(),
    body('liveAt').optional().isISO8601(),
    handleValidationErrors
  ] as ValidationChain[],
  
  list: [
    query('source').optional().isString().trim().escape(),
    query('notSource').optional().isString().trim().escape(),
    query('platform').optional().isString().trim().escape(),
    query('notPlatform').optional().isString().trim().escape(),
    query('link').optional().isString().trim(),
    query('status').optional().isIn(['Live', 'Offline', 'Unknown']),
    query('notStatus').optional().isIn(['Live', 'Offline', 'Unknown']),
    query('isPinned').optional().isBoolean(),
    query('isExpired').optional().isBoolean(),
    query('title').optional().isString().trim().escape(),
    query('notTitle').optional().isString().trim().escape(),
    query('postedBy').optional().isString().trim().escape(),
    query('notPostedBy').optional().isString().trim().escape(),
    query('city').optional().isString().trim().escape(),
    query('notCity').optional().isString().trim().escape(),
    query('region').optional().isString().trim().escape(),
    query('notRegion').optional().isString().trim().escape(),
    query('createdAtFrom').optional().isISO8601(),
    query('createdAtTo').optional().isISO8601(),
    query('checkedAtFrom').optional().isISO8601(),
    query('checkedAtTo').optional().isISO8601(),
    query('liveAtFrom').optional().isISO8601(),
    query('liveAtTo').optional().isISO8601(),
    query('orderFields').optional().isString(),
    query('orderDirections').optional().isString(),
    query('format').optional().isIn(['array']),
    handleValidationErrors
  ] as ValidationChain[]
};

// User validation rules
export const userValidationRules = {
  signup: [
    body('email').isEmail().normalizeEmail().withMessage('Invalid email address'),
    body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters long'),
    body('password').matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/).withMessage('Password must contain at least one uppercase letter, one lowercase letter, and one number'),
    handleValidationErrors
  ] as ValidationChain[],
  
  login: [
    body('email').isEmail().normalizeEmail().withMessage('Invalid email address'),
    body('password').notEmpty().withMessage('Password is required'),
    handleValidationErrors
  ] as ValidationChain[]
};