-- ============================================================
-- GROBizzz Platform – Complete Database Schema
-- Compatible with Supabase (PostgreSQL 15+)
-- ============================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ------------------------------------------------------------
-- 1. PROFILES (extends Supabase Auth users)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT,
  full_name     TEXT,
  phone         TEXT,
  role          TEXT NOT NULL DEFAULT 'business_owner'
                CHECK (role IN ('admin', 'editor', 'business_owner')),
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 2. CATEGORIES (system-level, expandable)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.categories (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug          TEXT UNIQUE NOT NULL,
  name          TEXT NOT NULL,
  description   TEXT,
  icon          TEXT,
  sections      JSONB DEFAULT '["about","gallery","hours","contact","social"]'::jsonb,
  is_active     BOOLEAN DEFAULT TRUE,
  display_order INTEGER DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 3. TEMPLATES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.templates (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug          TEXT UNIQUE NOT NULL,
  name          TEXT NOT NULL,
  description   TEXT,
  preview_image TEXT,
  folder        TEXT NOT NULL,          -- modern | restaurant | service
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 4. BUSINESSES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.businesses (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id            UUID REFERENCES public.profiles(id) ON DELETE SET NULL,

  -- Identity
  business_name       TEXT NOT NULL,
  slug                TEXT UNIQUE NOT NULL,
  category            TEXT NOT NULL,
  subcategory         TEXT,
  tagline             TEXT,
  description         TEXT,
  about               TEXT,
  year_established    SMALLINT,

  -- Media
  logo_url            TEXT,
  cover_image_url     TEXT,
  favicon_url         TEXT,

  -- Contact
  phone               TEXT,
  alternate_phone     TEXT,
  whatsapp            TEXT,
  email               TEXT,
  website             TEXT,

  -- Location
  address             TEXT,
  area                TEXT,
  city                TEXT,
  state               TEXT,
  pincode             TEXT,
  latitude            DECIMAL(10,7),
  longitude           DECIMAL(10,7),
  google_maps_url     TEXT,
  google_business_url TEXT,

  -- Social & external
  instagram_url       TEXT,
  facebook_url        TEXT,
  youtube_url         TEXT,
  linkedin_url        TEXT,
  twitter_url         TEXT,
  zomato_url          TEXT,
  swiggy_url          TEXT,
  other_links         JSONB DEFAULT '[]'::jsonb,

  -- Branding
  primary_color       TEXT DEFAULT '#c97b3a',
  secondary_color     TEXT DEFAULT '#1a1a1a',
  accent_color        TEXT DEFAULT '#f5f0e8',
  template_id         UUID REFERENCES public.templates(id),

  -- Features (toggles)
  features            JSONB DEFAULT '{
    "whatsapp": true,
    "call": true,
    "maps": true,
    "share": true,
    "gallery": true,
    "services": true,
    "menu": true,
    "reviews": true,
    "social": true,
    "contact_form": false,
    "verified": false
  }'::jsonb,

  -- SEO
  seo_title           TEXT,
  seo_description     TEXT,
  seo_keywords        TEXT,
  og_image_url        TEXT,

  -- Status
  verified            BOOLEAN DEFAULT FALSE,
  status              TEXT NOT NULL DEFAULT 'draft'
                      CHECK (status IN ('draft', 'published', 'unpublished')),
  published_at        TIMESTAMPTZ,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 5. SERVICES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.services (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id   UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  description   TEXT,
  price         DECIMAL(12,2),
  price_label   TEXT,                    -- e.g. "Starting from", "per session"
  image_url     TEXT,
  category      TEXT,                    -- free-text grouping
  display_order INTEGER DEFAULT 0,
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 6. PRODUCTS / MENU
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.products (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id   UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  description   TEXT,
  price         DECIMAL(12,2),
  image_url     TEXT,
  category      TEXT,
  display_order INTEGER DEFAULT 0,
  is_available  BOOLEAN DEFAULT TRUE,
  is_featured   BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 7. GALLERY
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.gallery (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id   UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  image_url     TEXT NOT NULL,
  caption       TEXT,
  album         TEXT DEFAULT 'general',
  display_order INTEGER DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 8. BUSINESS HOURS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.business_hours (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id   UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  day_of_week   SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sun … 6=Sat
  is_closed     BOOLEAN DEFAULT FALSE,
  open_time     TIME,
  close_time    TIME,
  UNIQUE (business_id, day_of_week)
);

-- ------------------------------------------------------------
-- INDEXES
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_businesses_owner ON public.businesses(owner_id);
CREATE INDEX IF NOT EXISTS idx_businesses_slug ON public.businesses(slug);
CREATE INDEX IF NOT EXISTS idx_businesses_status ON public.businesses(status);
CREATE INDEX IF NOT EXISTS idx_businesses_category ON public.businesses(category);
CREATE INDEX IF NOT EXISTS idx_businesses_city ON public.businesses(city);
CREATE INDEX IF NOT EXISTS idx_services_business ON public.services(business_id);
CREATE INDEX IF NOT EXISTS idx_products_business ON public.products(business_id);
CREATE INDEX IF NOT EXISTS idx_gallery_business ON public.gallery(business_id);
CREATE INDEX IF NOT EXISTS idx_hours_business ON public.business_hours(business_id);

-- ------------------------------------------------------------
-- UPDATED_AT TRIGGER
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_businesses_updated ON public.businesses;
CREATE TRIGGER trg_businesses_updated
  BEFORE UPDATE ON public.businesses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_services_updated ON public.services;
CREATE TRIGGER trg_services_updated
  BEFORE UPDATE ON public.services
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_products_updated ON public.products;
CREATE TRIGGER trg_products_updated
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_profiles_updated ON public.profiles;
CREATE TRIGGER trg_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ------------------------------------------------------------
-- AUTO-CREATE PROFILE ON SIGNUP
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'business_owner')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gallery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.templates ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Categories & Templates – public read
CREATE POLICY "Categories public read"
  ON public.categories FOR SELECT USING (true);
CREATE POLICY "Templates public read"
  ON public.templates FOR SELECT USING (true);

-- Businesses
CREATE POLICY "Published businesses are public"
  ON public.businesses FOR SELECT
  USING (status = 'published' OR owner_id = auth.uid() OR
         EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')));

CREATE POLICY "Owners can insert businesses"
  ON public.businesses FOR INSERT
  WITH CHECK (owner_id = auth.uid() OR
              EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')));

CREATE POLICY "Owners can update own businesses"
  ON public.businesses FOR UPDATE
  USING (owner_id = auth.uid() OR
         EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')));

CREATE POLICY "Owners can delete own businesses"
  ON public.businesses FOR DELETE
  USING (owner_id = auth.uid() OR
         EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));

-- Services / Products / Gallery / Hours – same ownership pattern
CREATE POLICY "Services select"
  ON public.services FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = business_id AND (b.status = 'published' OR b.owner_id = auth.uid() OR
      EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))
  ));

CREATE POLICY "Services insert"
  ON public.services FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = business_id AND (b.owner_id = auth.uid() OR
      EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))
  ));

