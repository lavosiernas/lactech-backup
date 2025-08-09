-- ===== CORREÇÃO DO STORAGE E RLS PARA FOTOS =====

-- 1. Criar bucket de fotos se não existir
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('profile-photos', 'profile-photos', true, 5242880, ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- 2. Remover políticas antigas se existirem
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "profile_photos_policy" ON storage.objects;
DROP POLICY IF EXISTS "profile_photos_insert_policy" ON storage.objects;
DROP POLICY IF EXISTS "profile_photos_select_policy" ON storage.objects;
DROP POLICY IF EXISTS "profile_photos_update_policy" ON storage.objects;
DROP POLICY IF EXISTS "profile_photos_delete_policy" ON storage.objects;

-- 3. Criar política permissiva para o bucket profile-photos
CREATE POLICY "profile_photos_all_policy" ON storage.objects
FOR ALL USING (bucket_id = 'profile-photos');

-- 4. Verificar se as políticas foram criadas
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%profile%';

-- 5. Verificar bucket
SELECT * FROM storage.buckets WHERE id = 'profile-photos';

-- 6. Testar acesso ao bucket
-- (Isso será testado pelo frontend)

-- ===== FIM DA CORREÇÃO ===== 