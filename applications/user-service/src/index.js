const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'user-service' });
});

app.get('/users', (req, res) => {
  res.json({ users: [], message: 'User service running' });
});

app.listen(port, () => {
  console.log(`User service listening on port ${port}`);
});

module.exports = app;