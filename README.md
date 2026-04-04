# GWS Admin — Google Workspace Advanced Admin

A multi-tenant Google Workspace administration tool for managing Gmail delegation, forwarding, filters, and vacation auto-responders across your domain. Built with SvelteKit, Firebase, and Google APIs.

## Features

- **Gmail Delegation:** Add or remove delegates for any user's mailbox across the domain.
- **Forwarding Rules:** Configure email forwarding addresses centrally.
- **Gmail Filters:** Create and manage Gmail filters for user mailboxes.
- **Vacation Responders:** Set up and schedule out-of-office auto-replies.
- **Domain User Listing:** Browse all users in your Google Workspace domain.
- **Audit Logging:** Every mutation is recorded with actor, action, and timestamp.
- **Multi-tenant:** Supports multiple workspaces with team collaboration and role-based access.

## Architecture

```
SvelteKit Frontend (Firebase Hosting)
  ↕ Firebase Auth (ID token)
Cloud Functions (index.js)
  ↕ googleapis (JWT impersonation via domain-wide delegation)
Gmail API / Admin Directory API
```

## Cloud Functions API

All GWS endpoints verify the caller's Firebase ID token and tenant membership before executing.

| Function | Method(s) | Description |
|---|---|---|
| `gwsListUsers` | GET | List domain users via Admin Directory API |
| `gwsDelegation` | GET/POST/DELETE | List, add, or remove Gmail delegates |
| `gwsForwarding` | GET/POST | Get forwarding config, create addresses, update auto-forwarding |
| `gwsFilters` | GET/POST/DELETE | List, create, or delete Gmail filters |
| `gwsVacation` | GET/POST | Get or update vacation auto-reply settings |
| `gwsSaveDomainConfig` | POST | Save domain + service account key (tests connection first) |
| `listTenants` | GET | Owner-only: list all tenants |
| `setTenantSuspended` | POST | Owner-only: suspend/unsuspend a tenant |
| `validatePayPalSubscription` | POST | Validate PayPal subscription and update tenant |
| `paypalWebhook` | POST | PayPal webhook receiver with signature verification |
| `paypalDiagnostics` | GET | Debug PayPal plan configuration |
| `onTenantPlanSet` | Firestore trigger | Emit webhook when tenant plan transitions from empty → non-empty |

## Firestore Schema

### `tenants/{tenantId}`

| Field | Type | Description |
|---|---|---|
| `plan` | string | Subscription plan: `free`, `basic`, `pro`, `business` |
| `tier` | string | Resolved tier for plan caps |
| `ownerUid` | string | Firebase UID of the tenant owner |
| `ownerEmail` | string | Owner's email |
| `domain` | string | Connected Google Workspace domain |
| `adminEmail` | string | Super admin email used for API impersonation |
| `serviceAccountKey` | map | Service account JSON key (written only by Cloud Functions) |
| `domainConnectedAt` | timestamp | When the domain was connected |
| `suspended` | boolean | Whether the tenant is suspended |
| `billingProvider` | string | `paypal` |
| `paypalSubscriptionId` | string | PayPal subscription ID |

### `tenants/{tenantId}/audit_log/{logId}`

| Field | Type | Description |
|---|---|---|
| `action` | string | e.g. `delegation.add`, `filter.create`, `domain.connect` |
| `actor` | string | Email or UID of the person who performed the action |
| `details` | map | Action-specific data (userEmail, delegateEmail, etc.) |
| `timestamp` | timestamp | Server timestamp |

### `tenant_users/{tenantId}__{userId}`

| Field | Type | Description |
|---|---|---|
| `tenantId` | string | Tenant ID |
| `userId` | string | Firebase UID |
| `email` | string | User email |
| `role` | string | `owner`, `admin`, or `member` |
| `displayName` | string | User display name |

### `tenant_invites/{inviteId}`

Standard invite documents for team collaboration.

## Project Structure

```
index.js                          Cloud Functions (all endpoints)
firestore.rules                   Firestore security rules
firebase.json                     Hosting rewrites + emulator config
src/
├── lib/
│   ├── firebase.js               Firebase client init + emulator connection
│   ├── paddle.js                 PayPal/Paddle billing integration
│   ├── planCaps.js               Plan limits and feature gates
│   ├── stores/
│   │   └── dashboardStore.js     Svelte store for tenant/session state
│   ├── services/
│   │   ├── gwsApi.js             Frontend API client (calls Cloud Functions)
│   │   ├── gmailService.js       Gmail API helpers (server-side)
│   │   ├── adminService.js       Admin Directory API helpers (server-side)
│   │   └── googleAuth.js         JWT impersonation client builder
│   └── components/
│       ├── Login.svelte           Login/signup component
│       └── SubscriptionGuard.svelte  Plan enforcement wrapper
├── routes/
│   ├── +page.svelte              Landing page
│   ├── dashboard/
│   │   ├── +layout.svelte        Dashboard layout with sidebar nav
│   │   ├── +page.svelte          Dashboard index (redirects to /delegation)
│   │   ├── delegation/+page.svelte  Gmail delegation management
│   │   ├── settings/+page.svelte    Domain connection + audit log
│   │   ├── users/+page.svelte       Team user management
│   │   └── upgrade/+page.svelte     Subscription upgrade flow
│   ├── admin/+page.svelte        Super-admin tenant overview
│   ├── privacy-policy/           Legal pages
│   ├── terms-of-service/
│   ├── refund-policy/
│   └── sitemap.xml/+server.ts
```

## Setup

### 1. Firebase Project

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com/).
2. Enable **Authentication** (Google provider) and **Firestore**.
3. Set the project ID in `.firebaserc`.

### 2. Environment Variables

Create a `.env` file at the project root:

```env
VITE_FIREBASE_API_KEY=your-api-key
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
VITE_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=000000000000
VITE_FIREBASE_APP_ID=1:000000000000:web:0000000000000000
VITE_USE_EMULATORS=true
```

### 3. Domain-Wide Delegation

1. Create a Google Cloud **service account** with domain-wide delegation enabled.
2. In **Google Admin → Security → API Controls → Domain-wide Delegation**, authorize the service account client ID with these scopes:
   - `https://www.googleapis.com/auth/gmail.settings.basic`
   - `https://www.googleapis.com/auth/gmail.settings.sharing`
   - `https://www.googleapis.com/auth/admin.directory.user.readonly`
3. Download the JSON key and upload it in **Dashboard → Settings**.

### 4. Local Development

```bash
npm install
firebase emulators:start          # Auth :9099, Functions :5001, Firestore :8081, UI :4000
npm run dev                       # SvelteKit dev server :5173
```

### 5. Deploy

```bash
npm run build && firebase deploy --only hosting
firebase deploy --only functions
firebase deploy --only firestore:rules
```

## Webhook Flow (Tenant Readiness)

A single consolidated webhook is emitted when a tenant selects a plan (free or paid) via the `onTenantPlanSet` Firestore update trigger. This guarantees the payload contains `plan` and `owner`.

- **Trigger:** `onDocumentUpdated('tenants/{tenantId}')` — fires when `plan`/`tier` transitions from empty → non-empty.
- **Idempotency:** Sets `automation.webhookSent.tenantCreated` after sending.
- **Secrets:** `WEBHOOK_SIGNUP_URL`, `WEBHOOK_SIGNUP_JWT_SECRET` (Secret Manager in prod, `.env` in emulator).
