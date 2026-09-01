require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const crypto = require('crypto');
const apiRoutes = require('./routes/api');
const Order = require('./models/Order');
const rekber = require('./controllers/rekberController');

const app = express();
const PORT = Number(process.env.PORT || 5000);
const MONGO_URI = process.env.MONGO_URI;
if (!MONGO_URI) throw new Error('MONGO_URI belum dikonfigurasi.');
if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) throw new Error('JWT_SECRET production wajib minimal 32 karakter.');

app.disable('x-powered-by');
app.use((req,res,next)=>{ res.setHeader('X-Content-Type-Options','nosniff'); res.setHeader('X-Frame-Options','DENY'); res.setHeader('Referrer-Policy','no-referrer'); next(); });
app.use(express.json({ limit:'2mb' }));
app.use(express.urlencoded({ extended:true, limit:'2mb' }));

const buckets = new Map();
app.use((req,res,next)=>{
  const key = `${req.ip}:${Math.floor(Date.now()/60000)}`;
  const count = (buckets.get(key) || 0) + 1;
  buckets.set(key,count);
  if (count > 120) return res.status(429).json({ success:false, message:'Terlalu banyak request. Coba lagi sebentar.' });
  next();
});

app.get('/', (req,res)=>res.json({ success:true, message:'Nusopa.Mart Backend aktif.', service:'Nusopa.Mart API', timestamp:new Date() }));
app.use('/api',apiRoutes);
app.use((req,res)=>res.status(404).json({ success:false,message:'Endpoint tidak ditemukan.' }));
app.use((err,req,res,next)=>{ console.error('API ERROR:',err); res.status(err.status||500).json({ success:false,message:'Terjadi kesalahan pada server.' }); });

let worker;
async function releaseWorker(){
  try {
    const now = new Date();
    const orders = await Order.find({ statusDana:'TERKUNCI', autoReleaseAt:{ $lte:now } }).limit(100).select('orderId');
    for (const order of orders) { try { await rekber.autoRelease({ query:{}, body:{}, user:{ role:'ADMIN' } }, { json:()=>({}) }); } catch (_) {} }
  } catch (e) { console.error('ESCROW WORKER:',e.message); }
}

async function startServer(){
  await mongoose.connect(MONGO_URI);
  console.log('MongoDB Nusopa.Mart berhasil terhubung.');
  app.listen(PORT,()=>console.log(`Nusopa.Mart Backend berjalan di port ${PORT}`));
  worker = setInterval(releaseWorker, 60 * 1000);
}
async function shutdown(signal){ clearInterval(worker); await mongoose.connection.close(); process.exit(0); }
process.on('SIGINT',()=>shutdown('SIGINT'));
process.on('SIGTERM',()=>shutdown('SIGTERM'));
if (require.main === module) startServer().catch(e=>{ console.error(e); process.exit(1); });
module.exports=app;
