-- Run in Supabase SQL Editor for the existing table.
-- Each signed-in user may insert and read only their own calculations.
alter table public.body_mass_index_calculations enable row level security;

grant select, insert on public.body_mass_index_calculations to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'body_mass_index_calculations'
      and policyname = 'Users can read own BMI calculations'
  ) then
    create policy "Users can read own BMI calculations"
      on public.body_mass_index_calculations
      for select to authenticated
      using ((select auth.uid()) = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'body_mass_index_calculations'
      and policyname = 'Users can insert own BMI calculations'
  ) then
    create policy "Users can insert own BMI calculations"
      on public.body_mass_index_calculations
      for insert to authenticated
      with check ((select auth.uid()) = user_id);
  end if;
end $$;

create index if not exists body_mass_index_calculations_user_created_idx
  on public.body_mass_index_calculations (user_id, created_at desc);
