-- ░▒▓█►─═ STORAGE ═─►█▓▒░
-- tablespace_usage.sql
-- Oracle SQL script to report tablespace usage
--- 2025-04-25 hmartinez create tablespace usage report

select a.tablespace_name,
       a.bytes_alloc/(1024*1024) "MAX ALLOC (MB)",
       a.physical_bytes/(1024*1024) "TOTAL PHYS ALLOC (MB)",
       nvl(b.tot_used,0)/(1024*1024) "USED (MB)",
       TO_CHAR((nvl(b.tot_used,0)/NULLIF(a.physical_bytes, 0))*100, 'FM999999990.00') || '%' "% USED"
from ( select tablespace_name,
       sum(bytes) physical_bytes,
       sum(CASE autoextensible WHEN 'NO' THEN bytes WHEN 'YES' THEN maxbytes END) bytes_alloc
       from dba_data_files
       group by tablespace_name ) a,
     ( select tablespace_name, sum(bytes) tot_used
       from dba_segments
       group by tablespace_name ) b
where a.tablespace_name = b.tablespace_name (+)
  and b.tablespace_name is not null
--and   (nvl(b.tot_used,0)/a.bytes_alloc)*100 > 10
and   a.tablespace_name not in (select distinct tablespace_name from dba_temp_files)
and   a.tablespace_name NOT LIKE 'UNDO%'
order by a.tablespace_name;


