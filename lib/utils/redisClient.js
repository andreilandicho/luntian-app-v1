import { createClient } from 'redis';

const redisClient = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });

redisClient.on('error', err => console.error('Redis Client Error', err));

// Top-level await (Node.js 14+). If not supported, connect in your main file before starting server.
await redisClient.connect();

export default redisClient;