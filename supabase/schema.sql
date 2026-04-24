-- ============================================================
-- SENFI — Schema + RLS Baseline
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor > New query)
-- Version: 1.0 · April 2026
-- ============================================================

-- ─── EXTENSION ───────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── ACCOUNTS (cuentas bancarias / tarjetas) ─────────────────
CREATE TABLE IF NOT EXISTS accounts (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL CHECK (type IN ('corriente', 'ahorro', 'fondo_liquido', 'credito', 'debito', 'efectivo')),
  bank        TEXT,
  last4       CHAR(4),
  balance     NUMERIC(12, 2) NOT NULL DEFAULT 0,
  currency    CHAR(3) NOT NULL DEFAULT 'DOP',
  apy         NUMERIC(5, 2),
  credit_limit NUMERIC(12, 2),
  cut_day     SMALLINT CHECK (cut_day BETWEEN 1 AND 31),
  pay_day     SMALLINT CHECK (pay_day BETWEEN 1 AND 31),
  parent_id   UUID REFERENCES accounts(id),
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own accounts"
  ON accounts FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── TAGS ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tags (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  slug           TEXT NOT NULL,
  display_name   TEXT NOT NULL,
  color          TEXT,
  is_suggested   BOOLEAN NOT NULL DEFAULT FALSE,
  times_used     INTEGER NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, slug)
);

ALTER TABLE tags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own tags"
  ON tags FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── TRANSACTIONS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id       UUID REFERENCES accounts(id) ON DELETE SET NULL,
  amount           NUMERIC(12, 2) NOT NULL,
  currency         CHAR(3) NOT NULL DEFAULT 'DOP',
  merchant         TEXT,
  description      TEXT,
  macro_category   TEXT NOT NULL CHECK (macro_category IN ('necesidad', 'estilo_vida', 'ahorro', 'inversion')),
  is_essential     BOOLEAN NOT NULL DEFAULT FALSE,
  payment_method   TEXT,
  source_channel   TEXT CHECK (source_channel IN ('manual', 'miat_email', 'miat_push', 'miat_voice', 'miat_photo', 'miat_forward')),
  miat_raw         TEXT,
  status           TEXT NOT NULL DEFAULT 'confirmed' CHECK (status IN ('pending', 'confirmed', 'rejected')),
  transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own transactions"
  ON transactions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── TRANSACTION ↔ TAGS (junction) ───────────────────────────
CREATE TABLE IF NOT EXISTS transaction_tags (
  transaction_id  UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  tag_id          UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (transaction_id, tag_id)
);

ALTER TABLE transaction_tags ENABLE ROW LEVEL SECURITY;

-- Join-based policy: user must own the transaction
CREATE POLICY "Users see own transaction_tags"
  ON transaction_tags FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM transactions t
      WHERE t.id = transaction_id AND t.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM transactions t
      WHERE t.id = transaction_id AND t.user_id = auth.uid()
    )
  );

-- ─── BUDGETS (por tag) ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS budgets (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tag_id        UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  monthly_limit NUMERIC(12, 2) NOT NULL CHECK (monthly_limit > 0),
  alert_pct     SMALLINT NOT NULL DEFAULT 75 CHECK (alert_pct BETWEEN 1 AND 100),
  strategy      TEXT NOT NULL DEFAULT 'base_cero' CHECK (strategy IN ('base_cero', 'equilibrio', 'crecimiento', 'libertad')),
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, tag_id)
);

ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own budgets"
  ON budgets FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── DEBTS ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS debts (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id      UUID REFERENCES accounts(id) ON DELETE SET NULL,
  name            TEXT NOT NULL,
  type            TEXT NOT NULL CHECK (type IN ('tarjeta_credito', 'prestamo_personal', 'hipoteca', 'informal', 'otro')),
  classification  TEXT NOT NULL CHECK (classification IN ('toxica', 'consumo', 'productiva')),
  balance         NUMERIC(12, 2) NOT NULL CHECK (balance >= 0),
  annual_rate     NUMERIC(6, 2) NOT NULL CHECK (annual_rate >= 0),
  monthly_payment NUMERIC(12, 2) NOT NULL CHECK (monthly_payment >= 0),
  payments_remaining INTEGER,
  level           SMALLINT NOT NULL DEFAULT 1 CHECK (level BETWEEN 1 AND 4),
  bank            TEXT,
  last4           CHAR(4),
  currency        CHAR(3) NOT NULL DEFAULT 'DOP',
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE debts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own debts"
  ON debts FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── GOALS (metas de ahorro) ──────────────────────────────────
CREATE TABLE IF NOT EXISTS goals (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  target_amount   NUMERIC(12, 2) NOT NULL CHECK (target_amount > 0),
  current_amount  NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
  monthly_alloc   NUMERIC(12, 2),
  pool_pct        NUMERIC(5, 2) CHECK (pool_pct BETWEEN 0 AND 100),
  target_date     DATE,
  is_preset       BOOLEAN NOT NULL DEFAULT FALSE,
  preset_type     TEXT CHECK (preset_type IN ('emergency_fund', 'usd_1k', 'usd_10k', 'fire')),
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  order_index     SMALLINT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own goals"
  ON goals FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── USER PROFILES ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name    TEXT,
  monthly_income  NUMERIC(12, 2),
  has_debts       BOOLEAN,
  ui_mode         TEXT NOT NULL DEFAULT 'simple' CHECK (ui_mode IN ('simple', 'intermedio', 'avanzado')),
  base_currency   CHAR(3) NOT NULL DEFAULT 'DOP',
  inflation_rate  NUMERIC(4, 2) NOT NULL DEFAULT 4.50,
  debt_strategy   TEXT NOT NULL DEFAULT 'avalanche' CHECK (debt_strategy IN ('avalanche', 'snowball', 'simultaneo')),
  budget_strategy TEXT NOT NULL DEFAULT 'base_cero' CHECK (budget_strategy IN ('base_cero', 'equilibrio', 'crecimiento', 'libertad')),
  onboarding_done BOOLEAN NOT NULL DEFAULT FALSE,
  miat_enabled    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own profile"
  ON profiles FOR ALL
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ─── AUTO-CREATE PROFILE ON SIGNUP ───────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id)
  VALUES (NEW.id)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─── UPDATED_AT TRIGGER ───────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_accounts_updated_at BEFORE UPDATE ON accounts FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER set_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER set_budgets_updated_at BEFORE UPDATE ON budgets FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER set_debts_updated_at BEFORE UPDATE ON debts FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER set_goals_updated_at BEFORE UPDATE ON goals FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER set_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ─── INDEXES ──────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_tags_user_slug ON tags(user_id, slug);
CREATE INDEX IF NOT EXISTS idx_debts_user_id ON debts(user_id);
CREATE INDEX IF NOT EXISTS idx_goals_user_id ON goals(user_id);
CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets(user_id);

-- ─── VERIFY RLS IS ENABLED ───────────────────────────────────
-- Run this to confirm: SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';
-- All tables should show rowsecurity = true

SELECT
  tablename,
  rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
