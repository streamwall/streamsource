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

  // Set non-Date-related filtering options
  const filterRules = {
    source: {[Op.iLike]: `%${res.query.source}%`,},
    notSource: {[Op.notILike]: `%${res.query.notSource}%`,},
    link: {[Op.iLike]: `%${res.query.link}%`,},
    status: {[Op.iLike]: `%${res.query.status}%`},
    notStatus: {[Op.notILike]: `%${res.query.status}%`,},
    isExpired: {[res.query.isExpired ? Op.is : Op.not]: true,},
    title: {[Op.iLike]: `%${res.query.title}%`},
    notTitle: {[Op.notILike]: `%${res.query.notTitle}%`,},
    postedBy: {[Op.iLike]: `%${res.query.postedBy}%`},
    notPostedBy: {[Op.notILike]: `%${res.query.notPostedBy}%`,},
    city: {[Op.iLike]: `%${res.query.city}%`},
    notCity: {[Op.notILike]: `%${res.query.notCity}%`,},
    region: {[Op.iLike]: `%${res.query.region}%`},
    notRegion: {[Op.notILike]: `%${res.query.notRegion}%`,},
  }
  Object.entries(filterRules).forEach(([param, rule]) => {
    if (!req.query.keys.includes(param)) {
      return
    }
    filter[param] = rule
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
        [Op.lt]: fromParam || new Date(),
        [Op.gt]: toParam || new Date(0)
      }
    }
  })

  // Validate ordering options
  const orderFields = req.query['orderFields']?.split(',') || ['createdAt']
  const orderDirections = req.query['orderDirections']?.split(',') || ['DESC']
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
  const order = [orderFields, orderDirections]

  // Finally, find that stuff and send it back
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

async function expireStream(req, res) {
  const id = req.params.id
  const stream = await Stream.findByPk(id)
  await stream.update({isExpired: true})
  res.status(204)
}

/* GET streams listing. */
router.get('/', getStreams)
router.post('/', createStream)
router.patch('/:id', patchStream)
router.delete('/:id', expireStream)

module.exports = router;
