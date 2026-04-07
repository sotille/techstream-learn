# Lab 3 — Safe Database Schema Migration with Zero-Downtime Patterns

**Estimated time:** 50–65 minutes
**Difficulty:** Intermediate
**Prerequisites:**
- Docker and Docker Compose installed
- Basic SQL familiarity (SELECT, ALTER TABLE, UPDATE)
- Chapter 1 lab completed (or understanding of blue-green deployment)

---

## Overview

You will implement a zero-downtime column rename using the expand/contract pattern on a PostgreSQL database. The lab uses Docker Compose to run PostgreSQL and a Flyway container for migration management.

The scenario: the `users` table stores usernames in a column called `user_name`. The new application version expects a column called `username`. You will perform this rename without any downtime using a three-phase migration.

---

## Setup

### Step 1 — Start PostgreSQL

```bash
docker run -d \
  --name lab-postgres \
  -e POSTGRES_USER=labuser \
  -e POSTGRES_PASSWORD=labpass \
  -e POSTGRES_DB=labdb \
  -p 5432:5432 \
  postgres:16-alpine
```

### Step 2 — Create the initial schema and seed data

```bash
docker exec -i lab-postgres psql -U labuser -d labdb <<'EOF'
CREATE TABLE users (
  id         SERIAL PRIMARY KEY,
  user_name  VARCHAR(255) NOT NULL,
  email      VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT now()
);

INSERT INTO users (user_name, email) VALUES
  ('alice', 'alice@example.com'),
  ('bob', 'bob@example.com'),
  ('carol', 'carol@example.com');

SELECT * FROM users;
EOF
```

Expected output: 3 rows with `user_name` column.

---

## Phase 1 — Expand: Add the New Column

Add `username` without removing `user_name`. The old application version continues to work. The new application version can begin writing to `username`.

```bash
docker exec -i lab-postgres psql -U labuser -d labdb <<'EOF'
-- Phase 1: Add new column (non-breaking)
ALTER TABLE users ADD COLUMN username VARCHAR(255);

-- Backfill: copy existing data into the new column
UPDATE users SET username = user_name WHERE username IS NULL;

-- Add NOT NULL constraint only AFTER backfill completes
ALTER TABLE users ALTER COLUMN username SET NOT NULL;

-- Verify both columns coexist
SELECT id, user_name, username, email FROM users;
EOF
```

**Checkpoint:** Both `user_name` and `username` columns exist. All rows have data in both.

**Backward compatibility test:** Run a query using the OLD column name — it should still work:

```bash
docker exec -i lab-postgres psql -U labuser -d labdb -c \
  "SELECT id, user_name FROM users WHERE user_name = 'alice';"
```

This query represents the old application version reading the database. It succeeds because `user_name` still exists.

---

## Phase 2 — Deploy the New Application Version

In a real deployment, this is where you would switch traffic from the old application version to the new one (see Lab 1 for the blue-green switch). In this lab, simulate the new application reading the new column:

```bash
docker exec -i lab-postgres psql -U labuser -d labdb <<'EOF'
-- Simulate new application version using the new column name
SELECT id, username, email FROM users;

-- Simulate new application writing to the new column
INSERT INTO users (user_name, username, email) VALUES
  ('dave', 'dave', 'dave@example.com');

SELECT id, user_name, username, email FROM users;
EOF
```

Notice: in Phase 2, the new application writes to BOTH columns to maintain backward compatibility (in case rollback is needed). This dual-write is temporary — it ends when Phase 3 is complete.

---

## Phase 3 — Contract: Remove the Old Column

Only execute Phase 3 after:
- The new application version has been running stably for your defined observation window (e.g., 24 hours, 1 week)
- A rollback to the old application version is no longer required
- Change management has approved the schema cleanup

```bash
docker exec -i lab-postgres psql -U labuser -d labdb <<'EOF'
-- Phase 3: Remove old column (only after new version is confirmed stable)
ALTER TABLE users DROP COLUMN user_name;

-- Verify final schema
\d users
SELECT * FROM users;
EOF
```

**Backward compatibility test — confirm old queries now fail:**

```bash
docker exec -i lab-postgres psql -U labuser -d labdb -c \
  "SELECT user_name FROM users;" 2>&1 || true
```

Expected: error indicating `user_name` column does not exist. The old application version would now fail if deployed — this confirms Phase 3 must only run after the old version is fully decommissioned.

---

## Rollback Exercise

Before running Phase 3, simulate what happens if you need to rollback to the old application after Phase 1:

1. The old application queries `user_name` — succeeds (column still exists)
2. The old application inserts using `user_name` — succeeds
3. The new `username` column may have a gap (the old app doesn't populate it), but the database remains consistent for the old version

This demonstrates that Phase 1 + Phase 2 are rollback-safe. Phase 3 is the point of no return.

---

## Pipeline Migration Gate (Advanced)

Review the example Flyway migration file `examples/flyway-migration/V2__add_username_column.sql`. This file implements Phase 1 as a Flyway versioned migration.

To run it with Flyway:

```bash
docker run --rm \
  --network host \
  -v "$(pwd)/examples/flyway-migration:/flyway/sql" \
  flyway/flyway:10 \
  -url=jdbc:postgresql://localhost:5432/labdb \
  -user=labuser \
  -password=labpass \
  migrate
```

Flyway records each migration in the `flyway_schema_history` table. Run this to view migration history:

```bash
docker exec -i lab-postgres psql -U labuser -d labdb -c \
  "SELECT version, description, installed_on, success FROM flyway_schema_history ORDER BY installed_rank;"
```

---

## Cleanup

```bash
docker stop lab-postgres && docker rm lab-postgres
```

---

## Reflection Questions

1. In Phase 2, the new application must write to BOTH `user_name` and `username` to maintain rollback safety. What happens to data consistency if the application writes to `username` only? Under what circumstances could this cause data loss?

2. The expand/contract pattern requires three separate deployments for a single column rename. A colleague argues this is too slow and they should just "schedule downtime." What are the business arguments against downtime windows for schema changes?

3. For a table with 50 million rows, the `UPDATE users SET username = user_name` backfill in Phase 1 could take 30+ minutes and lock the table. What approach would you use for the backfill on a table of this size?

4. How does this pattern interact with audit logging requirements? If a regulated system requires that every data change be attributable to an application version, how do you maintain that audit trail during the dual-column transition period?
