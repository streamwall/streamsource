const _ = require('lodash')
const {Op, ValidationError} = require("sequelize");
const express = require('express');
const router = express.Router();

const {Stream} = require('../models')

const ACCEPT_PARAMS = [
  'source',
  'link',
  'status',
  'isExpired',
  'title',
  'embedLink',
  'postedBy',
  'city',
  'region',
  'checkedAt',
  'liveAt'
]

const ORDERABLE_FIELDS = [
  'source',
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
  const filter = {}
  let order

  if (req.query) {
    // Non-date-related
    const filterRules = {
      source:      {field: 'source', rule: {[Op.iLike]: `%${req.query.source}%`,}},
      notSource:   {field: 'source', rule: {[Op.notILike]: `%${req.query.notSource}%`,}},
      link:        {field: 'link', rule: {[Op.iLike]: `%${req.query.link}%`,}},
      status:      {field: 'status', rule: {[Op.eq]: req.query.status}},
      notStatus:   {field: 'status', rule: {[Op.notEq]: req.query.status}},
      isExpired:   {field: 'isExpired', rule: {[req.query.isExpired ? Op.is : Op.not]: true,}},
      title:       {field: 'title', rule: {[Op.iLike]: `%${req.query.title}%`}},
      notTitle:    {field: 'title', rule: {[Op.notILike]: `%${req.query.notTitle}%`,}},
      postedBy:    {field: 'postedBy', rule: {[Op.iLike]: `%${req.query.postedBy}%`}},
      notPostedBy: {field: 'postedBy', rule: {[Op.notILike]: `%${req.query.notPostedBy}%`,}},
      city:        {field: 'city', rule: {[Op.iLike]: `%${req.query.city}%`}},
      notCity:     {field: 'city', rule: {[Op.notILike]: `%${req.query.notCity}%`,}},
      region:      {field: 'region', rule: {[Op.iLike]: `%${req.query.region}%`}},
      notRegion:   {field: 'region', rule: {[Op.notILike]: `%${req.query.notRegion}%`,}},
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
      const fromParam = req.query[`${fieldName}From`]
      const toParam = req.query[`${fieldName}To`]
      if (fromParam || toParam) {
        filter[fieldName] = {
          [Op.lt]: toParam || new Date(),
          [Op.gt]: fromParam || new Date(0)
        }
      }
    })

    // Set order
    let orderFields
    let orderDirections
    if(req.query.orderFields ^ req.query.orderDirections) {
      const errorResponse = { error: `Ordering requires both orderFields and orderDirections params to be sent`}
      res.status(400).json(errorResponse)
      return
    }
    if (req.query.orderFields && req.query.orderDirections) {
      orderFields = req.query.orderFields.split(',')
      orderDirections = req.query.orderDirections.split(',')
      if (orderFields.length !== orderDirections.length) {
        const errorResponse = {error: `orderFields and orderDirections must have the same length`}
        res.status(400).json(errorResponse)
        return
      }
      const invalidOrderFields = orderFields.filter((fieldName) => !ORDERABLE_FIELDS.includes(fieldName))
      if (invalidOrderFields.length > 0) {
        res.status(400).json({error: `Cannot order by fields: ${invalidOrderFields.join(', ')}`})
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
  const streams = await Stream.findAll(queryOptions)
  res.status(200).json(streams)
}

async function createStream(req, res) {
  const {link, postedBy, city, region} = req.body
  const stream = await Stream.create({link, postedBy, city, region})
  res.status(201).json(stream)
}

async function patchStream(req, res) {
  const id = req.params.id
  const stream = await Stream.findByPk(id)
  const permittedBody = _.pickBy(req.body, param => ACCEPT_PARAMS.includes(param))
  const updatedStream = await stream.update(permittedBody)

  if (updatedStream instanceof ValidationError) {
    res.status(400).json(updatedStream)
    return
  }

  await updatedStream.reload()
  res.status(200).json(updatedStream)
}

async function getStream(req, res) {
  const id = req.params.id
  const stream = await Stream.findByPk(id)
  if(!stream) {
    res.status(404).send()
    return
  }
  res.status(200).json(stream)
}

async function expireStream(req, res) {
  const id = req.params.id
  const stream = await Stream.findByPk(id)
  if(!stream) {
    res.status(404).send()
    return
  }
  await stream.update({isExpired: true})
  res.status(204).send()
}

/* GET streams listing. */
router.get('/', getStreams)
router.post('/', createStream)
router.get('/:id', getStream)
router.patch('/:id', patchStream)
router.delete('/:id', expireStream)

module.exports = router;
