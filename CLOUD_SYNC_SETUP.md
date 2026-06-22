# Cloud Sync Setup Guide

## Prerequisites
- Supabase project already created
- Authentication enabled

## Step 1: Create Stories Table

Go to Supabase Dashboard > SQL Editor and run:

```sql
-- Create stories table
CREATE TABLE IF NOT EXISTS stories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT,
  audio_path TEXT NOT NULL,
  duration INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on user_id for faster queries
CREATE INDEX IF NOT EXISTS idx_stories_user_id ON stories(user_id);
CREATE INDEX IF NOT EXISTS idx_stories_created_at ON stories(created_at DESC);

-- Enable Row Level Security
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can only see their own stories
CREATE POLICY "Users can view own stories"
  ON stories FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own stories
CREATE POLICY "Users can insert own stories"
  ON stories FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own stories
CREATE POLICY "Users can update own stories"
  ON stories FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own stories
CREATE POLICY "Users can delete own stories"
  ON stories FOR DELETE
  USING (auth.uid() = user_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_stories_updated_at
  BEFORE UPDATE ON stories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## Step 2: Create Recordings Storage Bucket

Go to Supabase Dashboard > Storage and create a new bucket named `recordings`.

Then run this SQL in SQL Editor:

```sql
-- RLS Policies for recordings bucket
-- Users can upload to their own folder
CREATE POLICY "Users can upload to own folder"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'recordings' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Users can view their own recordings
CREATE POLICY "Users can view own recordings"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'recordings' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Users can delete their own recordings
CREATE POLICY "Users can delete own recordings"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'recordings' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
```

## Step 3: Test Cloud Sync

1. Login to the app
2. Record a new story
3. Stop recording - it should automatically upload to cloud
4. Check the stories list - it should show the uploaded story
5. Try playing the story
6. Try deleting the story - it should delete from both cloud and local

## Troubleshooting

**Upload fails**: Check Supabase Storage bucket exists and RLS policies are set correctly.

**Can't see stories**: Check stories table exists and RLS policies allow SELECT.

**Delete fails**: Check both storage and database RLS policies allow DELETE.
