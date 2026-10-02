-- Migration 083: Membership Tier System & Aura Coins Transactional Engine

-- 1. Tabla de Estatus y Niveles de Usuario
CREATE TABLE IF NOT EXISTS user_levels (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    level_name VARCHAR(30) NOT NULL DEFAULT 'CLUB GLOW',
    total_historical_xp INT NOT NULL DEFAULT 0 CHECK (total_historical_xp >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Trazabilidad de Puntos XP (Inmutables)
CREATE TABLE IF NOT EXISTS xp_logs (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    xp_amount INT NOT NULL CHECK (xp_amount > 0),
    event_type VARCHAR(50) NOT NULL,
    reference_id VARCHAR(100) UNIQUE, -- Idempotency key (ej: booking_123, order_456)
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Saldo Transaccional Canjeable (Aura Coins)
CREATE TABLE IF NOT EXISTS aura_coin_transactions (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    coins_amount INT NOT NULL, -- Positivo (ingreso) o negativo (gasto/reverso)
    balance_after INT NOT NULL CHECK (balance_after >= 0),
    transaction_type VARCHAR(50) NOT NULL,
    reference_id VARCHAR(100),
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Verificaciones de Redes Sociales (Antifraude Ambassadors)
CREATE TABLE IF NOT EXISTS social_verifications (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    platform VARCHAR(30) NOT NULL,
    post_url_hash VARCHAR(64) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    xp_awarded INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP WITH TIME ZONE
);

-- 5. Redenciones y Cupones Canjeados
CREATE TABLE IF NOT EXISTS reward_redemptions (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    coupon_code VARCHAR(30) UNIQUE NOT NULL,
    discount_cop INT NOT NULL CHECK (discount_cop > 0),
    coins_spent INT NOT NULL CHECK (coins_spent > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    used_at TIMESTAMP WITH TIME ZONE
);

-- Índices para alto rendimiento
CREATE INDEX IF NOT EXISTS idx_xp_logs_user ON xp_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_aura_coins_user ON aura_coin_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_social_verif_user ON social_verifications(user_id);
