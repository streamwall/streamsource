require('dotenv').config()

module.exports = {
  "development": {
    "username": process.env.DB_USERNAME || "postgres",
    "password": process.env.DB_PASSWORD || null,
    "database": process.env.DB_NAME || 'streamsource_development',
    "host": process.env.DB_HOSTNAME || '127.0.0.1',
    "port": process.env.DB_PORT || '5432',
    "dialect": "postgres",
    "dialectOptions": {
      "ssl": process.env.DB_SSL == "true"
    }
  },
  "test": {
    "username": process.env.DB_USERNAME || 'postgres',
    "password": process.env.DB_PASSWORD || null,
    "database": process.env.DB_NAME || 'streamsource_test',
    "host": process.env.DB_HOSTNAME || '127.0.0.1',
    "port": process.env.DB_PORT || '5432',
    "dialect": "postgres",
    "dialectOptions": {
      "ssl": process.env.DB_SSL == "true"
    }
  },
  "production": {
    "username": process.env.DB_USERNAME,
    "password": process.env.DB_PASSWORD,
    "database": process.env.DB_NAME,
    "host": process.env.DB_HOSTNAME,
    "port": process.env.DB_PORT,
    "dialect": "postgres",
    "dialectOptions": {
      "ssl": process.env.DB_SSL == "true"
    }
  }
}
