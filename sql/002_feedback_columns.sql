-- v2: feedback buttons. Run once in the Supabase SQL editor.
alter table job_postings
  add column if not exists fit_score     int,
  add column if not exists fit_reasoning text,
  add column if not exists status        text check (status in ('applied', 'not_interested')),
  add column if not exists status_at     timestamptz;
