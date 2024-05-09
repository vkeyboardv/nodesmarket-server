const fs = require('node:fs/promises')

const db = {
  findKey: async (key) => {
    const json = await fs.readFile('./db.json', 'utf8');

    const jsonParsed = JSON.parse(json);

    const [foundKey] = jsonParsed.keys.filter(el => el.key === key)

    return foundKey
  }
}

module.exports = db;
