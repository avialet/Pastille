const express = require('express');
const compression = require('compression');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(compression());

// Pas de cache en dev, long cache en prod
const isDev = process.env.NODE_ENV !== 'production';
app.use(express.static(path.join(__dirname, 'public'), {
    maxAge: isDev ? 0 : '1y',
    setHeaders: (res, filePath) => {
        if (filePath.endsWith('.html') || isDev) {
            res.setHeader('Cache-Control', 'no-cache');
        }
    }
}));

// Téléchargement DMG
app.use('/download', express.static(path.join(__dirname, 'download'), {
    setHeaders: (res) => {
        res.setHeader('Content-Disposition', 'attachment');
    }
}));

// SPA fallback
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`Pastille site running on http://localhost:${PORT}`);
});
