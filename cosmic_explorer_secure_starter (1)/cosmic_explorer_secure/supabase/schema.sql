-- Cosmic Explorer: secure starter schema for Supabase.
-- Run this in Supabase SQL Editor. No secret keys belong in the website.

create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;
revoke all on public.admin_users from anon, authenticated;

-- SECURITY DEFINER lets the function check the private admin allow-list.
-- A signed-in user cannot promote themselves because admin_users has no client grants.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users au where au.user_id = auth.uid()
  );
$$;
revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

create table if not exists public.site_content (
  id uuid primary key default gen_random_uuid(),
  content_key text not null unique,
  title text not null,
  body jsonb not null default '{}'::jsonb,
  published boolean not null default false,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);
alter table public.site_content enable row level security;
revoke all on public.site_content from anon, authenticated;
grant select on public.site_content to anon, authenticated;
grant insert, update, delete on public.site_content to authenticated;
create policy "public reads published content" on public.site_content
  for select to anon, authenticated using (published = true or (select public.is_admin()));
create policy "admins insert content" on public.site_content
  for insert to authenticated with check ((select public.is_admin()));
create policy "admins update content" on public.site_content
  for update to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admins delete content" on public.site_content
  for delete to authenticated using ((select public.is_admin()));

create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  quiz_key text not null unique,
  title text not null,
  questions jsonb not null default '[]'::jsonb,
  published boolean not null default false,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);
alter table public.quizzes enable row level security;
revoke all on public.quizzes from anon, authenticated;
grant select on public.quizzes to anon, authenticated;
grant insert, update, delete on public.quizzes to authenticated;
create policy "public reads published quizzes" on public.quizzes
  for select to anon, authenticated using (published = true or (select public.is_admin()));
create policy "admins insert quizzes" on public.quizzes
  for insert to authenticated with check ((select public.is_admin()));
create policy "admins update quizzes" on public.quizzes
  for update to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admins delete quizzes" on public.quizzes
  for delete to authenticated using ((select public.is_admin()));

create table if not exists public.site_settings (
  id uuid primary key default gen_random_uuid(),
  setting_key text not null unique,
  value jsonb not null default '{}'::jsonb,
  public_read boolean not null default false,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);
alter table public.site_settings enable row level security;
revoke all on public.site_settings from anon, authenticated;
grant select on public.site_settings to anon, authenticated;
grant insert, update, delete on public.site_settings to authenticated;
create policy "public reads public settings" on public.site_settings
  for select to anon, authenticated using (public_read = true or (select public.is_admin()));
create policy "admins insert settings" on public.site_settings
  for insert to authenticated with check ((select public.is_admin()));
create policy "admins update settings" on public.site_settings
  for update to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admins delete settings" on public.site_settings
  for delete to authenticated using ((select public.is_admin()));

-- The admin allow-list is intentionally not seeded here.
-- Create your Supabase Auth user first, then add ONLY your own UUID via SQL Editor:
-- insert into public.admin_users (user_id) values ('YOUR_AUTH_USER_UUID');
