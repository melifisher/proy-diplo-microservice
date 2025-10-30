// Importa la librería para verificar que las cosas funcionen como esperamos
import assert from 'node:assert';

// Importa la librería para crear servidores web y hacer peticiones HTTP
import http from 'node:http';

// Importa la librería para crear pruebas automáticas
import test from 'node:test';

// Trae nuestra aplicación desde el archivo app.js
import app from '../app.js';

// Crea una nueva prueba para la ruta GET /hola
test('GET /hola', async (t) => {
    // Crea un servidor temporal usando nuestra aplicación
    // 0 -> el puerto se asigna automáticamente
    const server = app.listen(0);

    // Obtiene el puerto donde está corriendo el servidor
    const { port } = server.address();

    // Hace una petición GET al servidor y espera la respuesta
    const body = await new Promise((resolve, reject) => {
        // Le pregunta al servidor "¿qué hay en /hola?"
        http.get(`http://localhost:${port}/hola`, (res) => {
            let data = '';
            // Va juntando todos los pedazos de información que envía el servidor
            res.on("data", (chunk) => { data += chunk; });
            // Cuando termina de recibir datos, guarda toda la información
            res.on("end", () => { resolve(data); });
            // Si algo sale mal, captura el error
        }).on("error", reject);
    });

    // Cierra el servidor porque ya no lo necesitamos
    await new Promise((r) => server.close(r));

    // Convierte la respuesta de texto a un objeto JavaScript
    const parsed = JSON.parse(body);

    // Verifica que el mensaje sea exactamente 'Hola Mundo'
    assert.strictEqual(parsed.mensaje, 'Hola Mundo');
});