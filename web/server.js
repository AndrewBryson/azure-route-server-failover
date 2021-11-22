const http = require('http');

const myId = process.env["ID"] || "NOT-SET"
const port = process.env["PORT"] || 3000;

http.createServer((request, response) => {
    response.writeHead(200, {
        'Content-Type': 'text/plain'
    });

    response.write(`${myId}`);
    response.end();

}).listen(port, () => {
    console.log(`Listening on port:${port}, ID:${myId}`);
});