CREATE POLICY "Services update"
  ON public.services FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = business_id AND (b.owner_id = auth.uid() OR
      EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))
  ));

CREATE POLICY "Services delete"
  ON public.services FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = business_id AND (b.owner_id = auth.uid() OR
      EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))
  ));

-- Products policies (mirror services)
CREATE POLICY "Products select" ON public.products FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND (b.status = 'published' OR b.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))));
CREATE POLICY "Products insert" ON public.products FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND (b.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))));
CREATE POLICY "Products update" ON public.products FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND (b.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))));
CREATE POLICY "Products delete" ON public.products FOR DELETE
  USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND (b.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))));

-- Gallery policies
CREATE POLICY "Gallery select" ON public.gallery FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND (b.status = 'published' OR b.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))));
CREATE POLICY "Gallery insert" ON public.gallery FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND (b.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))));
CREATE POLICY "Gallery update" ON public.gallery FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND (b.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))));
CREATE POLICY "Gallery delete" ON public.gallery FOR DELETE
  USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND (b.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))));

-- Hours policies
CREATE POLICY "Hours select" ON public.business_hours FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND (b.status = 'published' OR b.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))));
CREATE POLICY "Hours insert" ON public.business_hours FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND (b.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))));
CREATE POLICY "Hours update" ON public.business_hours FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND (b.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))));
CREATE POLICY "Hours delete" ON public.business_hours FOR DELETE
  USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND (b.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','editor')))));

-- ------------------------------------------------------------
-- SEED CATEGORIES & TEMPLATES
-- ------------------------------------------------------------
INSERT INTO public.categories (slug, name, sections, display_order) VALUES
  ('cafe', 'Cafe', '["about","menu","gallery","hours","location","whatsapp","call","zomato","swiggy","instagram","reviews"]', 1),
  ('restaurant', 'Restaurant', '["about","menu","gallery","hours","location","whatsapp","call","zomato","swiggy","instagram","reviews"]', 2),
  ('hotel', 'Hotel', '["about","services","gallery","hours","location","whatsapp","call","instagram"]', 3),
  ('salon', 'Salon', '["about","services","pricing","gallery","appointment","whatsapp","call","location","instagram","reviews"]', 4),
  ('beauty', 'Beauty', '["about","services","pricing","gallery","whatsapp","call","location","instagram"]', 5),
  ('gym', 'Gym', '["about","membership","services","trainers","gallery","hours","whatsapp","call","location","instagram"]', 6),
  ('fitness', 'Fitness', '["about","services","gallery","hours","whatsapp","call","location","instagram"]', 7),
  ('clothing', 'Clothing', '["about","products","gallery","location","whatsapp","call","instagram"]', 8),
  ('fashion', 'Fashion', '["about","products","gallery","location","whatsapp","call","instagram"]', 9),
  ('jewellery', 'Jewellery', '["about","products","gallery","location","whatsapp","call","instagram"]', 10),
  ('retail', 'Retail Shop', '["about","products","gallery","location","whatsapp","call","instagram"]', 11),
  ('shopping-mall', 'Shopping Mall', '["about","products","gallery","location","whatsapp","call"]', 12),
  ('real-estate', 'Real Estate', '["about","services","projects","gallery","contact","whatsapp","location"]', 13),
  ('construction', 'Construction', '["about","services","projects","gallery","contact","whatsapp","location","enquiry"]', 14),
  ('education', 'Education', '["about","courses","facilities","gallery","admissions","contact","location","whatsapp"]', 15),
  ('college', 'College', '["about","courses","facilities","gallery","admissions","contact","location"]', 16),
  ('school', 'School', '["about","courses","facilities","gallery","admissions","contact","location"]', 17),
  ('training', 'Training Institute', '["about","courses","gallery","contact","location","whatsapp"]', 18),
  ('hospital', 'Hospital', '["about","services","gallery","hours","location","whatsapp","call"]', 19),
  ('clinic', 'Clinic', '["about","services","gallery","hours","location","whatsapp","call"]', 20),
  ('doctor', 'Doctor', '["about","services","gallery","hours","location","whatsapp","call"]', 21),
  ('lawyer', 'Lawyer', '["about","services","gallery","contact","location","whatsapp","call"]', 22),
  ('ca', 'CA', '["about","services","gallery","contact","location","whatsapp","call"]', 23),
  ('it-company', 'IT Company', '["about","services","projects","gallery","contact","location","whatsapp"]', 24),
  ('software', 'Software Company', '["about","services","projects","gallery","contact","location","whatsapp"]', 25),
  ('service', 'Service Provider', '["about","services","gallery","contact","location","whatsapp","call"]', 26),
  ('freelancer', 'Freelancer', '["about","services","gallery","contact","location","whatsapp"]', 27),
  ('photographer', 'Photographer', '["about","services","gallery","contact","location","whatsapp","instagram"]', 28),
  ('event', 'Event Management', '["about","services","gallery","contact","location","whatsapp","instagram"]', 29),
  ('travel', 'Travel', '["about","services","gallery","contact","location","whatsapp"]', 30),
  ('automobile', 'Automobile', '["about","services","gallery","location","whatsapp","call"]', 31),
  ('repair', 'Repair Service', '["about","services","gallery","location","whatsapp","call"]', 32),
  ('other', 'Other', '["about","services","gallery","contact","location","whatsapp","call"]', 99)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.templates (slug, name, description, folder) VALUES
  ('modern', 'Modern Business', 'Clean, premium digital business card layout', 'modern'),
  ('restaurant', 'Restaurant / Cafe', 'Menu-focused layout ideal for F&B businesses', 'restaurant'),
  ('service', 'Service Business', 'Service-list oriented layout for salons, gyms, professionals', 'service')
ON CONFLICT (slug) DO NOTHING;
