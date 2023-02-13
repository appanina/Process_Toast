export PGHOST=$1
export PGPORT=$2
export PGDATABASE=$3
export PGUSER=$4
export PGPASSWORD=$5
export LOG=$HOME/log
exec > $LOG/ProcessToast-$PGHOST-"`date +"%d-%m-%Y-%H%M"`".log 2>&1
psql << EOF
--DROP tables if they exist
DROP TABLE IF EXISTS t1_toast;
DROP TABLE IF EXISTS t2_toast;
--CREATE tables and disable autovacuum for demo purposes.
CREATE TABLE t1_toast (sno BIGINT, description TEXT);
ALTER TABLE t1_toast SET (autovacuum_enabled = 'false');
CREATE TABLE t2_toast (sno BIGINT, description TEXT);
ALTER TABLE t2_toast SET (autovacuum_enabled = 'false');
--Perform a manual vacuum
VACUUM ANALYZE t1_toast ;
VACUUM ANALYZE t2_toast ;
--Load data into t1_toast
INSERT INTO t1_toast SELECT t, array_to_string(ARRAY(SELECT chr((10 + round(random() * 10)) :: integer) FROM generate_series(1,1000)), '')||t FROM generate_series(1, 500000) t;
SELECT age(relfrozenxid) AS table_age,pg_size_pretty(pg_relation_size(oid)) table_data_size,pg_size_pretty(pg_relation_size(reltoastrelid)) table_toasted_data_size,pg_size_pretty(pg_total_relation_size(oid)) total_size FROM pg_class WHERE relname = 't1_toast';
INSERT INTO t1_toast SELECT t, array_to_string(ARRAY(SELECT chr((10 + round(random() * 10)) :: integer) FROM generate_series(1,500000)), '')||t FROM generate_series(1, 10000) t;
SELECT pg_size_pretty(pg_relation_size(oid)) table_data_size,pg_size_pretty(pg_relation_size(reltoastrelid)) table_toasted_data_size,pg_size_pretty(pg_total_relation_size(oid)) total_size FROM pg_class WHERE relname = 't1_toast';
--DELETE data from t1_toast
DELETE FROM t1_toast;
--Load data into t2_toast
INSERT INTO t2_toast SELECT t, array_to_string(ARRAY(SELECT chr((10 + round(random() * 10)) :: integer) FROM generate_series(1,1000)), '')||t FROM generate_series(1, 500000) t;
SELECT age(relfrozenxid) AS table_age,pg_size_pretty(pg_relation_size(oid)) table_data_size,pg_size_pretty(pg_relation_size(reltoastrelid)) table_toasted_data_size,pg_size_pretty(pg_total_relation_size(oid)) total_size FROM pg_class WHERE relname = 't2_toast';
INSERT INTO t2_toast SELECT t, array_to_string(ARRAY(SELECT chr((10 + round(random() * 10)) :: integer) FROM generate_series(1,500000)), '')||t FROM generate_series(1, 10000) t;
SELECT pg_size_pretty(pg_relation_size(oid)) table_data_size,pg_size_pretty(pg_relation_size(reltoastrelid)) table_toasted_data_size,pg_size_pretty(pg_total_relation_size(oid)) total_size FROM pg_class WHERE relname = 't2_toast';
--DELETE data from t2_toast
DELETE FROM t2_toast;
--Check storage used and % of bloat split between toast and main relations
SELECT
    pg_size_pretty(pg_relation_size(oid)) table_data_size,
    pg_size_pretty(pg_relation_size(reltoastrelid)) table_toasted_data_size,
    pg_size_pretty(pg_total_relation_size(oid)) total_size
FROM
    pg_class
WHERE
    relname IN ('t1_toast','t2_toast');
WITH x
     AS (SELECT relname AS relname,
                n_dead_tup,
                n_live_tup
         FROM   pg_stat_all_tables
         WHERE  ( relname ) IN (SELECT relname
                                FROM   pg_class
                                WHERE  oid IN (SELECT reltoastrelid
                                               FROM   pg_class
                                               WHERE  relname = 't1_toast'))
         UNION ALL
         SELECT relname AS relname,
                n_dead_tup,
                n_live_tup
         FROM   pg_stat_all_tables
         WHERE  relname IN ( 't1_toast' ))
SELECT relname,
       CASE n_dead_tup
         WHEN 0 THEN 0
         ELSE ( n_dead_tup / SUM(n_dead_tup)
                               over () ) * 100
       END AS "% of bloat"
FROM   x
GROUP  BY relname,
          n_dead_tup;
WITH x
     AS (SELECT relname AS relname,
                n_dead_tup,
                n_live_tup
         FROM   pg_stat_all_tables
         WHERE  ( relname ) IN (SELECT relname
                                FROM   pg_class
                                WHERE  oid IN (SELECT reltoastrelid
                                               FROM   pg_class
                                               WHERE  relname = 't2_toast'))
         UNION ALL
         SELECT relname AS relname,
                n_dead_tup,
                n_live_tup
         FROM   pg_stat_all_tables
         WHERE  relname IN ( 't2_toast' ))
SELECT relname,
       CASE n_dead_tup
         WHEN 0 THEN 0
         ELSE ( n_dead_tup / SUM(n_dead_tup)
                               over () ) * 100
       END AS "% of bloat"
FROM   x
GROUP  BY relname,
          n_dead_tup;
--Perform manual VACUUM
\timing
VACUUM (PROCESS_TOAST false,FREEZE) t1_toast;
VACUUM (FREEZE) t2_toast;
\timing
--Check storage used and % of bloat split between toast and main relations
SELECT
    pg_size_pretty(pg_relation_size(oid)) table_data_size,
    pg_size_pretty(pg_relation_size(reltoastrelid)) table_toasted_data_size,
    pg_size_pretty(pg_total_relation_size(oid)) total_size
FROM
    pg_class
WHERE
    relname IN ('t1_toast','t2_toast');
WITH x
     AS (SELECT relname AS relname,
                n_dead_tup,
                n_live_tup
         FROM   pg_stat_all_tables
         WHERE  ( relname ) IN (SELECT relname
                                FROM   pg_class
                                WHERE  oid IN (SELECT reltoastrelid
                                               FROM   pg_class
                                               WHERE  relname = 't1_toast'))
         UNION ALL
         SELECT relname AS relname,
                n_dead_tup,
                n_live_tup
         FROM   pg_stat_all_tables
         WHERE  relname IN ( 't1_toast' ))
SELECT relname,
       CASE n_dead_tup
         WHEN 0 THEN 0
         ELSE ( n_dead_tup / SUM(n_dead_tup)
                               over () ) * 100
       END AS "% of bloat"
FROM   x
GROUP  BY relname,
          n_dead_tup;
WITH x
     AS (SELECT relname AS relname,
                n_dead_tup,
                n_live_tup
         FROM   pg_stat_all_tables
         WHERE  ( relname ) IN (SELECT relname
                                FROM   pg_class
                                WHERE  oid IN (SELECT reltoastrelid
                                               FROM   pg_class
                                               WHERE  relname = 't2_toast'))
         UNION ALL
         SELECT relname AS relname,
                n_dead_tup,
                n_live_tup
         FROM   pg_stat_all_tables
         WHERE  relname IN ( 't2_toast' ))
SELECT relname,
       CASE n_dead_tup
         WHEN 0 THEN 0
         ELSE ( n_dead_tup / SUM(n_dead_tup)
                               over () ) * 100
       END AS "% of bloat"
FROM   x
GROUP  BY relname,
          n_dead_tup;
EOF
