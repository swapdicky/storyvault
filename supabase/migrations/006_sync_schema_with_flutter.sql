-- Complete migration to sync Supabase schema with Flutter app
-- This script adds transcript column, tags table, and story_tags junction table
-- Safe for Supabase PostgreSQL with proper existence checks

-- Add transcript column to stories table (nullable since Whisper not implemented yet)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'stories' AND column_name = 'transcript'
  ) THEN
    ALTER TABLE stories ADD COLUMN transcript TEXT;
  END IF;
END $$;

-- Create GIN index for full-text search on transcript
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE indexname = 'idx_stories_transcript_gin'
  ) THEN
    CREATE INDEX idx_stories_transcript_gin ON stories USING gin(to_tsvector('english', transcript));
  END IF;
END $$;

-- Create tags table
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tags') THEN
    CREATE TABLE tags (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      name TEXT NOT NULL UNIQUE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
  END IF;
END $$;

-- Enable RLS on tags
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for tags (safe with DO block)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated users can read tags' AND tablename = 'tags') THEN
    CREATE POLICY "Authenticated users can read tags"
      ON tags FOR SELECT
      TO authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated users can insert tags' AND tablename = 'tags') THEN
    CREATE POLICY "Authenticated users can insert tags"
      ON tags FOR INSERT
      TO authenticated
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated users can update tags' AND tablename = 'tags') THEN
    CREATE POLICY "Authenticated users can update tags"
      ON tags FOR UPDATE
      TO authenticated
      USING (true);
  END IF;
END $$;

-- Create updated_at trigger function (safe to recreate)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for tags (safe with DO block)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'update_tags_updated_at') THEN
    CREATE TRIGGER update_tags_updated_at
      BEFORE UPDATE ON tags
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- Create story_tags junction table (many-to-many relationship)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'story_tags') THEN
    CREATE TABLE story_tags (
      story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
      tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      PRIMARY KEY (story_id, tag_id)
    );
  END IF;
END $$;

-- Enable RLS on story_tags
ALTER TABLE story_tags ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for story_tags (safe with DO block)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated users can read story_tags' AND tablename = 'story_tags') THEN
    CREATE POLICY "Authenticated users can read story_tags"
      ON story_tags FOR SELECT
      TO authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated users can insert story_tags' AND tablename = 'story_tags') THEN
    CREATE POLICY "Authenticated users can insert story_tags"
      ON story_tags FOR INSERT
      TO authenticated
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated users can delete story_tags' AND tablename = 'story_tags') THEN
    CREATE POLICY "Authenticated users can delete story_tags"
      ON story_tags FOR DELETE
      TO authenticated
      USING (true);
  END IF;
END $$;

-- Create indexes for better query performance (safe with DO block)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_story_tags_story_id') THEN
    CREATE INDEX idx_story_tags_story_id ON story_tags(story_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_story_tags_tag_id') THEN
    CREATE INDEX idx_story_tags_tag_id ON story_tags(tag_id);
  END IF;
END $$;
