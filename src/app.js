const express = require('express');
const db = require('./db');
const app = express();


app.get('/health', (req, res) => res.send('OK'));


app.get('/users', async (req, res) => {
const [rows] = await db.query('SELECT * FROM users');
res.json(rows);
});


module.exports = app;


if (require.main === module) {
app.listen(3000, () => console.log('Server running on port 3000'));
}