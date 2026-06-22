-- Add transcript column to stories table
ALTER TABLE stories 
ADD COLUMN transcript TEXT;

-- Add index for transcript search
CREATE INDEX idx_stories_transcript ON stories USING gin(to_tsvector('english', transcript));
