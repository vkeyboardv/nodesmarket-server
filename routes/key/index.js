'use strict'

module.exports = async function (fastify, opts) {
  const { db } = fastify;

  fastify.get('/', async function (request, reply) {
    const { key } = request.query;

    const foundKey = await db.findKey(key);
    
    if (foundKey) {
      reply.status(200).send(true);
    } else {
      reply.status(403).send(false);
    }
  })
}
