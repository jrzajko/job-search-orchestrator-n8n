# Changelog

Dated progress, newest first. The early entries are the personal pipeline (`workflows/`); from 13 November the same pipeline became the starting point for a done-for-you job search service for other people (CV, LinkedIn guide and a daily digest), tested with two users. Test users are not named here.

## 18 November 2026: company database and intake form v2
- **Data strategy changed.** Aggregator APIs need a paid commercial licence before any paying user, and full descriptions need a higher tier. Company job boards are free and include full descriptions, so the service now builds its own database of UK-hiring companies (`company-database/`).
- **Shared lists:** 36 sectors, 5 focus areas, 7 company types, 5 size bands, plus ways of working, level, contract type and job function, used on both the intake form and the company tags.
- **Company discovery from Common Crawl:** DuckDB over the Parquet URL index found 7,792 company boards in the October 2026 crawl (Workable 3,666, Greenhouse 3,022, Ashby 1,106). Lever blocks Common Crawl's crawler, so it's missing for now.
- **Board check workflow:** calls each board's public feed once and records open jobs and UK jobs. First 20: 11 with UK roles.
- **Tagging workflow:** Claude Haiku 5.5 tags each UK-hiring company from the shared lists, at about $0.0002 a company; off-list or unsure results are flagged for review.
- **Intake form v2** (`intake/update_intake_form_v2.gs`): updates the live form in place, adding tick-box questions for sectors, kinds of work, what the company works on, company type and size, with the same wording as the company tags.
- Evaluated and set aside: a paid company/jobs data provider (self-service licence is internal-use only), UK government job APIs (one is for cross-government use and duplicates the main aggregator; NHS Jobs has an open feed but is narrow; Civil Service Jobs has no API).

## 17 November 2026
- **Agent notebook** (`notebooks/job_search_agent.ipynb`) for an agentic-AI course exercise: one job-search agent with three tools (live job search, salary spread, candidate profile), falling back to the model for anything else, with LangSmith tracing. Fictional candidate.
- Design conclusion recorded: the daily pipeline stays a fixed workflow; agents fit the judgement steps (user setup, company discovery and tagging, matching, on-demand CV tailoring).
- Licence reply from the main aggregator: commercial use needs a paid licence before launch; the free key is for testing only.

## 16 November 2026
- Scoring moved to **Claude Haiku 5.5** (about 10× cheaper than Haiku 4.5). It thinks by default, so the call disables thinking and the parser reads the first text block; caught in a test before going live.
- The unprocessed backlog fix from the v2 limitations: only postings first seen in the last 3 days are re-read (about 325 rows instead of about 1,300).

## 14 November 2026
- A Code node returned items that still carried a sub-workflow's `metadata` key, which n8n rejects ("Invalid output format"), so one morning's digest didn't send. Fixed by returning plain `{ json, pairedItem }` items, tested in a copy first.

## 13 November 2026: second user's pipeline
- The pipeline was copied and retuned for a second user changing sector: 36 searches across London, another city, remote and UK-wide niche terms.
- **Broad titles search newest first:** title-only search, sorted by date, last 3 days. For one broad search the old relevance sort returned 45 of 50 ads already seen; the new mode returned 49 new ones.
- **Cheaper scoring:** senior and IT titles dropped before scoring; at most 60 postings scored per run, best-fit role types first.
- **Skipped searches are no longer silent:** a failed search returns a marker, and a separate email names any searches skipped after 5 retries.
- Each emailed listing credits the job source, as the aggregator's terms require.

## Early November 2026: v2.1
- An aggregator outage skips one search instead of failing the run; failed runs send an alert email.

## Early November 2026: v2 (first scheduled run 4 November)
- Applied / Not interested buttons with signed links and a confirmation page; Applied creates a Notion job pipeline page. Scores and reasons stored in Supabase.

## October 2026: v1
- Aggregator → Supabase dedupe → free filter → Claude scoring → daily email digest.
