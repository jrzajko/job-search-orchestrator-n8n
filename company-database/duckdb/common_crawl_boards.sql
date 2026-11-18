-- Find every company with a public job board on Greenhouse, Ashby or Workable,
-- using Common Crawl's URL index (free), queried locally with DuckDB.
--
-- Run in the DuckDB CLI with a database file so results survive a failed batch:
--   duckdb cc.duckdb
-- Then paste the sections below in order. Tested with DuckDB 2.0 on macOS.
--
-- Change the crawl ID to the latest one listed at https://index.commoncrawl.org/collinfo.json
-- (CC-MAIN-2026-43 = October 2026). Older crawls add companies the newest one missed.

-- 1. Setup. Retries and fewer threads, because data.commoncrawl.org cuts off
--    transfers ("Transferred a partial file") when too many run at once.
INSTALL httpfs; LOAD httpfs;
SET http_retries = 10;
SET http_retry_wait_ms = 2000;
SET http_retry_backoff = 2;
SET threads = 4;

-- 2. The list of URL index files for one crawl (300 Parquet files in subset=warc).
SET VARIABLE files = (
  SELECT list('https://data.commoncrawl.org/' || column0)
  FROM read_csv('https://data.commoncrawl.org/crawl-data/CC-MAIN-2026-43/cc-index-table.paths.gz',
                header=false, columns={'column0':'VARCHAR'})
  WHERE column0 LIKE '%subset=warc%'
);
SELECT len(getvariable('files')) AS file_count;

-- 3. One row per host and company slug, with how many archived job pages it has.
--    The index is sorted by url_surtkey (reversed host), so these ranges let DuckDB
--    read only a small part of each file.
--    Lever (jobs.lever.co) is not included: its robots.txt blocks Common Crawl's crawler (CCBot),
--    so the index has no Lever pages.
CREATE TABLE IF NOT EXISTS board_pages (host VARCHAR, slug VARCHAR, pages BIGINT);

-- Run in batches of 50 files: [1:50], [51:100], [101:150], [151:200], [201:250], [251:300].
-- If a batch fails, re-run just that batch.
INSERT INTO board_pages
SELECT url_host_name, split_part(url_path, '/', 2), count(*)
FROM read_parquet(getvariable('files')[1:50])
WHERE fetch_status = 200 AND (
     (url_surtkey >= 'com,ashbyhq,jobs)/'          AND url_surtkey < 'com,ashbyhq,jobs)0')
  OR (url_surtkey >= 'io,greenhouse,boards)/'      AND url_surtkey < 'io,greenhouse,boards)0')
  OR (url_surtkey >= 'io,greenhouse,job-boards)/'  AND url_surtkey < 'io,greenhouse,job-boards)0')
  OR (url_surtkey >= 'com,workable,apply)/'        AND url_surtkey < 'com,workable,apply)0')
)
GROUP BY 1, 2;

-- 4. Check the totals.
SELECT host, count(DISTINCT slug) AS companies, sum(pages) AS pages
FROM board_pages GROUP BY host ORDER BY companies DESC;

-- 5. Export a clean list for Supabase (board_candidates table, sql/002).
--    The excluded values are page paths, not companies (e.g. Workable's /j/ short links).
COPY (
  SELECT CASE host
           WHEN 'apply.workable.com'       THEN 'workable'
           WHEN 'job-boards.greenhouse.io' THEN 'greenhouse'
           WHEN 'boards.greenhouse.io'     THEN 'greenhouse'
           WHEN 'jobs.ashbyhq.com'         THEN 'ashby'
         END AS source,
         slug, sum(pages) AS pages
  FROM board_pages
  WHERE slug NOT IN ('', 'j', 'api', 'embed', 'b', 'jobs', 'meeting')
  GROUP BY 1, 2
  ORDER BY source, pages DESC
) TO 'board_slugs.csv' (HEADER);
