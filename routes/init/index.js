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
  fastify.get('/', async function (_request, reply) {
    try {
      const cmd = 'init';
      const data = await getShellScriptByCmd(cmd);

      return reply.type('text/plain').send(data);
    } catch (err) {
      return reply.status(500).send(false);
    }
  })
}
