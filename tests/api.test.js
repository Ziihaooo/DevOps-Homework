process.env.NODE_PATH = __dirname + '/../src/node_modules';
require('module').Module._initPaths();

const request = require('supertest');
const app = require('../src/app');


describe('GET /users', () => {
it('returns user list', async () => {
const res = await request(app).get('/users');
expect(res.statusCode).toBe(200);
expect(res.body.length).toBeGreaterThan(0);
});
});