const express = require('express');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
  res.json({ 
    message: 'Ma super CI/CD!',
    build: process.env.BUILD_NUMBER || 'local',
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, () => {
  console.log(`✓ Serveur démarré sur le port ${PORT}`);
});
