-- Create story_tags junction table (many-to-many relationship)
CREATE TABLE story_tags (
  story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (story_id, tag_id)
);

-- Enable RLS
ALTER TABLE story_tags ENABLE ROW LEVEL SECURITY;

-- RLS policies for story_tags
-- Allow authenticated users to read story_tags
CREATE POLICY "Authenticated users can read story_tags"
  ON story_tags FOR SELECT
  TO authenticated
  USING (true);

-- Allow authenticated users to insert story_tags
CREATE POLICY "Authenticated users can insert story_tags"
  ON story_tags FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Allow authenticated users to delete story_tags
CREATE POLICY "Authenticated users can delete story_tags"
  ON story_tags FOR DELETE
  TO authenticated
  USING (true);

-- Create indexes for better query performance
CREATE INDEX idx_story_tags_story_id ON story_tags(story_id);
CREATE INDEX idx_story_tags_tag_id ON story_tags(tag_id);
