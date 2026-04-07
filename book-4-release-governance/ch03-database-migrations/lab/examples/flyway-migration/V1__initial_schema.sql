-- V1__initial_schema.sql
-- Creates the initial users table with the legacy 'user_name' column.
-- This represents the starting state before the column rename migration.

CREATE TABLE users (
    id         SERIAL PRIMARY KEY,
    user_name  VARCHAR(255) NOT NULL,
    email      VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

INSERT INTO users (user_name, email) VALUES
    ('alice', 'alice@example.com'),
    ('bob',   'bob@example.com'),
    ('carol', 'carol@example.com');
