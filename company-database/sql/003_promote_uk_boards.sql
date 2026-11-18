-- Promote checked boards with UK jobs into companies + company_job_sources.
-- Run once in the Supabase SQL editor to create the functions, then any time:
--   select * from promote_uk_boards();
-- Safe to re-run: existing companies and sources are updated, not duplicated.

-- Company name used for matching duplicates: lower case, no punctuation,
-- no trailing Ltd / Limited / plc / Inc etc. "Acme Ltd" and "acme" both become "acme".
create or replace function company_name_key(n text) returns text
language sql immutable as $$
  select regexp_replace(
           lower(regexp_replace(trim(n),
             '([,\s]+(ltd|limited|plc|inc|llc|gmbh|group|ag|sa|bv|holdings)\.?)+$', '', 'i')),
           '[^a-z0-9]', '', 'g')
$$;

-- Best available display name: the board's own name, otherwise the slug tidied up
-- ("base-power" -> "Base Power"). The tagging step corrects names later.
create or replace function board_display_name(company_name text, slug text) returns text
language sql immutable as $$
  select coalesce(nullif(trim(company_name), ''),
                  initcap(regexp_replace(slug, '[-_]+', ' ', 'g')))
$$;

create or replace function promote_uk_boards()
returns table (companies_added int, sources_added_or_updated int)
language plpgsql as $$
declare c_added int; s_count int;
begin
  -- 1. New companies (one per name key; if a company is on two systems, the board
  --    with more UK jobs supplies the name)
  insert into companies (name, name_key, discovered_via)
  select distinct on (k) nm, k, 'common_crawl'
  from (
    select board_display_name(company_name, slug) as nm,
           company_name_key(board_display_name(company_name, slug)) as k,
           uk_jobs
    from board_candidates
    where status = 'uk'
  ) s
  where k <> ''
  order by k, uk_jobs desc nulls last
  on conflict (name_key) do nothing;
  get diagnostics c_added = row_count;

  -- 2. Job sources, linked to their company
  insert into company_job_sources
    (company_id, source, slug, board_url, status, open_jobs, uk_jobs, last_uk_job_at, last_checked_at)
  select c.id, b.source, b.slug,
         case b.source
           when 'greenhouse' then 'https://job-boards.greenhouse.io/' || b.slug
           when 'ashby'      then 'https://jobs.ashbyhq.com/' || b.slug
           when 'workable'   then 'https://apply.workable.com/' || b.slug
         end,
         'active', b.open_jobs, b.uk_jobs, b.last_checked_at, b.last_checked_at
  from board_candidates b
  join companies c on c.name_key = company_name_key(board_display_name(b.company_name, b.slug))
  where b.status = 'uk'
  on conflict (source, slug) do update set
    open_jobs       = excluded.open_jobs,
    uk_jobs         = excluded.uk_jobs,
    last_uk_job_at  = excluded.last_uk_job_at,
    last_checked_at = excluded.last_checked_at,
    status          = 'active';
  get diagnostics s_count = row_count;

  return query select c_added, s_count;
end;
$$;

-- Companies waiting to be tagged, with one board to read their jobs from
-- (the board with the most UK jobs). Used by the n8n tagging workflow.
create or replace view companies_to_tag with (security_invoker = true) as
select distinct on (c.id)
       c.id, c.name, s.source, s.slug, s.uk_jobs
from companies c
join company_job_sources s on s.company_id = c.id
where c.tagged_at is null
  and s.source in ('greenhouse', 'ashby', 'workable')
order by c.id, s.uk_jobs desc nulls last;
