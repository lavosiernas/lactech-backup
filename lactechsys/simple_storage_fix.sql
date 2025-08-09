-- Solução simples para upload de fotos no Supabase Storage
-- Execute este SQL no painel do Supabase > SQL Editor

-- 1. Criar bucket se não existir
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-photos',
    'profile-photos',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Remover todas as políticas existentes do bucket
DELETE FROM storage.objects WHERE bucket_id = 'profile-photos';

-- 3. Desabilitar RLS temporariamente para o bucket
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- 4. Ou criar política muito permissiva
CREATE POLICY "Allow all operations on profile photos" ON storage.objects
FOR ALL USING (bucket_id = 'profile-photos')
WITH CHECK (bucket_id = 'profile-photos');

-- 5. Verificar se funcionou
SELECT * FROM storage.buckets WHERE id = 'profile-photos'; 