// Minimal Express application used for backend tests
// Exported so that supertest can import the app instance.

const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

// Example route – real routes are defined elsewhere in the application.
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

module.exports = app;
