const request = require('C:/beauty-app/backend/node_modules/supertest');
const express = require('C:/beauty-app/backend/node_modules/express');
const biometricRoutes = require('C:/beauty-app/backend/src/routes/biometricRoutes');
const biometricConsentRoutes = require('C:/beauty-app/backend/src/routes/biometricConsentRoutes');
const app = express();
app.use(express.json({ limit: '50mb' }));
app.use((req,res,next)=>{ if(req.headers.authorization==='Bearer valid-jwt-token'){req.user={id:'7',role:'user'};} next(); });
app.use('/api/biometric', biometricRoutes);
app.use('/api/consent', biometricConsentRoutes);
(async()=>{
  for (let i=1;i<=4;i++){
    const s=Date.now();
    const r=await request(app).get('/api/consent/status/7').set('Authorization','Bearer valid-jwt-token');
    console.log('call',i,'status',r.statusCode,'ms',Date.now()-s);
  }
  process.exit(0);
})();
