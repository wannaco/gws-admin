# GWS Admin Setup Tutorial

## Welcome to GWS Admin Setup!

This tutorial will help you create and configure a Google Cloud Platform project for GWS Admin. It takes about 5-10 minutes.

<walkthrough-tutorial-duration duration="10"></walkthrough-tutorial-duration>

## What you'll do

- Create a new GCP project
- Enable required APIs
- Set up billing
- Create a service account
- Download your credentials

Click **Next** to begin.

## Step 1: Set Your Project Name

First, let's set a name for your project.

In the terminal below, run:

```bash
export PROJECT_NAME="gws-admin-$(date +%s)"
echo "Project name set to: $PROJECT_NAME"
```

<walkthrough-footnote>You can change this to any unique name you prefer.</walkthrough-footnote>

## Step 2: Create Your GCP Project

Now let's create the project:

```bash
gcloud projects create $PROJECT_NAME \
  --name="GWS Admin - $(date +%Y-%m-%d)" \
  --set-as-default
echo "✓ Project created: $PROJECT_NAME"
```

<walkthrough-footnote>This creates a new GCP project in your organization.</walkthrough-footnote>

## Step 3: Link Billing Account

You need to link a billing account. First, let's find your billing account ID:

```bash
gcloud billing accounts list
```

Copy the **ACCOUNT_ID** (looks like: `0X0X0X-0X0X0X-0X0X0X`), then run:

```bash
export BILLING_ACCOUNT="YOUR_BILLING_ACCOUNT_ID"
gcloud billing projects link $PROJECT_NAME --billing-account=$BILLING_ACCOUNT
echo "✓ Billing linked"
```

<walkthrough-warning-title>Don't have a billing account?</walkthrough-warning-title>
<walkthrough-warning>
Go to [Google Cloud Billing](https://console.cloud.google.com/billing) to create one first.
</walkthrough-warning>

## Step 4: Enable Required APIs

Now let's enable all the APIs GWS Admin needs:

```bash
gcloud services enable firebase.googleapis.com \
  firestore.googleapis.com \
  cloudfunctions.googleapis.com \
  secretmanager.googleapis.com \
  admin.googleapis.com \
  gmail.googleapis.com

echo "✓ APIs enabled"
```

<walkthrough-footnote>This may take 1-2 minutes.</walkthrough-footnote>

## Step 5: Create Service Account

Create a service account for domain-wide delegation:

```bash
gcloud iam service-accounts create gws-admin-sa \
  --display-name="GWS Admin Service Account" \
  --description="Service account for GWS Admin domain-wide delegation"

echo "✓ Service account created"
```

## Step 6: Create and Download Key

Create a JSON key for the service account:

```bash
gcloud iam service-accounts keys create ~/gws-admin-key.json \
  --iam-account=gws-admin-sa@$PROJECT_NAME.iam.gserviceaccount.com

echo "✓ Key created at: ~/gws-admin-key.json"
cat ~/gws-admin-key.json
```

<walkthrough-success-title>Key Created!</walkthrough-success-title>
<walkthrough-success>
Your key is displayed above. Copy this entire JSON and save it securely. You'll paste it into GWS Admin settings.
</walkthrough-success>

## Step 7: Grant Domain-Wide Delegation Authority (Manual Step)

<walkthrough-warning-title>Important: Manual Step Required</walkthrough-warning-title>
<walkthrough-warning>
You must complete this step in the Google Admin Console for your domain.
</walkthrough-warning>

1. Go to [Google Admin Console](https://admin.google.com) → Security → API Controls → Domain-wide Delegation
2. Click "Manage Domain-Wide Delegation"
3. Click "Add new"
4. Enter the Client ID: 

```bash
echo "Client ID: $(gcloud iam service-accounts describe gws-admin-sa@$PROJECT_NAME.iam.gserviceaccount.com --format='value(oauth2ClientId)')"
```

5. Add these OAuth scopes (one per line):
   - `https://www.googleapis.com/auth/gmail.settings.basic`
   - `https://www.googleapis.com/auth/gmail.settings.sharing`
   - `https://www.googleapis.com/auth/admin.directory.user.readonly`
   - `https://www.googleapis.com/auth/admin.directory.group.readonly`

6. Click "Authorize"

## Step 8: Get Your Project ID

Your project ID is:

```bash
echo "Project ID: $PROJECT_NAME"
echo "Project Number: $(gcloud projects describe $PROJECT_NAME --format='value(projectNumber)')"
```

<walkthrough-conclusion-title>Setup Complete!</walkthrough-conclusion-title>

## Next Steps

1. **Copy the JSON key** from Step 6
2. **Complete domain-wide delegation** in Step 7
3. **Go to GWS Admin** and paste your credentials in Settings

<walkthrough-conclusion>
**Need help?** Contact support at support@thinkcloud.dev
</walkthrough-conclusion>

## Troubleshooting

**"Billing account not found"**
- Ensure you have billing administrator permissions
- Check [Google Cloud Billing](https://console.cloud.google.com/billing)

**"Permission denied"**
- Make sure you're a project owner or have Project Creator role
- Check with your Google Workspace admin

**"API already enabled"**
- This is fine, you can proceed

**Lost your key?**
```bash
# Recreate it
gcloud iam service-accounts keys create ~/gws-admin-key-new.json \
  --iam-account=gws-admin-sa@$PROJECT_NAME.iam.gserviceaccount.com
```
