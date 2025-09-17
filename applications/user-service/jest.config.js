module.exports = {
  testEnvironment: 'node',
  testTimeout: 10000,
  forceExit: true,
  detectOpenHandles: true,
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/index.js'
  ],
  testMatch: [
    '**/__tests__/**/*.js',
    '**/?(*.)+(spec|test).js'
  ]
};