drop policy if exists memberships_self_read on public.business_memberships;
drop policy if exists platform_admin_manage_memberships on public.business_memberships;
create policy memberships_read on public.business_memberships
  for select to authenticated
  using (user_id = (select auth.uid()) or private.is_platform_admin());
create policy platform_admin_insert_memberships on public.business_memberships
  for insert to authenticated
  with check (private.is_platform_admin());
create policy platform_admin_update_memberships on public.business_memberships
  for update to authenticated
  using (private.is_platform_admin())
  with check (private.is_platform_admin());
create policy platform_admin_delete_memberships on public.business_memberships
  for delete to authenticated
  using (private.is_platform_admin());

drop policy if exists platform_admin_manage_business_units on public.business_units;
create policy platform_admin_insert_business_units on public.business_units
  for insert to authenticated
  with check (private.is_platform_admin());
create policy platform_admin_update_business_units on public.business_units
  for update to authenticated
  using (private.is_platform_admin())
  with check (private.is_platform_admin());
create policy platform_admin_delete_business_units on public.business_units
  for delete to authenticated
  using (private.is_platform_admin());