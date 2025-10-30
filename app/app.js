import express from 'express';

const app = express();

app.get('/hola', (req, res) => {
    res.json({ mensaje: 'Hola Mundo' });
});

export default app;