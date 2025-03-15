console.log('Starting the server...');

const http = require('http');

const server = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Server is running!');
});

server.listen(4000, () => {
    console.log('Server running at http://localhost:4000/');
});
