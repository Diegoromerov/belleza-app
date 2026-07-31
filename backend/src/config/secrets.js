// backend/src/config/secrets.js
/**
 * Secret Manager Abstraction Layer for GlowApp Backend
 * Supports 'env', 'mock', and 'aws' providers via process.env.SECRET_PROVIDER
 */

const secretsCache = new Map();

class SecretManager {
  constructor(provider = process.env.SECRET_PROVIDER || 'env') {
    this.provider = provider;
  }

  async getSecret(secretName, defaultValue = null) {
    if (secretsCache.has(secretName)) {
      return secretsCache.get(secretName);
    }

    let secretValue = null;

    switch (this.provider) {
      case 'aws':
        // En producción se invocará el SDK de AWS Secrets Manager
        secretValue = process.env[secretName] || defaultValue;
        break;

      case 'mock':
        // Provider de prueba para entornos de testing y CI
        secretValue = `mock_secret_val_${secretName}`;
        break;

      case 'env':
      default:
        secretValue = process.env[secretName] || defaultValue;
        break;
    }

    if (secretValue !== null) {
      secretsCache.set(secretName, secretValue);
    }

    return secretValue;
  }

  clearCache() {
    secretsCache.clear();
  }
}

const secretManagerInstance = new SecretManager();

module.exports = {
  SecretManager,
  secretManager: secretManagerInstance,
  getSecret: (name, def) => secretManagerInstance.getSecret(name, def),
};
