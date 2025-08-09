-- Verificar e criar bucket profile-photos se não existir
-- Execute este SQL no painel do Supabase > SQL Editor

-- 1. Verificar se o bucket existe
SELECT * FROM storage.buckets WHERE id = 'profile-photos';

-- 2. Se não existir, criar o bucket
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'profile-photos') THEN
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES (
            'profile-photos',
            'profile-photos',
            true,
            5242880, -- 5MB limit
            ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
        );
        RAISE NOTICE 'Bucket profile-photos criado com sucesso!';
    ELSE
        RAISE NOTICE 'Bucket profile-photos já existe!';
    END IF;
END $$;

-- 3. Verificar novamente se o bucket foi criado
SELECT * FROM storage.buckets WHERE id = 'profile-photos'; 