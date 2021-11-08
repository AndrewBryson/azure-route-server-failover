const express = require('express');
const app = express();

const myId = process.env["ID"] || "NOT-SET"
const port = process.env["PORT"] || 3000;

app.get('/', function (req, res) {
    res.send(`${myId}`);
});

app.listen(port, () => {
    console.log(`Listening on port:${port}, ID:${myId}`);
});