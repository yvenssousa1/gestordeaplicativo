-- Global CRM platform administrator.
-- The private allowlist is provisioned only through trusted SQL/admin operations.
create table if not exists private.platform_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  created_at timestamptz not null default now()
);
revoke all on private.platform_admins from public, anon, authenticated;
grant select on private.platform_admins to authenticated;

create or replace function private.is_platform_admin()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $function$
  select exists (
    select 1
    from private.platform_admins as a
    where a.user_id = (select auth.uid())
  );
$function$;
revoke all on function private.is_platform_admin() from public, anon;
grant execute on function private.is_platform_admin() to authenticated;

create or replace function private.has_business_access(target_business_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $function$
  select private.is_platform_admin()
    or exists (
      select 1
      from public.business_memberships as m
      where m.business_id = target_business_id
        and m.user_id = (select auth.uid())
    );
$function$;
revoke all on function private.has_business_access(uuid) from public, anon;
grant execute on function private.has_business_access(uuid) to authenticated;

-- The platform administrator can manage all memberships, while ordinary
-- members remain restricted to seeing their own membership rows.
drop policy if exists platform_admin_manage_memberships on public.business_memberships;
create policy platform_admin_manage_memberships on public.business_memberships
  for all to authenticated
  using (private.is_platform_admin())
  with check (private.is_platform_admin());

-- The platform administrator can manage all business-unit records.
drop policy if exists platform_admin_manage_business_units on public.business_units;
create policy platform_admin_manage_business_units on public.business_units
  for all to authenticated
  using (private.is_platform_admin())
  with check (private.is_platform_admin());
