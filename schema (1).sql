-- À coller dans Supabase > SQL Editor > Run. Le PREMIER compte créé devient admin.
create table profiles(id uuid primary key references auth.users on delete cascade, name text, role text not null default 'Aucun', is_admin boolean not null default false);
create table models(id uuid primary key default gen_random_uuid(), nom text not null, pseudo text, ck jsonb not null default '[0,0,0,0,0]');
create table model_terms(model_id uuid primary key references models on delete cascade, pct numeric not null default 50);
create table staff_terms(user_id uuid primary key references profiles on delete cascade, pct numeric not null default 0);
create table assignments(id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles on delete cascade, model_id uuid not null references models on delete cascade, shift text not null, unique(user_id,model_id,shift));
create table sales(id uuid primary key default gen_random_uuid(), d date not null default current_date, model_id uuid not null references models, user_id uuid not null references profiles, amt numeric not null check(amt>0), type text not null);
create table settings(key text primary key, value numeric not null);
insert into settings values('plat',20);

create function is_admin() returns boolean language sql security definer stable set search_path=public as $$ select coalesce((select is_admin from profiles where id=auth.uid()),false) $$;
create function is_mgr() returns boolean language sql security definer stable set search_path=public as $$ select coalesce((select role='Manager' from profiles where id=auth.uid()),false) $$;
create function is_assigned(m uuid) returns boolean language sql security definer stable set search_path=public as $$ select exists(select 1 from assignments where user_id=auth.uid() and model_id=m) $$;

create function new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into profiles(id,name,is_admin) values(new.id, coalesce(new.raw_user_meta_data->>'name',new.email), not exists(select 1 from profiles)); return new; end $$;
create trigger on_signup after insert on auth.users for each row execute function new_user();

alter table profiles enable row level security; alter table models enable row level security; alter table model_terms enable row level security;
alter table staff_terms enable row level security; alter table assignments enable row level security; alter table sales enable row level security; alter table settings enable row level security;

-- Admin : tout. Les autres : uniquement ce qui leur est attribué.
create policy a_all on profiles for all using(is_admin()) with check(is_admin());
create policy a_all on models for all using(is_admin()) with check(is_admin());
create policy a_all on model_terms for all using(is_admin()) with check(is_admin());
create policy a_all on staff_terms for all using(is_admin()) with check(is_admin());
create policy a_all on assignments for all using(is_admin()) with check(is_admin());
create policy a_all on sales for all using(is_admin()) with check(is_admin());
create policy a_all on settings for all using(is_admin()) with check(is_admin());

create policy r_profiles on profiles for select using(id=auth.uid() or is_mgr());
create policy r_models on models for select using(is_mgr() or is_assigned(id));
create policy r_asg on assignments for select using(user_id=auth.uid() or is_mgr());
create policy r_sales on sales for select using(user_id=auth.uid() or is_mgr());
-- Un chatteur ne peut ajouter une vente que pour lui-même et une modèle qui lui est attribuée. Jamais modifier ni supprimer.
create policy w_sales on sales for insert with check(user_id=auth.uid() and is_assigned(model_id));

-- ===== Retraits (mobile money Bénin : MTN MoMo, Moov Money, Celtiis Cash, ou virement) =====
create table payouts(id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles on delete cascade, amt numeric not null check(amt>0), method text not null, phone text not null, status text not null default 'En attente', ref text, created_at timestamptz not null default now());
alter table payouts enable row level security;
-- Solde = commissions gagnées (après frais plateforme) moins les retraits non refusés. Calculé côté serveur.
create function my_balance() returns numeric language sql security definer stable set search_path=public as $$
 select coalesce((select sum(amt) from sales where user_id=auth.uid()),0)
  * (1-coalesce((select value from settings where key='plat'),20)/100)
  * coalesce((select pct from staff_terms where user_id=auth.uid()),0)/100
  - coalesce((select sum(amt) from payouts where user_id=auth.uid() and status<>'Refusé'),0) $$;
create policy a_all on payouts for all using(is_admin()) with check(is_admin());
create policy r_pay on payouts for select using(user_id=auth.uid());
create policy w_pay on payouts for insert with check(user_id=auth.uid() and status='En attente' and amt<=my_balance());
