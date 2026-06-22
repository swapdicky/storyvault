-- Complete migration to sync Supabase schema with Flutter app
-- This script adds transcript column, tags table, and story_tags junction table

-- Add transcript column to stories table
ALTER TABLE stories ADD COLUMN IF NOT EXISTS transcript TEXT;

-- Create GIN index for full-text search on transcript
CREATE INDEX IF NOT EXISTS idx_stories_transcript_gin ON stories USING gin(to_tsvector('english', transcript));

-- Create tags table
CREATE TABLE IF NOT EXISTS tags (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on tags
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;

-- RLS policies for tags
CREATE POLICY IF NOT EXISTS "Authenticated users can read tags"
  ON tags FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY IF NOT EXISTS "Authenticated users can insert tags"
  ON tags FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "Authenticated users can update tags"
  ON tags FOR UPDATE
  TO authenticated
  USING (true);

-- Create updated_at trigger for tags
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER IF NOT EXISTS update_tags_updated_at
  BEFORE UPDATE ON tags
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create story_tags junction table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS story_tags (
  story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (story_id, tag_id)
);

-- Enable RLS on story_tags
ALTER TABLE story_tags ENABLE ROW LEVEL SECURITY;

-- RLS policies for story_tags
CREATE POLICY IF NOT EXISTS "Authenticated users can read story_tags"
  ON story_tags FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY IF NOT EXISTS "Authenticated users can insert story_tags"
  ON story_tags FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "Authenticated users can delete story_tags"
  ON story_tags FOR DELETE
  TO authenticated
  USING (true);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_story_tags_story_id ON story_tags(story_id);
CREATE INDEX IF NOT EXISTS idx_story_tags_tag_id ON story_tags(tag_id);
