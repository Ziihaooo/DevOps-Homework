const express = require('express');
const app = express();
const PORT = 3000;

// Health endpoint
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Optional root endpoint
app.get('/', (req, res) => {
  res.send('App running');
});

// 0.0.0.0 is REQUIRED for Docker & EC2 target group
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on port ${PORT}`);
});
