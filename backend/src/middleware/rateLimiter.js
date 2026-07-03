const NodeCache = require('node-cache');
const usageCache = new NodeCache({ stdTTL: 86400 }); // 1 día

module.exports = (req, res, next) => {
  const userId = req.userId;
  const key = `usage_${userId}_${new Date().toDateString()}`;
  const currentUsage = usageCache.get(key) || 0;
  
  if (currentUsage >= 3) { // 3 fotos/día
    return res.status(429).json({ 
      error: 'Límite diario alcanzado',
      message: 'Máximo 3 análisis por día'
    });
  }
  
  usageCache.set(key, currentUsage + 1);
  next();
};
