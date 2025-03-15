// Load necessary modules
const http = require('http');
const fs = require('fs');
const path = require('path');

// Set the port to listen on
const port = 9091;

// Construct the full path to the index.html file
const indexPath = path.join(__dirname, 'index.html');

// Create an HTTP server that handles incoming requests
const server = http.createServer((req, res) => {
    // Only handle GET requests
    if (req.method === 'GET') {
        // Read the index.html file
        fs.readFile(indexPath, (err, data) => {
            // If there's an error reading the file, return a 500 error
            if (err) {
                res.writeHead(500, { 'Content-Type': 'text/plain' });
                res.end('Error reading index.html');
            } else {
                // If the file is read successfully, send it with a 200 status code
                res.writeHead(200, { 'Content-Type': 'text/html' });
                res.end(data);
            }
        });
    } else {
        // For non-GET methods, return a 405 error (Method Not Allowed)
        res.writeHead(405, { 'Content-Type': 'text/plain' });
        res.end('Method Not Allowed');
    }
});

// Start the server and listen on the specified port
server.listen(port, () => {
    console.log(`Server running at http://localhost:${port}/`);
});
