-- Criar bucket para fotos de perfil no Supabase Storage
-- Execute este SQL no painel do Supabase > SQL Editor

-- 1. Criar o bucket profile-photos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-photos',
    'profile-photos',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
);

-- 2. Criar política RLS para permitir upload de fotos
CREATE POLICY "Users can upload their own profile photos" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'profile-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- 3. Criar política RLS para permitir visualização de fotos
CREATE POLICY "Profile photos are publicly viewable" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-photos');

-- 4. Criar política RLS para permitir atualização de fotos
CREATE POLICY "Users can update their own profile photos" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'profile-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- 5. Criar política RLS para permitir exclusão de fotos
CREATE POLICY "Users can delete their own profile photos" ON storage.objects
FOR DELETE USING (
    bucket_id = 'profile-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- 6. Verificar se o bucket foi criado
SELECT * FROM storage.buckets WHERE id = 'profile-photos'; 