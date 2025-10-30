// Trae nuestra aplicación desde el archivo app.js
import app from './app.js';

// Define el puerto: usa el que esté en las variables de entorno o 3000 por defecto
const PORT = process.env.PORT || 3000;

// Inicia el servidor en el puerto especificado y muestra un mensaje
const server = app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});

// Escucha la señal SIGTERM (cuando el sistema quiere cerrar la app elegantemente)
process.on("SIGTERM", () => {
    // Cierra el servidor de forma ordenada
    server.close(() => {
        // Termina el proceso con código 0 (significa "todo salió bien")
        process.exit(0);
    });
});

// Escucha la señal SIGINT (cuando presionas Ctrl+C para parar la app)
process.on("SIGINT", () => {
    // Cierra el servidor de forma ordenada
    server.close(() => {
        // Termina el proceso con código 0 (significa "todo salió bien")
        process.exit(0);
    });
});

// Exporta el servidor para que otros archivos puedan usarlo
export default server;