-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Ensure we have the proper schema permissions
GRANT USAGE ON SCHEMA public TO postgres, authenticated, anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO postgres, authenticated, anon;

-- Ensure auth schema access
GRANT USAGE ON SCHEMA auth TO postgres, authenticated, anon;
GRANT SELECT ON ALL TABLES IN SCHEMA auth TO postgres, authenticated, anon;
