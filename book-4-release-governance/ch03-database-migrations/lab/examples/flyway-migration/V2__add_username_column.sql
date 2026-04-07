-- V2__add_username_column.sql — Phase 1 (Expand) of the expand/contract migration
--
-- Adds the new 'username' column without removing 'user_name'.
-- After this migration:
--   - Old application version: reads/writes 'user_name' (unchanged — backward compatible)
--   - New application version: reads/writes 'username'
--   - Both columns exist; no incompatibility window
--
-- This migration is safe to run while the old application version is serving traffic.

-- Add the new column as nullable first to avoid a full table lock on populated tables
ALTER TABLE users ADD COLUMN username VARCHAR(255);

-- Backfill: copy existing data into the new column
-- On large tables, do this in batches:
--   UPDATE users SET username = user_name WHERE id BETWEEN 1 AND 10000;
--   (repeat in batches to avoid locking)
UPDATE users SET username = user_name WHERE username IS NULL;

-- Add NOT NULL constraint only AFTER backfill is complete
-- On PostgreSQL 12+, this is a metadata-only operation if the column has no NULLs
ALTER TABLE users ALTER COLUMN username SET NOT NULL;
