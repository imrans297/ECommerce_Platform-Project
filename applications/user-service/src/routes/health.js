const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { asyncHandler } = require('../middleware/asyncHandler');

// Health check endpoint
router.get('/', asyncHandler(async (req, res) => {
  const healthCheck = {
    uptime: process.uptime(),
    message: 'OK',
    timestamp: Date.now(),
    service: 'user-service',
    version: process.env.npm_package_version || '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  };

  try {
    // Check database connection
    const dbState = mongoose.connection.readyState;
    healthCheck.database = {
      status: dbState === 1 ? 'connected' : 'disconnected',
      state: dbState
    };

    // Check memory usage
    const memUsage = process.memoryUsage();
    healthCheck.memory = {
      rss: `${Math.round(memUsage.rss / 1024 / 1024)} MB`,
      heapTotal: `${Math.round(memUsage.heapTotal / 1024 / 1024)} MB`,
      heapUsed: `${Math.round(memUsage.heapUsed / 1024 / 1024)} MB`,
      external: `${Math.round(memUsage.external / 1024 / 1024)} MB`
    };

    res.status(200).json(healthCheck);
  } catch (error) {
    healthCheck.message = error.message;
    res.status(503).json(healthCheck);
  }
}));

// Readiness probe
router.get('/ready', asyncHandler(async (req, res) => {
  try {
    // Check if database is ready
    if (mongoose.connection.readyState !== 1) {
      return res.status(503).json({
        status: 'not ready',
        message: 'Database not connected'
      });
    }

    res.status(200).json({
      status: 'ready',
      message: 'Service is ready to accept traffic'
    });
  } catch (error) {
    res.status(503).json({
      status: 'not ready',
      message: error.message
    });
  }
}));

// Liveness probe
router.get('/live', (req, res) => {
  res.status(200).json({
    status: 'alive',
    message: 'Service is alive'
  });
});

module.exports = router;