const _ = require('lodash')
const { Op, ValidationError } = require("sequelize");
const express = require('express');
const passport = require("passport");
const { accessControl } = require("../auth/authorization");
const router = express.Router();

const { Stream } = require('../models')

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
]

async function getStreams(req, res) {
  const filter = {
    isExpired: { [Op.not]: true }
  }
  let order
  let format

  if (req.query) {
    format = req.query.format

    // Non-date-related
    const filterRules = {
      source:      {
        field: 'source',
        rule:  { [Op.iLike]: `%${req.query.source}%`, }
      },
      notSource:   {
        field: 'source',
        rule:  { [Op.notILike]: `%${req.query.notSource}%`, }
      },
      platform:    {
        field: 'platform',
        rule:  { [Op.eq]: `${req.query.platform}`, }
      },
      notPlatform: {
        field: 'platform',
        rule:  { [Op.not]: `${req.query.notPlatform}`, }
      },
      link:        {
        field: 'link',
        rule:  { [Op.iLike]: `%${req.query.link}%`, }
      },
      status:      {
        field: 'status',
        rule:  { [Op.eq]: req.query.status }
      },
      notStatus:   {
        field: 'status',
        rule:  { [Op.notEq]: req.query.status }
      },
      isExpired:   {
        field: 'isExpired',
        rule:  { [req.query.isExpired ? Op.is : Op.not]: true, }
      },
      title:       {
        field: 'title',
        rule:  { [Op.iLike]: `%${req.query.title}%` }
      },
      notTitle:    {
        field: 'title',
        rule:  { [Op.notILike]: `%${req.query.notTitle}%`, }
      },
      postedBy:    {
        field: 'postedBy',
        rule:  { [Op.iLike]: `%${req.query.postedBy}%` }
      },
      notPostedBy: {
        field: 'postedBy',
        rule:  { [Op.notILike]: `%${req.query.notPostedBy}%`, }
      },
      city:        {
        field: 'city',
        rule:  { [Op.iLike]: `%${req.query.city}%` }
      },
      notCity:     {
        field: 'city',
        rule:  { [Op.notILike]: `%${req.query.notCity}%`, }
      },
      region:      {
        field: 'region',
        rule:  { [Op.iLike]: `%${req.query.region}%` }
      },
      notRegion:   {
        field: 'region',
        rule:  { [Op.notILike]: `%${req.query.notRegion}%`, }
      },
    }

    Object.entries(filterRules).forEach(([ruleName, filterRule]) => {
      if (!req.query[ruleName]) {
        return
      }
      filter[filterRule.field] = filterRule.rule
    })

    // Set Date-range filters
    const dateFilters = [
      'createdAt',
      'updatedAt',
      'liveAt',
      'checkedAt'
    ]
    dateFilters.forEach((fieldName) => {
      const toParam = req.query[`${fieldName}To`]
      const fromParam = req.query[`${fieldName}From`]
      if (fromParam || toParam) {
        filter[fieldName] = {
          [Op.or]: {
            [Op.lt]: toParam || new Date(),
            [Op.eq]: null,
          },
          [Op.or]: {
            [Op.gt]: fromParam || new Date(0),
            [Op.eq]: null,
          }
        }
      }
    })

    // Set order
    let orderFields
    let orderDirections
    if (req.query.orderFields ^ req.query.orderDirections) {
      const errorResponse = { error: `Ordering requires both orderFields and orderDirections params to be sent` }
      res.status(400).json(errorResponse)
      return
    }
    if (req.query.orderFields && req.query.orderDirections) {
      orderFields = req.query.orderFields.split(',')
      orderDirections = req.query.orderDirections.split(',')
      if (orderFields.length !== orderDirections.length) {
        const errorResponse = { error: `orderFields and orderDirections must have the same length` }
        res.status(400).json(errorResponse)
        return
      }
      const invalidOrderFields = orderFields.filter((fieldName) => !ORDERABLE_FIELDS.includes(fieldName))
      if (invalidOrderFields.length > 0) {
        res.status(400).json({ error: `Cannot order by fields: ${invalidOrderFields.join(', ')}` })
        return
      }
      order = orderFields.map((fieldName, i) => {
        return [orderFields[i], orderDirections[i]]
      })
    }
  }

  order = order || [['createdAt', 'DESC']]
  const queryOptions = {
    where: filter,
    order
  }
  console.log(queryOptions)
  const streams = await Stream.findAll(queryOptions)
  const response = format === 'array' ? streams : { data: streams }
  res.status(200).json(response)
}

async function normalizeLink(link) {
  let normalizedLink = link
  normalizedLink = normalizedLink.replace(/\/$/,'')
  normalizedLink = normalizedLink.replace(/https?:\/\/(www\.)?/i, '')
  return normalizedLink
}

async function createStream(req, res) {
  if (!req.user || !accessControl.can(req.user.role).createAny('stream').granted) {
    res.status(401)
    return
  }

  // Don't add duplicate links if the link is already present and active
  const normalizedLink = await normalizeLink(req.body.link)
  const existingStream = await Stream.findOne({
    where: {
      link: { [Op.iLike]:  `%${normalizedLink}%` },
      isExpired: false,
    }
  })
  if(existingStream) {
    res.status(303).json({ data: existingStream })
    return
  }

  const stream = await Stream.create({
    city:     req.body.city,
    link:     req.body.link,
    platform: req.body.platform,
    postedBy: req.body.postedBy,
    region:   req.body.region,
    source:   req.body.source,
    status:   req.body.status,
    title:    req.body.title,
  })

  const response = {
    data: stream
  }
  res.status(201).json(response)
}

async function patchStream(req, res) {
  if (!req.user || !accessControl.can(req.user.role).updateAny('stream').granted) {
    res.status(401)
    return
  }

  const id = req.params.id
  const stream = await Stream.findByPk(id)

  const updatedStream = await stream.update({
    source:    req.body.source,
    platform:  req.body.platform,
    link:      req.body.link,
    status:    req.body.status,
    isExpired: req.body.isExpired,
    title:     req.body.title,
    embedLink: req.body.embedLink,
    postedBy:  req.body.postedBy,
    city:      req.body.city,
    region:    req.body.region,
    checkedAt: req.body.checkedAt,
    liveAt:    req.body.liveAt
  })

  if (updatedStream instanceof ValidationError) {
    const response = {
      error: updatedStream
    }
    res.status(400).json(response)
    return
  }

  const response = {
    data: updatedStream
  }
  res.status(200).json(response)
}

async function getStream(req, res) {
  const id = req.params.id
  const stream = await Stream.findByPk(id)
  if (!stream) {
    res.status(404).send()
    return
  }
  const response = {
    data: stream
  }
  res.status(200).json(response)
}

async function expireStream(req, res) {
  if (!req.user || !accessControl.can(req.user.role).deleteAny('stream').granted) {
    res.status(401)
    return
  }

  const id = req.params.id
  const stream = await Stream.findByPk(id)
  if (!stream) {
    res.status(404).send()
    return
  }
  await stream.update({ isExpired: true })
  res.status(204).send()
}

/* GET streams listing. */
router.get('/', getStreams)
router.post('/', passport.authenticate('jwt', { session: false }), createStream)
router.get('/:id', getStream)
router.patch('/:id', passport.authenticate('jwt', { session: false }), patchStream)
router.delete('/:id', passport.authenticate('jwt', { session: false }), expireStream)

module.exports = router;
