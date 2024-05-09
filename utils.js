const { randomBytes } = require('crypto');

const generateKey = () => randomBytes(16).toString('hex').toUpperCase();

module.exports = { generateKey }
