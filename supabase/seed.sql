-- ============================================================
-- GROBizzz Seed Data – Demo Businesses
-- Run after 001_initial_schema.sql
-- ============================================================

-- Note: owner_id will be null for seed data (or set after creating an admin user).
-- In production, assign a real profile id.

-- Helper: get template ids
DO $$
DECLARE
  tpl_restaurant UUID;
  tpl_modern UUID;
  tpl_service UUID;
  b1 UUID;
  b2 UUID;
  b3 UUID;
  b4 UUID;
  b5 UUID;
BEGIN
  SELECT id INTO tpl_restaurant FROM public.templates WHERE slug = 'restaurant' LIMIT 1;
  SELECT id INTO tpl_modern FROM public.templates WHERE slug = 'modern' LIMIT 1;
  SELECT id INTO tpl_service FROM public.templates WHERE slug = 'service' LIMIT 1;

  -- 1. Hydeout Cafe
  INSERT INTO public.businesses (
    business_name, slug, category, subcategory, tagline, description, about,
    phone, whatsapp, email, address, area, city, state, pincode,
    google_maps_url, instagram_url, zomato_url, swiggy_url,
    primary_color, secondary_color, accent_color, template_id,
    features, verified, status, published_at,
    seo_title, seo_description
  ) VALUES (
    'Hydeout Cafe',
    'hydeout-cafe',
    'cafe',
    'Café · Lounge · Family Restaurant',
    'A warm corner on Jalna Road for long breakfasts & late-night coffee',
    'Hydeout Cafe serves all-day breakfast, wood-fired pizzas, and specialty coffee in a cozy lounge setting.',
    'Born in 2019 on Jalna Road, Hydeout is where Chhatrapati Sambhajinagar comes for unhurried breakfasts, honest food and conversations that stretch into the night. We believe good food tastes better when shared.',
    '+919890777333',
    '+919890777333',
    'hello@hydeoutcafe.in',
    'Chetan Trade Center, Opp. SFS School, Jalna Road',
    'Jalna Road',
    'Chhatrapati Sambhajinagar',
    'Maharashtra',
    '431001',
    'https://maps.google.com/?q=Hydeout+Cafe+Chhatrapati+Sambhajinagar',
    'https://instagram.com/hydeoutcafe',
    'https://zomato.com/hydeout-cafe',
    'https://swiggy.com/hydeout-cafe',
    '#c97b3a',
    '#1a1a1a',
    '#f5f0e8',
    tpl_restaurant,
    '{"whatsapp":true,"call":true,"maps":true,"share":true,"gallery":true,"services":false,"menu":true,"reviews":true,"social":true,"contact_form":false,"verified":true}'::jsonb,
    TRUE,
    'published',
    NOW(),
    'Hydeout Cafe | Café & Lounge | Grobizzz',
    'All-day breakfast, wood-fired pizzas and specialty coffee in Chhatrapati Sambhajinagar.'
  ) RETURNING id INTO b1;

  -- Hours for Hydeout (Mon-Sun 09:00-23:00)
  INSERT INTO public.business_hours (business_id, day_of_week, is_closed, open_time, close_time)
  SELECT b1, d, FALSE, '09:00', '23:00' FROM generate_series(0,6) AS d;

  -- Menu items
  INSERT INTO public.products (business_id, name, description, price, category, display_order, is_featured) VALUES
    (b1, 'Classic English Breakfast', 'Eggs, bacon, sausage, toast, beans & grilled tomato', 320, 'Breakfast', 1, TRUE),
    (b1, 'Avocado Toast', 'Sourdough, smashed avocado, chilli flakes, poached egg', 280, 'Breakfast', 2, FALSE),
    (b1, 'Margherita Pizza', 'San Marzano tomato, mozzarella, fresh basil', 450, 'Pizza', 3, TRUE),
    (b1, 'Hydeout Special Burger', 'Double patty, cheddar, caramelised onion, house sauce', 380, 'Mains', 4, TRUE),
    (b1, 'Cold Brew', '12-hour cold extraction', 180, 'Beverages', 5, FALSE),
    (b1, 'Tiramisu', 'Classic Italian dessert', 220, 'Desserts', 6, FALSE);

  -- Gallery placeholders (replace with real URLs after upload)
  INSERT INTO public.gallery (business_id, image_url, caption, display_order) VALUES
    (b1, 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800', 'Interior seating', 1),
    (b1, 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800', 'Evening ambience', 2),
    (b1, 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800', 'Signature dishes', 3);

  -- 2. Blackstone Cafe
  INSERT INTO public.businesses (
    business_name, slug, category, subcategory, tagline, description, about,
    phone, whatsapp, address, city, state, pincode,
    primary_color, secondary_color, accent_color, template_id,
    features, verified, status, published_at
  ) VALUES (
    'Blackstone Cafe',
    'blackstone-cafe',
    'cafe',
    'Coffee · Bakery',
    'Specialty coffee & artisanal bakes',
    'Blackstone is a specialty coffee destination with fresh bakery items baked daily.',
    'We source single-origin beans and bake everything in-house. Come for the coffee, stay for the pastries.',
    '+919876543210',
    '+919876543210',
    'Near City Center Mall',
    'Pune',
    'Maharashtra',
    '411001',
    '#2c1810',
    '#f8f1e9',
    '#d4a574',
    tpl_restaurant,
    '{"whatsapp":true,"call":true,"maps":true,"share":true,"gallery":true,"menu":true,"reviews":true,"social":true,"verified":false}'::jsonb,
    FALSE,
    'published',
    NOW()
  ) RETURNING id INTO b2;

  INSERT INTO public.business_hours (business_id, day_of_week, is_closed, open_time, close_time)
  SELECT b2, d, FALSE, '08:00', '22:00' FROM generate_series(0,6) AS d;

  INSERT INTO public.products (business_id, name, price, category, display_order) VALUES
    (b2, 'Flat White', 180, 'Coffee', 1),
    (b2, 'Croissant', 120, 'Bakery', 2),
    (b2, 'Chocolate Brownie', 150, 'Desserts', 3);

  -- 3. Sample Salon
  INSERT INTO public.businesses (
    business_name, slug, category, tagline, description, about,
    phone, whatsapp, address, city, state,
    primary_color, secondary_color, accent_color, template_id,
    features, verified, status, published_at
  ) VALUES (
    'Glow & Grace Salon',
    'glow-grace-salon',
    'salon',
    'Hair · Skin · Nails',
    'Premium unisex salon offering hair, skin and nail services.',
    'Our expert stylists use only premium products. Book your appointment today.',
    '+919123456789',
    '+919123456789',
    'Shop 12, Fashion Street',
    'Mumbai',
    'Maharashtra',
    '#9b59b6',
    '#2c3e50',
    '#f5eef8',
    tpl_service,
    '{"whatsapp":true,"call":true,"maps":true,"share":true,"gallery":true,"services":true,"reviews":true,"social":true,"verified":true}'::jsonb,
    TRUE,
    'published',
    NOW()
  ) RETURNING id INTO b3;

  INSERT INTO public.services (business_id, name, price, price_label, category, display_order) VALUES
    (b3, 'Haircut (Men)', 300, NULL, 'Hair', 1),
    (b3, 'Haircut (Women)', 500, NULL, 'Hair', 2),
    (b3, 'Hair Coloring', 1500, 'Starting from', 'Hair', 3),
    (b3, 'Facial', 800, NULL, 'Skin', 4),
    (b3, 'Manicure', 400, NULL, 'Nails', 5);

  -- 4. Sample Gym
  INSERT INTO public.businesses (
    business_name, slug, category, tagline, description, about,
    phone, whatsapp, address, city, state,
    primary_color, secondary_color, accent_color, template_id,
    features, status, published_at
  ) VALUES (
    'Iron Temple Fitness',
    'iron-temple-fitness',
    'gym',
    'Strength · Cardio · Community',
    'Fully equipped gym with personal training and group classes.',
    'Train hard, recover smarter. Join a community that pushes you further.',
    '+919988776655',
    '+919988776655',
    'Plot 45, Industrial Area',
    'Nagpur',
    'Maharashtra',
    '#e74c3c',
    '#1a1a1a',
    '#fadbd8',
    tpl_service,
    '{"whatsapp":true,"call":true,"maps":true,"share":true,"gallery":true,"services":true,"hours":true,"social":true}'::jsonb,
    'published',
    NOW()
  ) RETURNING id INTO b4;

  INSERT INTO public.services (business_id, name, price, price_label, category, display_order) VALUES
    (b4, 'Monthly Membership', 1999, NULL, 'Membership', 1),
    (b4, 'Quarterly Membership', 5499, NULL, 'Membership', 2),
    (b4, 'Personal Training (10 sessions)', 8000, NULL, 'Training', 3);

  -- 5. Sample IT Company
  INSERT INTO public.businesses (
    business_name, slug, category, tagline, description, about,
    phone, whatsapp, email, website, address, city, state,
    primary_color, secondary_color, accent_color, template_id,
    features, status, published_at
  ) VALUES (
    'KDRT IT Solutions',
    'kdrt-it-solutions',
    'it-company',
    'Building digital products that scale',
    'Full-stack development, cloud solutions and digital transformation for businesses.',
    'We help local and global brands build reliable, modern software. From MVPs to enterprise platforms.',
    '+919999888877',
    '+919999888877',
    'hello@kdrt.in',
    'https://kdrt.in',
    'Tech Park, Baner',
    'Pune',
    'Maharashtra',
    '#2563eb',
    '#0f172a',
    '#e0e7ff',
    tpl_modern,
    '{"whatsapp":true,"call":true,"maps":true,"share":true,"gallery":true,"services":true,"social":true,"contact_form":true}'::jsonb,
    'published',
    NOW()
  ) RETURNING id INTO b5;

  INSERT INTO public.services (business_id, name, description, category, display_order) VALUES
    (b5, 'Web Application Development', 'Custom React / Node / full-stack apps', 'Development', 1),
    (b5, 'Mobile Apps', 'iOS & Android with React Native / Flutter', 'Development', 2),
    (b5, 'Cloud & DevOps', 'AWS, GCP, CI/CD pipelines', 'Infrastructure', 3),
    (b5, 'UI/UX Design', 'Product design systems & prototypes', 'Design', 4);

END $$;
