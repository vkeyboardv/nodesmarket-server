'use strict'

const fs = require('node:fs');
const path = require('node:path');

const getShellData = async (filePath) => {
  const fullPath = path.join(__dirname, filePath);
  const data = await fs.promises.readFile(fullPath, 'utf8');

  return data;
}

module.exports = async function (fastify, opts) {
  const { db } = fastify;

  fastify.get('/', async function (request, reply) {
    const { key } = request.query;

    try {
      const foundKey = await db.findKey(key);
    
      if (!foundKey) {
        reply.status(403).send(false);
      }
    
      const data = await getShellData('start.sh');

      reply.type('text/plain').send(data);
    } catch (err) {
      reply.status(500).send('Error reading the bash file.');
    }
  })
}
