const express = require('express');
const os = require('os');
const app = express();

const PORT = process.env.PORT || 5050;

app.get('/', (req, res) => {
  const hostname = os.hostname();
  const timestamp = new Date().toISOString();
  console.log(`${timestamp} - Request received from ${req.ip}`);
  res.send(`Hello from backend server: ${hostname}`);
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Server hostname: ${os.hostname()}`);
});
