# Chapter 3 — Database Migration Safety: Schema Changes Without Downtime

**Volume:** Book 4 — Release Engineering & DevSecOps Governance
**Framework reference:** [release-orchestration-framework: database-migration-safety.md](../../../../release-orchestration-framework/docs/database-migration-safety.md) | [release-orchestration-framework: progressive-delivery.md](../../../../release-orchestration-framework/docs/progressive-delivery.md)

---

## What You Will Learn

Database schema changes are the most operationally risky part of a software release. Unlike application code, database migrations cannot be rolled back by deploying the previous version — a dropped column, a renamed table, or a type change persists in the database regardless of which application version is running. This fundamental asymmetry between application and database rollback is the source of most release-related downtime.

By the end of this chapter, you will understand:

1. **Why database migrations fail at deployment time** — the incompatibility window between old and new application code and new schema
2. **The expand/contract pattern** — the foundational technique for safe zero-downtime schema changes
3. **Migration tooling** — how Flyway, Liquibase, and Alembic implement versioned migrations and what their limitations are
4. **Pipeline integration** — where database migrations run in the CI/CD pipeline and how to gate them
5. **Rollback strategy** — what can and cannot be rolled back, and how to design for rollback-safe migrations

---

## The Incompatibility Window Problem

Consider a migration that renames a column: `user_name` → `username`. If you run the migration and then deploy the new application version simultaneously, there is a window — however brief — where the old application version is still running against a database with the new column name. All queries from the old version that reference `user_name` fail.

In a rolling deployment, this window is not brief — it is the entire duration of the rolling update. Pods running the old version will fail for every database query until they are replaced. In a blue-green deployment, the problem is different: if you run the migration before the traffic switch, the old (blue) environment may fail immediately.

The expand/contract pattern eliminates this incompatibility window.

---

## The Expand/Contract Pattern

The expand/contract pattern (also called Parallel Change) decomposes a schema change into three distinct phases, each deployed separately:

### Phase 1 — Expand

Add new structures without removing old ones. Both old and new application versions can operate against the expanded schema.

**Example:** Adding a new `username` column while keeping `user_name`:
```sql
ALTER TABLE users ADD COLUMN username VARCHAR(255);
-- Copy existing data into the new column
UPDATE users SET username = user_name WHERE username IS NULL;
```

After Phase 1: old application reads/writes `user_name`, new application reads/writes `username`. Both columns exist. No incompatibility.

### Phase 2 — Migrate

Deploy the new application version (which uses `username`). The expanded schema supports both versions simultaneously. If rollback is needed, the old application version still works.

After Phase 2: new application is deployed and stable. Old version is no longer in use. Both columns still exist in the database.

### Phase 3 — Contract

Once the new application has been confirmed stable and the old version will not be rolled back to, remove the old structure.

```sql
ALTER TABLE users DROP COLUMN user_name;
```

After Phase 3: schema is clean. Migration is complete. Total downtime: zero.

---

## When Expand/Contract Is Not Enough

Some schema changes cannot be decomposed this way:

- **Type changes with incompatible representations** (e.g., integer → UUID) require a full data migration with dual writes and reads during the transition period — more complex than a simple column add/drop
- **Renaming tables** (not just columns) requires application-level view abstraction to avoid coordinating two simultaneous refactors
- **Adding NOT NULL constraints without defaults** cannot be done safely in a single migration on tables with existing rows; they require a multi-phase approach with backfill

These scenarios are covered in depth in the [release-orchestration-framework: database-migration-safety.md](../../../../release-orchestration-framework/docs/database-migration-safety.md).

---

## Migration Tooling

| Tool | Primary languages | Migration format | Highlights |
|------|-------------------|-----------------|------------|
| Flyway | Java, any (SQL-native) | SQL or Java | Simple, convention-based, no XML; good for teams that prefer plain SQL |
| Liquibase | Java, any | XML, YAML, JSON, SQL | Rich changeset metadata, rollback support, diff-based migration generation |
| Alembic | Python | Python scripts | Tight SQLAlchemy integration; autogenerate from model changes |
| golang-migrate | Go, any | SQL | Lightweight, filesystem-based, Docker-friendly |

All tools share the same core concept: a version-controlled sequence of migration files, a metadata table in the database that tracks which migrations have been applied, and idempotent application logic that skips already-applied migrations.

---

## Pipeline Integration

Migrations should run as a distinct pipeline stage — not interleaved with application deployment:

```
Test → Build → Migrate (Phase 1: Expand) → Deploy New Version → Verify → Migrate (Phase 3: Contract)
```

Key pipeline requirements:
- Migration stage runs with a service account that has DDL permissions; the application runtime account should not have DDL permissions
- Migration output (which migrations ran, duration, row counts) is captured as a pipeline artifact for audit
- A migration dry-run (`--dry-run` or equivalent) runs in the CI stage to catch SQL errors before they reach production
- Migrations on large tables (> 1M rows) should use online schema change tools (pt-online-schema-change, gh-ost) to avoid locking

---

## Lab Exercise

The lab for this chapter walks through:

1. Implementing the expand/contract pattern for a column rename on a sample PostgreSQL database
2. Running migrations with Flyway in a Docker environment
3. Verifying backward compatibility during the Expand phase using the old application version
4. Completing the Contract phase after confirming the new version is stable
5. Testing the migration pipeline gate (failing a migration that does not follow expand/contract)

See [lab/README.md](lab/README.md) to begin.

---

## Further Reading

- [release-orchestration-framework: database-migration-safety.md](../../../../release-orchestration-framework/docs/database-migration-safety.md) — full reference on migration patterns, tooling, and failure modes
- [release-orchestration-framework: progressive-delivery.md](../../../../release-orchestration-framework/docs/progressive-delivery.md) — how blue-green and canary deployments interact with database migrations
- [Chapter 1 — Blue-Green Deployments](../ch01-blue-green-deployment/README.md) — the deployment strategy that makes zero-downtime migrations operationally tractable
