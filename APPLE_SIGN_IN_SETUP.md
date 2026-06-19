# Apple Sign In Setup Guide

This guide explains how to configure Apple Sign In for StoryVault.

## Prerequisites

- Apple Developer Account
- Xcode installed
- Supabase project set up

## Step 1: Configure Apple Sign In in Xcode

1. Open the iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Select the `Runner` target in the project navigator

3. Go to the "Signing & Capabilities" tab

4. Click "+ Capability" and add "Sign in with Apple"

5. Ensure your team is selected and the bundle identifier is correct

## Step 2: Configure Supabase Apple Provider

1. Go to your Supabase project dashboard

2. Navigate to Authentication > Providers > Apple

3. Enable the Apple provider

4. Configure the following:
   - **Client ID**: Your Apple Services ID (from Apple Developer portal)
   - **Apple Team ID**: Your Apple Developer Team ID
   - **Private Key**: Generate and download from Apple Developer portal
   - **Key ID**: The ID of the private key
   - **Bundle ID**: Your app's bundle identifier (e.g., com.example.storyvault)

## Step 3: Configure Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com)

2. Navigate to Certificates, Identifiers & Profiles

3. Create a new App ID with the following:
   - Bundle ID: Match your Xcode bundle identifier
   - Capabilities: Check "Sign in with Apple"

4. Create a Services ID:
   - Description: StoryVault
   - Bundle ID: Your app's bundle identifier
   - Return URLs: Add your Supabase callback URL

5. Generate a private key for Sign in with Apple:
   - Go to Keys section
   - Create a new key
   - Check "Sign in with Apple"
   - Download the .p8 file (you can only download it once!)

## Step 4: Update Supabase Config

Update the Supabase configuration in `lib/core/constants/supabase_config.dart` with your actual credentials:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

## Step 5: Test the Integration

1. Run the app on a physical device or simulator
2. Try signing in with Apple
3. Verify the user is created in Supabase Auth

## Troubleshooting

- **"Sign in with Apple is not enabled"**: Ensure the capability is added in Xcode
- **"Invalid client ID"**: Check that your Services ID matches in Supabase
- **"Key not found"**: Ensure the private key is correctly uploaded to Supabase
- **Simulator issues**: Apple Sign In works best on physical devices

## Notes

- Apple Sign In is required for apps that offer other social login options
- The sign_in_with_apple package handles the OAuth flow automatically
- User email and name are only provided on the first sign-in
