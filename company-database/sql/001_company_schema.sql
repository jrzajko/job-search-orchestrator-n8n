-- Job search service: company database (v1)
-- Run once in the Supabase SQL editor (same project as the job postings tables).
-- Lists match "Job search service: shared lists for users and companies (draft v1)".

-- ---------------------------------------------------------------------------
-- 1. The shared lists. Every tag on a company must come from here.
-- ---------------------------------------------------------------------------
create table if not exists taxonomy_options (
  list_name   text not null,          -- sector, focus_area, company_type, size_band, work_mode, level, contract_type, job_function
  value       text not null,
  group_name  text,                   -- form layout only (sector groups)
  sort_order  int  not null default 0,
  version     int  not null default 1,
  primary key (list_name, value)
);

insert into taxonomy_options (list_name, value, group_name, sort_order) values
-- Sectors
('sector','Construction & civil engineering','Built environment & energy',1),
('sector','Housebuilding & property development','Built environment & energy',2),
('sector','Retrofit & energy efficiency','Built environment & energy',3),
('sector','Renewable energy & clean tech','Built environment & energy',4),
('sector','Energy & utilities (incl. water)','Built environment & energy',5),
('sector','Social housing & housing associations','Built environment & energy',6),
('sector','Facilities management & property services','Built environment & energy',7),
('sector','Architecture, surveying & engineering consultancy','Built environment & energy',8),
('sector','Marine, ports & maritime','Transport & marine',9),
('sector','Transport & logistics','Transport & marine',10),
('sector','Aviation & aerospace','Transport & marine',11),
('sector','Automotive','Transport & marine',12),
('sector','Software & SaaS','Technology',13),
('sector','Fintech','Technology',14),
('sector','AI & data','Technology',15),
('sector','Cybersecurity','Technology',16),
('sector','IT services & consultancy','Technology',17),
('sector','Telecoms','Technology',18),
('sector','E-commerce & marketplaces','Technology',19),
('sector','Banking & insurance','Finance & professional services',20),
('sector','Investment & asset management','Finance & professional services',21),
('sector','Accounting, legal & consulting','Finance & professional services',22),
('sector','Recruitment & HR services','Finance & professional services',23),
('sector','Central & local government','Public sector & non-profit',24),
('sector','NHS & healthcare','Public sector & non-profit',25),
('sector','Education & training','Public sector & non-profit',26),
('sector','Charity & social enterprise','Public sector & non-profit',27),
('sector','Defence & security','Public sector & non-profit',28),
('sector','Manufacturing & engineering','Industry & science',29),
('sector','Pharma, biotech & life sciences','Industry & science',30),
('sector','Food, drink & agriculture','Industry & science',31),
('sector','Environmental services & waste','Industry & science',32),
('sector','Retail & consumer goods','Consumer & creative',33),
('sector','Hospitality, events & leisure','Consumer & creative',34),
('sector','Media, marketing & creative','Consumer & creative',35),
('sector','Travel & tourism','Consumer & creative',36),
-- Focus areas (optional, cross-cutting)
('focus_area','Climate & sustainability',null,1),
('focus_area','Social impact',null,2),
('focus_area','Health & wellbeing',null,3),
('focus_area','Education & skills',null,4),
('focus_area','Financial inclusion',null,5),
-- Company type
('company_type','Startup',null,1),
('company_type','Scale-up',null,2),
('company_type','Established SME',null,3),
('company_type','Large corporate',null,4),
('company_type','Public sector',null,5),
('company_type','Charity or social enterprise',null,6),
('company_type','Recruitment agency',null,7),
-- Size band
('size_band','1-49',null,1),
('size_band','50-249',null,2),
('size_band','250-999',null,3),
('size_band','1,000-4,999',null,4),
('size_band','5,000+',null,5),
-- Ways of working (jobs)
('work_mode','On-site',null,1),
('work_mode','Hybrid',null,2),
('work_mode','Remote (UK)',null,3),
('work_mode','Remote (anywhere)',null,4),
-- Level (jobs)
('level','Trainee or entry',null,1),
('level','Assistant or junior',null,2),
('level','Coordinator, officer or specialist',null,3),
('level','Manager',null,4),
('level','Senior manager or lead',null,5),
('level','Head of or director',null,6),
('level','Executive',null,7),
-- Contract type (jobs)
('contract_type','Permanent full time',null,1),
('contract_type','Permanent part time',null,2),
('contract_type','Fixed-term',null,3),
('contract_type','Contract or freelance',null,4),
('contract_type','Temporary',null,5),
('contract_type','Apprenticeship or graduate scheme',null,6),
-- Job function (jobs)
('job_function','Project & programme management',null,1),
('job_function','Operations',null,2),
('job_function','Customer success & account management',null,3),
('job_function','Sales & business development',null,4),
('job_function','Solutions & pre-sales',null,5),
('job_function','Marketing & communications',null,6),
('job_function','Product management',null,7),
('job_function','Software engineering',null,8),
('job_function','Data & analytics',null,9),
('job_function','Design',null,10),
('job_function','Finance',null,11),
('job_function','HR & people',null,12),
('job_function','Administration & office support',null,13),
('job_function','Sustainability & ESG',null,14),
('job_function','Surveying & site roles',null,15),
('job_function','Policy & research',null,16)
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- 2. Companies (one row per employer, shared by all users)
-- ---------------------------------------------------------------------------
create table if not exists companies (
  id                 uuid primary key default gen_random_uuid(),
  name               text not null,
  name_key           text not null unique,  -- lower-case name without Ltd/Limited/plc etc., for matching duplicates
  website            text,
  description        text,                  -- one or two sentences, written by Claude when tagging
  main_sector        text,
  secondary_sectors  text[] not null default '{}',   -- up to 2
  focus_areas        text[] not null default '{}',
  company_type       text,
  size_band          text,
  uk_locations       text[] not null default '{}',   -- e.g. {London, Manchester}
  hires_remote_uk    boolean,
  discovered_via     text not null,         -- common_crawl, aggregator, search_engine, user_target, seed_list, companies_house
  tag_version        int,                   -- taxonomy version used when tagged
  tag_confidence     text,                  -- high, medium, low
  needs_review       boolean not null default false,
  review_note        text,                  -- e.g. "no sector fits: suggests 'Arts & heritage'"
  tagged_at          timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

-- Single-value tags must come from the lists (array tags are checked by the tagging step).
alter table companies drop constraint if exists companies_main_sector_fk;
alter table companies drop constraint if exists companies_company_type_fk;
alter table companies drop constraint if exists companies_size_band_fk;
alter table companies add column if not exists main_sector_list  text generated always as ('sector') stored;
alter table companies add column if not exists company_type_list text generated always as ('company_type') stored;
alter table companies add column if not exists size_band_list    text generated always as ('size_band') stored;
alter table companies add constraint companies_main_sector_fk
  foreign key (main_sector_list, main_sector) references taxonomy_options (list_name, value);
alter table companies add constraint companies_company_type_fk
  foreign key (company_type_list, company_type) references taxonomy_options (list_name, value);
alter table companies add constraint companies_size_band_fk
  foreign key (size_band_list, size_band) references taxonomy_options (list_name, value);

create index if not exists companies_main_sector_idx on companies (main_sector);
create index if not exists companies_secondary_sectors_idx on companies using gin (secondary_sectors);
create index if not exists companies_focus_areas_idx on companies using gin (focus_areas);

-- ---------------------------------------------------------------------------
-- 3. Where each company's jobs can be pulled from (a company can have several)
-- ---------------------------------------------------------------------------
create table if not exists company_job_sources (
  id              uuid primary key default gen_random_uuid(),
  company_id      uuid not null references companies (id) on delete cascade,
  source          text not null check (source in
                    ('greenhouse','lever','ashby','workable','smartrecruiters','recruitee',
                     'adzuna','reed','careers_page')),
  slug            text,                   -- board name, e.g. "octopusenergy"; null for adzuna/reed
  board_url       text,
  status          text not null default 'unchecked'
                    check (status in ('unchecked','active','no_jobs','not_found','error')),
  open_jobs       int,
  uk_jobs         int,
  last_uk_job_at  timestamptz,
  last_checked_at timestamptz,
  created_at      timestamptz not null default now(),
  unique (source, slug)
);

create index if not exists company_job_sources_company_idx on company_job_sources (company_id);
create index if not exists company_job_sources_status_idx on company_job_sources (status);

-- ---------------------------------------------------------------------------
-- 4. Keep updated_at current
-- ---------------------------------------------------------------------------
create or replace function set_updated_at() returns trigger as $$
begin new.updated_at = now(); return new; end;
$$ language plpgsql;

drop trigger if exists companies_updated_at on companies;
create trigger companies_updated_at before update on companies
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------------
-- 5. Quick check after running: should return 8 lists and 86 options in total
-- ---------------------------------------------------------------------------
select list_name, count(*) from taxonomy_options group by list_name order by list_name;
