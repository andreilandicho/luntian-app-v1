import express from 'express';
import usersRouter from './routes/users.js';
import barangaysRouter from './routes/barangays.js';

const app = express();
app.use(express.json());

app.use('/users', usersRouter);
app.use('/barangays', barangaysRouter);

app.listen(3000, () => console.log('Server running on port 3000'));