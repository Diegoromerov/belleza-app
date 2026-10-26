module.exports = {
  // Ignore .agent directory tests that are not relevant
  testPathIgnorePatterns: ['/\\.agent/'],
  // Restrict Jest roots to backend and frontend areas to avoid naming collisions
  roots: ['<rootDir>/backend', '<rootDir>/frontend'],
  testEnvironment: 'node',
  testMatch: ['**/tests/**/*.test.js'],
  collectCoverage: true,
  coverageDirectory: 'coverage',
};
