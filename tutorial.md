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

## Step 1: Link Your Account to gcloud

Cloud Shell is already authenticated via your browser session, but gcloud CLI needs the account explicitly registered in its config. Run:

```bash
gcloud auth login
```

Type **Y** at the prompt — this does **not** re-authenticate you. It just links your existing Cloud Shell session to gcloud's configuration so commands like `gcloud projects create` work correctly.

## Step 2: Set Your Project Name

Set a name for your new GCP project:

```bash
export PROJECT_NAME="gws-admin-$(date +%s)"
echo "Project name: $PROJECT_NAME"
```

<walkthrough-footnote>You can change this to any unique name you prefer.</walkthrough-footnote>

## Step 3: Create Your GCP Project

Now let's create the project:

```bash
gcloud projects create $PROJECT_NAME \
  --name="GWS Admin - $(date +%Y-%m-%d)"
gcloud config set project $PROJECT_NAME
echo "Project created: $PROJECT_NAME"
```

<walkthrough-footnote>This creates a new GCP project in your organization.</walkthrough-footnote>

## Step 3: Enable Required APIs

Now let's enable the APIs GWS Admin needs:

```bash
gcloud services enable admin.googleapis.com
gcloud services enable gmail.googleapis.com

echo "APIs enabled"
```

<walkthrough-footnote>These are the Admin SDK and Gmail APIs for domain-wide delegation. Billing is NOT required.</walkthrough-footnote>

## Step 3: Create Service Account

Create a service account for domain-wide delegation:

```bash
gcloud iam service-accounts create gws-admin-sa \
  --display-name="GWS Admin Service Account" \
  --description="Service account for GWS Admin domain-wide delegation"

echo "Service account created"
```

## Step 4: Create and Download Key

> **⚠️ Enterprise org policy note:** If your Google Cloud organisation enforces
> `iam.disableServiceAccountKeyCreation`, this step will fail. See the
> **Troubleshooting** section at the end of this tutorial for the fix before
> continuing.

Create a JSON key for the service account:

```bash
gcloud iam service-accounts keys create ~/gws-admin-key.json \
  --iam-account=gws-admin-sa@$PROJECT_NAME.iam.gserviceaccount.com

echo "Key created at: ~/gws-admin-key.json"
cat ~/gws-admin-key.json
```

<walkthrough-success-title>Key Created!</walkthrough-success-title>
<walkthrough-success>
Your key is displayed above. Copy this entire JSON and save it securely. You'll paste it into GWS Admin settings.
</walkthrough-success>

## Step 5: Grant Domain-Wide Delegation Authority (Manual Step)

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

## Step 6: Get Your Project ID

Your project ID is:

```bash
echo "Project ID: $PROJECT_NAME"
echo "Project Number: $(gcloud projects describe $PROJECT_NAME --format='value(projectNumber)')"
```

<walkthrough-conclusion-title>Setup Complete!</walkthrough-conclusion-title>

## Next Steps

1. **Copy the JSON key** from Step 4
2. Save the json from the console as with a desired name like credentiasgws.json
4. **Complete domain-wide delegation** in Step 5
5. **Go to GWS Admin** and upload your  credentials json file in Settings

<walkthrough-conclusion>
**Need help?** Contact support at support@thinkcloud.dev
</walkthrough-conclusion>

## Troubleshooting

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

**"Service account key creation is disabled" (iam.disableServiceAccountKeyCreation)**

Your Google Workspace organisation has an org policy that prevents JSON key
downloads. The setup script will automatically attempt to override this for
you — if it succeeds you don't need to do anything manually.

If the auto-fix fails (e.g. you see "Could not override the org policy"), run
this command yourself (requires `roles/orgpolicy.policyAdmin`):

```bash
gcloud resource-manager org-policies disable-enforce \
  constraints/iam.disableServiceAccountKeyCreation \
  --project=$PROJECT_NAME
```

Then re-run Step 4. If you don't have that role, ask your GCP Org Policy
Administrator to run the command above for your project.
