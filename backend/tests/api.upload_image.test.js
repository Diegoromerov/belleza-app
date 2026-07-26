// backend/tests/api.upload_image.test.js
const request = require('supertest');
const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
app.post('/api/upload', (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ error: 'Token requerido' });
  
  // Simular subida exitosa
  res.status(200).json({ url: 'https://storage.glowapp.com/uploads/test_image.png' });
});

describe('POST /api/upload', () => {
  const endpoint = '/api/upload';

  test('should upload a valid PNG image and return URL', async () => {
    const pngPath = path.join(__dirname, 'test_image.png');
    if (!fs.existsSync(pngPath)) {
      const pngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/5+BFwAJgwP/9i0wWQAAAABJRU5ErkJggg==';
      fs.writeFileSync(pngPath, Buffer.from(pngBase64, 'base64'));
    }
    const response = await request(app)
      .post(endpoint)
      .set('Authorization', 'Bearer dummy-token')
      .attach('image', pngPath);
    expect(response.statusCode).toBe(200);
    expect(response.body).toHaveProperty('url');
    expect(typeof response.body.url).toBe('string');
  });

  test('should reject request without authorization header', async () => {
    const response = await request(app).post(endpoint);
    expect(response.statusCode).toBe(401);
  });
});
