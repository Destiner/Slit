# Release Process

This guide covers submitting a new Slit release to the App Store using the `asc` CLI and Xcode Cloud.

## Authentication (one-time setup)

Register your API key with asc:

```bash
asc auth login \
  --name "CLI" \
  --key-id "YOUR_KEY_ID" \
  --issuer-id "YOUR_ISSUER_ID" \
  --private-key /path/to/AuthKey.p8
```

Credentials are stored in the keychain. You won't need the .p8 file after this.

## Release Steps

### 1. Bump the version

Update `MARKETING_VERSION` in `Slit.xcodeproj/project.pbxproj`:

```bash
# Find current version
grep 'MARKETING_VERSION' Slit.xcodeproj/project.pbxproj

# Update to new version (e.g., 1.2.3)
sed -i '' 's/MARKETING_VERSION = 1.2.2;/MARKETING_VERSION = 1.2.3;/g' Slit.xcodeproj/project.pbxproj
```

### 2. Commit and push

```bash
git add Slit.xcodeproj/project.pbxproj
git commit -m "chore: bump version to 1.2.3"
git push origin main
```

This triggers an Xcode Cloud build automatically.

### 3. Wait for Xcode Cloud build

```bash
# List workflows to get workflow ID
asc xcode-cloud workflows --app "APP_ID" --output table

# Check build runs
asc xcode-cloud build-runs --workflow-id "WORKFLOW_ID" --output table

# Wait for build to complete
asc xcode-cloud status --run-id "BUILD_RUN_ID" --wait --output table
```

### 4. Create App Store version

```bash
asc versions create --app "APP_ID" --version "1.2.3" --platform IOS
```

### 5. Attach build to version

```bash
# Get the latest build ID
asc builds list --app "APP_ID" --sort -uploadedDate --limit 1

# Attach build to version
asc versions attach-build --version-id "VERSION_ID" --build "BUILD_ID"
```

### 6. Set release notes

```bash
asc app-info set --app "APP_ID" --locale "en-US" --whats-new "Bug fixes and improvements" --version "1.2.3" --platform IOS
```

### 7. Submit for review

```bash
asc submit create --app "APP_ID" --version-id "VERSION_ID" --build "BUILD_ID" --confirm
```

### 8. Verify submission

```bash
asc versions list --app "APP_ID" --output table
```

The version should show `WAITING_FOR_REVIEW` status.

## Reference

- App ID: `APP_ID`
- Xcode Cloud Workflow ID: `WORKFLOW_ID`
