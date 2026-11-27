-- V12: Convert INET columns that are mapped as String in JPA entities to VARCHAR(45)
-- PostgreSQL INET type requires explicit cast from varchar; since entities store these
-- as plain strings, convert them to VARCHAR to avoid type mismatch errors.

ALTER TABLE refresh_tokens
    ALTER COLUMN ip_address TYPE VARCHAR(45) USING ip_address::text;
