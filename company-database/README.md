# Company database

A free way to build a list of UK-hiring employers, tagged by sector, type and size, with a feed for each one's open jobs, full descriptions included. It's the core of the multi-user version of the job search service: users are matched to companies, and the daily pipeline pulls roles from those companies' public job boards.

Built 18 November 2026. Status: board check and tagging running; matching and the daily pull are next.

---

## Why

Broad job APIs were fine for one person's search but don't fit a paid service:

- **Licensing.** Commercial use of the main UK aggregator needs a paid licence before the first paying user, and full job descriptions need a higher tier on top. A paid company/jobs data provider that was evaluated licenses its self-service data for internal use only.
- **Descriptions.** Aggregators return a short snippet, so scoring and CV tailoring work from a fraction of the ad.

Company job boards (Greenhouse, Ashby, Workable, Lever and others) publish every open role, with the full description, through free public feeds. The catch: there's no search across companies. You have to know each company's board name first. This folder is the answer to "where do the company names come from?".

---

## How it works

```
Common Crawl URL index (free, monthly)
   → DuckDB: every archived page under the job board hosts → company slugs   (duckdb/)
   → Supabase board_candidates                                               (sql/002)
   → n8n "Companies - Check Job Boards": call each board once,
        count open jobs and UK jobs, keep the company name                   (workflows/company-board-check.json)
   → promote_uk_boards(): one company per brand, one source per board        (sql/003)
   → n8n "Companies - Tag with Claude": Haiku reads the board's UK roles
        and "About us" text, tags from the shared lists                      (workflows/company-tagging.json)
   → [next] match users to companies → daily pull from matched boards
```

| Stage | What it does | Cost |
|---|---|---|
| Find | Query Common Crawl's Parquet URL index with DuckDB, by host, and take the first path segment as the company slug | Free |
| Check | One request per board to its public feed: open jobs, UK jobs (UK place names and country codes, US state patterns excluded), status `uk` / `no_uk` / `no_jobs` / `not_found` / `error` | Free feeds; a few n8n executions |
| Promote | Copy boards with UK jobs into `companies` and `company_job_sources`. A name key ("Acme Ltd" = "acme") merges a company found on two systems | Free |
| Tag | Claude Haiku 5.5 returns brand name, one-line description, main and secondary sectors, focus areas, company type, size band, UK locations and remote hiring, using only the shared lists. Off-list or low-confidence results are flagged `needs_review` | ~2,000 tokens in, ~170 out: about $0.0002 a company |

---

## The shared lists

Users and companies are described in the same words, so matching is mostly a lookup and the AI only handles nuance. The same options appear on the intake form (`../intake/`) and in the `taxonomy_options` table (`sql/001`):

| List | Options |
|---|---|
| Sector | 36, in 7 groups: built environment & energy, transport & marine, technology, finance & professional services, public sector & non-profit, industry & science, consumer & creative |
| Focus area | Climate & sustainability, Social impact, Health & wellbeing, Education & skills, Financial inclusion |
| Company type | Startup, Scale-up, Established SME, Large corporate, Public sector, Charity or social enterprise, Recruitment agency |
| Size band | 1–49, 50–249, 250–999, 1,000–4,999, 5,000+ |
| Ways of working, level, contract type, job function | Used for jobs and user preferences |

Main sector, company type and size band are foreign keys to the list table, so a tag that isn't on the list can't be saved.

---

## Results so far

| Step | Number |
|---|---|
| Company slugs from one crawl (October 2026) | 7,792: Workable 3,666, Greenhouse 3,022, Ashby 1,106 |
| Lever slugs | 0. Lever's robots.txt blocks Common Crawl's crawler |
| First board check (20 boards) | 11 with UK roles, 8 with jobs but none in the UK, 1 gone; 15 seconds |
| First tagging run (10 companies) | All tagged from the lists; 8 high and 2 medium confidence; 1 flagged (a dental software company: no health-tech sector yet) |

The full board check runs 400 boards every 10 minutes.

---

## Where it went wrong

- **Lever returned nothing.** The query was right; Lever opts out of Common Crawl. Lever companies need another route (trying employer names already seen in aggregator results, or search-engine discovery).
- **The CDX lookup API timed out** (502) on whole-host queries. The Parquet index queried with DuckDB doesn't depend on that server.
- **Downloads were cut off** halfway ("Transferred a partial file"). Fewer threads, HTTP retries and batches of 50 files fixed it, and a database file keeps finished batches.
- **Successful runs were invisible.** Turning off saved data for successful executions (to save storage) also hid them from the executions list. It was switched back on.

---

## Design decisions

- **Fetch inside the Code node** (`this.helpers.httpRequest`), not with an HTTP Request node, so each run keeps only a small summary per board rather than every job description in memory.
- **Shared, not per user.** Each board is checked once a day however many users care about it, so cost grows with companies, not users.
- **Lists before data.** The lists were fixed before tagging, because changing them later means re-tagging (`tag_version`).
- **Haiku with thinking disabled** for tagging: a short, structured task.

## Limits

- Coverage leans to tech, SaaS, startups and scale-ups. Construction firms, housing associations and many public bodies use other recruitment systems without open feeds, so broad sources stay necessary for those users.
- Each crawl samples the web; older crawls add companies, and boards that disappear are marked `not_found`.
- Board vendors' terms for use in a paid service still need checking.

---

## Setup

1. Supabase SQL editor: run `sql/001_company_schema.sql`, then `sql/002_board_candidates.sql`, then `sql/003_promote_uk_boards.sql`.
2. Run `duckdb/common_crawl_boards.sql` in the DuckDB CLI and import `board_slugs.csv` into `board_candidates`.
3. n8n: import both workflows, select your Supabase (service role key) and Anthropic credentials on the nodes (placeholders `SUPABASE_CREDENTIAL_ID` / `ANTHROPIC_CREDENTIAL_ID`), and publish the board check. Switch its schedule off when nothing is left unchecked.
4. `select * from promote_uk_boards();` in Supabase, then run the tagging workflow until `companies_to_tag` is empty.
