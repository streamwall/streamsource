const { Stream } = require('../models')
const express = require('express');
var router = express.Router();

async function getStreams(req, res) {
  const streams = await Stream.findAll()
  res.status(200).json(streams)
}

async function createStream(req, res) {
  const link = req.body['link']
  const stream = await Stream.create({ link })
  res.status(201).json(stream)
}

/* GET streams listing. */
router.get('/', getStreams)
router.post('/', createStream)

module.exports = router;
