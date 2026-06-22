-- Remove tags and story_tags tables to simplify schema
-- This migration removes the AI metadata tables for MVP

-- Drop story_tags junction table
DROP TABLE IF EXISTS story_tags CASCADE;

-- Drop tags table
DROP TABLE IF EXISTS tags CASCADE;

-- Note: transcript column is kept for manual entry
-- GIN index on transcript is kept for potential future use
