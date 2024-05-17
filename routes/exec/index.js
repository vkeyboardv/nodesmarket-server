'use strict'

const fs = require('node:fs');
const path = require('node:path');

const getShellScriptByCmd = async (cmd) => {
  const filePath = `./sh/${cmd}.obfuscated.sh`;
  const fullPath = path.join(__dirname, filePath);

  const data = await fs.promises.readFile(fullPath, 'utf8');

  return data;
}

module.exports = async function (fastify, opts) {
  const { db } = fastify;

  fastify.get('/', async function (request, reply) {
    const { key, cmd } = request.query;

    try {
      const foundKey = await db.findKey(key);
    
      if (!foundKey) {
        return reply.status(403).send(false);
      }
    
      const data = await getShellScriptByCmd(cmd);

      return reply.type('text/plain').send(data);
    } catch (err) {
      return reply.status(500).send(false);
    }
  })
}
