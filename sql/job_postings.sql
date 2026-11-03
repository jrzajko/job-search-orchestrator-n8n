-- Job postings store for the n8n job-search orchestrator.
-- Run once in the Supabase SQL editor.

create table if not exists job_postings (
  id            uuid primary key default gen_random_uuid(),
  source        text not null,            -- e.g. 'adzuna'; one value per aggregator
  external_id   text not null,            -- the aggregator's own posting id
  title         text,
  company       text,
  location      text,
  url           text,
  salary_min    numeric,
  salary_max    numeric,
  posted_date   timestamptz,
  description   text,
  first_seen_at timestamptz default now(),
  emailed       boolean default false,    -- set true once a posting has been scored
  unique (source, external_id)            -- dedupe lives in the database, not in n8n
);

-- Fast lookup for the daily "what hasn't been processed yet" query
create index if not exists job_postings_unprocessed_idx
  on job_postings (emailed) where emailed = false;
