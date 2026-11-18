-- Holding table for company job board slugs found in Common Crawl, before they are checked.
-- Import the CSV from duckdb/common_crawl_boards.sql into this table (Supabase: Table Editor → Import data from CSV).
create table if not exists board_candidates (
  source          text not null,                     -- greenhouse, ashby, workable
  slug            text not null,                     -- the company's board name, e.g. "acme"
  pages           int,                               -- archived job pages in the crawl (rough size signal)
  status          text not null default 'unchecked', -- unchecked, uk, no_uk, no_jobs, not_found, error
  open_jobs       int,
  uk_jobs         int,
  company_name    text,
  last_checked_at timestamptz,
  primary key (source, slug)
);
