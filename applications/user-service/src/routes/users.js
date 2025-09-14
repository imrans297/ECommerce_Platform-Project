const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { auth, authorize } = require('../middleware/auth');
const { validateUser, validateLogin } = require('../middleware/validation');
const { asyncHandler } = require('../middleware/asyncHandler');

// Public routes
router.post('/register', validateUser, asyncHandler(userController.register));
router.post('/login', validateLogin, asyncHandler(userController.login));
router.post('/forgot-password', asyncHandler(userController.forgotPassword));
router.put('/reset-password/:token', asyncHandler(userController.resetPassword));
router.get('/verify-email/:token', asyncHandler(userController.verifyEmail));

// Protected routes
router.use(auth); // All routes below require authentication

router.get('/profile', asyncHandler(userController.getProfile));
router.put('/profile', asyncHandler(userController.updateProfile));
router.put('/change-password', asyncHandler(userController.changePassword));
router.post('/logout', asyncHandler(userController.logout));

// Admin only routes
router.get('/', authorize('admin', 'moderator'), asyncHandler(userController.getUsers));
router.get('/:id', authorize('admin', 'moderator'), asyncHandler(userController.getUserById));
router.put('/:id', authorize('admin'), asyncHandler(userController.updateUser));
router.delete('/:id', authorize('admin'), asyncHandler(userController.deleteUser));
router.put('/:id/activate', authorize('admin'), asyncHandler(userController.activateUser));
router.put('/:id/deactivate', authorize('admin'), asyncHandler(userController.deactivateUser));

module.exports = router;