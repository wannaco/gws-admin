# GWS Admin - GCP Project Setup Tutorial

This interactive tutorial guides customers through creating and configuring a Google Cloud Platform project for GWS Admin.

## Quick Start for Customers

### Option A: Open in Cloud Shell (Recommended)

Click this button to open the tutorial directly in Google Cloud Shell:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/your-org/gws-admin&cloudshell_tutorial=tutorial.md&cloudshell_workspace=cloud-shell-tutorial)

### Option B: Manual Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click the Cloud Shell icon (terminal icon) in the top right
3. Run: `git clone https://github.com/your-org/gws-admin && cd gws-admin/cloud-shell-tutorial`
4. Run: `cloudshell launch-tutorial tutorial.md`

## What This Tutorial Does

- Creates a new GCP project
- Enables required APIs (Firebase, Firestore, Cloud Functions, etc.)
- Links billing account
- Creates service account for domain-wide delegation
- Generates a JSON key for download

## Files in This Directory

- `tutorial.md` - The interactive tutorial steps
- `setup.sh` - Automated setup script
- `cleanup.sh` - Cleanup script if needed

## Customization

To customize for your app:
1. Update the `tutorial.md` with your specific app name and URLs
2. Modify `setup.sh` to include any additional APIs or services
3. Update the README with your repo URL

## Testing

Test the tutorial:
```bash
cloudshell launch-tutorial tutorial.md
```

## Troubleshooting

If customers get stuck:
1. Ensure they have a Google account
2. Check they have billing permissions
3. Verify Cloud Shell is enabled for their organization
