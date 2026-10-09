# GROBizzz – Single Portal + Backend

One form portal. Backend does everything else.

```
Fill form → POST /api/portal/create → Supabase → unique slug → published
                                              ↓
                                    /p/hydeout-cafe  (public profile)
```

## What you get

| Part | Purpose |
|------|---------|
| **Portal** (`/`) | Single multi-step form (your existing Grobizzz form) |
| **Backend** | Creates business, generates unique slug, publishes, stores in Supabase |
| **Public profile** (`/p/:slug`) | Dynamic page – no hardcoded HTML per business |

No full admin dashboard. Everything after the form is handled by the server.

## Setup

```bash
cd grobizzz-platform
cp .env.example .env
# Add SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
npm install
```

### Supabase

1. Run `supabase/migrations/001_initial_schema.sql`
2. Optional: run `supabase/seed.sql` (demo businesses)

### Run

```bash
npm start
```

- **Form portal:** http://localhost:5000/
- **Example profile:** http://localhost:5000/p/hydeout-cafe (after seed)

## Flow

1. Open `/`
2. Fill the 8-step form
3. Click **Generate My Website**
4. Backend generates unique slug, saves, publishes
5. Browser opens `/p/{slug}`

## API

```
POST /api/portal/create
→ creates + publishes, returns { slug, profile_url }

GET /api/public/business/:slug
→ full published profile data
```

## Env

```env
PORT=5000
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
```

## Structure

```
client/portal/     ← ONE form
client/public/     ← Dynamic profile
server/            ← All logic
supabase/          ← Schema + seed
```

Your original form is kept. Submit hits the backend; slug + publish are automatic.
