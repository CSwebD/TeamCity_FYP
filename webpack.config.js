const path = require('path');

module.exports = {
    mode: 'production',
    entry: './app.js',
    output: {
        filename: 'bundle.js',
        path: path.resolve(__dirname, 'dist'),
    },
    resolve: {
        fallback: {
            http: require.resolve('stream-http'),
        },
    },
};
