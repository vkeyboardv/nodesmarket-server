'use strict'

const fs = require('node:fs');
const path = require('node:path');

const getShellData = async (filePath) => {
  const fullPath = path.join(__dirname, filePath);
  const data = await fs.promises.readFile(fullPath, 'utf8');

  return data;
}

module.exports = async function (fastify, opts) {
  fastify.get('/', async function (request, reply) {
    try {
      const data = await getShellData('init_keys.sh');

      return reply.type('text/plain').send(data);
    } catch (err) {
      return reply.status(500).send(false);
    }
  })
}
