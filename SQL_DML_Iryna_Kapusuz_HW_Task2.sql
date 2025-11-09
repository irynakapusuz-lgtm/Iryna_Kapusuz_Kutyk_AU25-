---Task 1 Create table ‘table_to_delete’ 
BEGIN;
CREATE TABLE table_to_delete as 
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;    
COMMIT;

---check
SELECT *
FROM table_to_delete
LIMIT 10;

---Task 2 Checking how much space this table consumes;
SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';

-----Task 3. A DELETE operation from 'table_to_delete'
-----we use Explain Analyze to check execution time

BEGIN;
EXPLAIN ANALYZE
DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; 
COMMIT;
-----31 sec 91 msec

-----Task 3.B. 

SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';

----- 575MB
---Task 3.C. VACUUM FULL VERBOSE table_to_delete;

VACUUM FULL VERBOSE table_to_delete; 
--- result showed in screenshot;

---Task 3.D Checking space comsumptıon;

SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';

--- Answer: 383 MB
--- Task 3. E. Recreate table_to_delete;
BEGIN;
DROP TABLE IF EXISTS table_to_delete;
CREATE TABLE table_to_delete as 
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;    
COMMIT;


----Task 4.A TRUNCATE a table;

BEGIN;
TRUNCATE TABLE table_to_delete;
COMMIT;
---Answer: 115msc;
---4.B.Checking space comsumption:

SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';
----Task 4c: 0 MB;

----Task 5; Space consumption of table_to_delete:
---BEFORE DELETE:        575 MB     
---AFTER DELETE:         575 MB
---AFTER VACUUM FULL:    380 MB
---AFTER TRUnCATE:       8.192 byte, table_bytes 0 MB;
----------  Duration of operations;
----DELETE/EXPLAIN TO ANALYZE: 31 sec
----VACUUM FULl VERBOSE:       10 sec
----TRUNCATE:                  0,18 msec
---CONCLUSION: 

---BEFORE DELETE:     Full table with 10 mln rows;         
---AFTER DELETE:      No change - rows remains as dead tuples;       
---AFTER VACUUM FULL: Table physically compacted;    
---AFTER TRUnCATE:    Table almost empty; only metadata remained;