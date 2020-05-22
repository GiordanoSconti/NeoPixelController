const fs = require('fs');
const path = require('path');
const express = require('express');
const webServerPort = 8080;
const app = express();
app.use(express.static('public'));
app.get('/', function (req, res) {
    res.sendFile(path.join(__dirname, 'index.html'));
});
app.listen(webServerPort, function () {
    console.log('Web Server is listening on ' + webServerPort + '!');
});