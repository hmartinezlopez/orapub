-- redo_performance.sql
-- 
-- Purpose: This script is used to check the redo log performance
-- and to determine if the redo log group size is appropriate.
-- 
-- 2014-10-01 hmartinez created this script
-- Version: 1.0



-- Script to Collect Log File Sync Diagnostic Information (lfsdiag.sql) (Doc ID 1064487.1)
-- Master Note: Troubleshooting Redo Logs and Archiving (Doc ID 1507157.1)

-- Peak redo rate according
-- to EM or AWR reports 	     Recommended redo log group size
-- <1 MB/sec 	                     1 GB
-- <=3 MB/sec 	                     3 GB
-- <= 5 MB/sec 	                     4 GB
-- <= 25 MB/sec 	                16 GB
-- <= 50 MB/sec 	                32 GB
-- > 50 MB/sec 	                    64 GB


select * from (
select thread#,sequence#,first_time "LOG START TIME",(blocks*block_size/1024/1024)/((next_time-first_time)*86400) "REDO RATE(MB/s)", (((blocks*block_size)/a.average)*100) pct_full
from v$archived_log, (select avg(bytes) average from v$log) a
where ((next_time-first_time)*86400<300)
and first_time > (sysdate-90)
and (((blocks*block_size)/a.average)*100)>80
and dest_id=1
order by 4 desc
)
where rownum<11;


