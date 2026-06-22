This PR implements AI-powered story metadata generation using OpenAI's Whisper API and GPT-3.5.

## Features
- **Whisper Transcription**: Automatically transcribe audio recordings to text
- **AI Title Generation**: Generate 3-5 title suggestions from transcripts
- **AI Tag Generation**: Generate 3-8 relevant tags from transcripts
- **Enhanced Story Entity**: Added transcript and tags fields to Story model
- **AI Metadata UI**: New screen for reviewing and selecting AI-generated metadata
- **Database Migrations**: Added transcript column, tags table, and story_tags junction table

## Database Changes
- Added transcript column to stories table
- Created tags table for storing tag names
- Created story_tags junction table for many-to-many relationship
- Added full-text search index on transcript

## Implementation Details
- Integrated OpenAI API for Whisper transcription
- Used GPT-3.5 for title and tag generation
- Updated story creation flow to include AI metadata generation
- Added configuration for OpenAI API key

## Configuration
Users need to set their OpenAI API key in lib/core/constants/supabase_config.dart

## Testing
- Run database migrations in Supabase
- Set OpenAI API key
- Test recording and upload flow
- Verify AI metadata generation
