-- Solução definitiva para upload de fotos no Supabase Storage
-- Execute este SQL no painel do Supabase > SQL Editor

-- 1. Criar bucket profile-photos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-photos',
    'profile-photos',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Criar política simples para permitir tudo no bucket
CREATE POLICY "profile_photos_policy" ON storage.objects
FOR ALL USING (bucket_id = 'profile-photos')
WITH CHECK (bucket_id = 'profile-photos');

-- 3. Verificar se o bucket foi criado
SELECT id, name, public, file_size_limit FROM storage.buckets WHERE id = 'profile-photos'; 