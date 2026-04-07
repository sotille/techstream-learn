-- V3__drop_legacy_username_column.sql — Phase 3 (Contract) of the expand/contract migration
--
-- Removes the legacy 'user_name' column after the new application version
-- has been deployed and confirmed stable.
--
-- PREREQUISITES before running this migration:
--   1. New application version has been running in production for the defined
--      observation window (e.g., 24 hours or per your change management policy)
--   2. No active rollback plan to the old application version
--   3. Change management approval obtained
--   4. All application code referencing 'user_name' has been removed
--
-- This migration is NOT rollback-safe — once 'user_name' is dropped, the
-- old application version cannot be deployed without re-adding the column.

ALTER TABLE users DROP COLUMN user_name;
