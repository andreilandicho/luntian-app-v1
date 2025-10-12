import { createClient } from 'redis';

const redisClient = createClient({ 
    url: process.env.REDIS_URL,
    socket: {
        tls: true
    }
});

redisClient.on('error', err => console.error('Redis Client Error', err));

// Top-level await (Node.js 14+). If not supported, connect in your main file before starting server.
await redisClient.connect();

export default redisClient;