
#!/bin/bash
# GWS Admin - Automated GCP Project Setup
# This script automates the entire GCP setup process

set -e  # Exit on error

echo "🚀 GWS Admin GCP Setup"
echo "======================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "${RED}❌ gcloud CLI not found${NC}"
    echo "Please use Google Cloud Shell or install gcloud CLI"
    exit 1
fi

# Get or generate project name
if [ -z "$PROJECT_NAME" ]; then
    DEFAULT_NAME="gws-admin-$(date +%s)"
    read -p "Enter project name [$DEFAULT_NAME]: " PROJECT_NAME
    PROJECT_NAME=${PROJECT_NAME:-$DEFAULT_NAME}
fi

echo "${YELLOW}📋 Using project name: $PROJECT_NAME${NC}"

# Step 1: Create project
echo ""
echo "${YELLOW}Step 1/5: Creating GCP project...${NC}"
gcloud projects create $PROJECT_NAME \
    --name="GWS Admin - $(date +%Y-%m-%d)" \
    --set-as-default 2>/dev/null || {
    echo "${RED}⚠️  Project may already exist or name is taken${NC}"
    gcloud config set project $PROJECT_NAME
}

echo "${GREEN}✓ Project created/selected${NC}"

# Step 2: Link billing
if [ -z "$BILLING_ACCOUNT" ]; then
    echo ""
    echo "${YELLOW}Available billing accounts:${NC}"
    gcloud billing accounts list --format="table[box](displayName,name,open)"
    echo ""
    read -p "Enter billing account ID (from NAME column above): " BILLING_ACCOUNT
fi

echo ""
echo "${YELLOW}Step 2/5: Linking billing account...${NC}"
gcloud billing projects link $PROJECT_NAME --billing-account=$BILLING_ACCOUNT
echo "${GREEN}✓ Billing linked${NC}"

# Step 3: Enable APIs
echo ""
echo "${YELLOW}Step 3/5: Enabling APIs...${NC}"
gcloud services enable admin.googleapis.com
gcloud services enable gmail.googleapis.com
echo "${GREEN}✓ APIs enabled${NC}"

# Step 4: Create service account
echo ""
echo "${YELLOW}Step 4/5: Creating service account...${NC}"
SERVICE_ACCOUNT="gws-admin-sa@$PROJECT_NAME.iam.gserviceaccount.com"
gcloud iam service-accounts create gws-admin-sa \
    --display-name="GWS Admin Service Account" \
    --description="Service account for GWS Admin domain-wide delegation" 2>/dev/null || {
    echo "${YELLOW}⚠️  Service account already exists${NC}"
}
echo "${GREEN}✓ Service account ready${NC}"

# Step 5: Create key
echo ""
echo "${YELLOW}Step 5/5: Creating service account key...${NC}"
KEY_FILE="$HOME/gws-admin-key-$PROJECT_NAME.json"
gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account=$SERVICE_ACCOUNT
echo "${GREEN}✓ Key saved to: $KEY_FILE${NC}"

# Get client ID
echo ""
CLIENT_ID=$(gcloud iam service-accounts describe $SERVICE_ACCOUNT --format='value(oauth2ClientId)')
echo "${GREEN}✓ Client ID: $CLIENT_ID${NC}"

# Summary
echo ""
echo "${GREEN}🎉 Setup Complete!${NC}"
echo "======================"
echo ""
echo "📊 Project Details:"
echo "  Project ID: $PROJECT_NAME"
echo "  Project Number: $(gcloud projects describe $PROJECT_NAME --format='value(projectNumber)')"
echo "  Service Account: $SERVICE_ACCOUNT"
echo "  Client ID: $CLIENT_ID"
echo ""
echo "📁 Files:"
echo "  Key file: $KEY_FILE"
echo ""
echo "📝 Next Steps:"
echo "  1. Copy the key file contents (cat $KEY_FILE)"
echo "  2. Add Client ID to Domain-Wide Delegation in Google Admin Console"
echo "  3. Add these OAuth scopes:"
echo "     - https://www.googleapis.com/auth/gmail.settings.basic"
echo "     - https://www.googleapis.com/auth/gmail.settings.sharing"
echo "     - https://www.googleapis.com/auth/admin.directory.user.readonly"
echo "     - https://www.googleapis.com/auth/admin.directory.group.readonly"
echo ""
echo "🔧 Optional: Copy key to clipboard"
if command -v pbcopy &> /dev/null; then
    cat "$KEY_FILE" | pbcopy
    echo "   (Key copied to clipboard on Mac)"
elif command -v xclip &> /dev/null; then
    cat "$KEY_FILE" | xclip -selection clipboard
    echo "   (Key copied to clipboard on Linux)"
fi

echo ""
echo "${YELLOW}Displaying key (save this securely):${NC}"
cat "$KEY_FILE"
echo ""
