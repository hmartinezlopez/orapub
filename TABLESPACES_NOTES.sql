
select TS#, NAME, BIGFILE, FLASHBACK_ON 
from V$TABLESPACE;



select a.tablespace_name,
       a.bytes_alloc/(1024*1024) "TOTAL ALLOC (MB)",
       a.physical_bytes/(1024*1024) "TOTAL PHYS ALLOC (MB)",
       nvl(b.tot_used,0)/(1024*1024) "USED (MB)",
       (nvl(b.tot_used,0)/a.bytes_alloc)*100 "% USED"
from ( select tablespace_name,
       sum(bytes) physical_bytes,
       sum(decode(autoextensible,'NO',bytes,'YES',maxbytes)) bytes_alloc
       from dba_data_files
       group by tablespace_name ) a,
     ( select tablespace_name, sum(bytes) tot_used
       from dba_segments
       group by tablespace_name ) b
where a.tablespace_name = b.tablespace_name (+)
--and   (nvl(b.tot_used,0)/a.bytes_alloc)*100 > 10
and   a.tablespace_name not in (select distinct tablespace_name from dba_temp_files)
and   a.tablespace_name not like 'UNDO%'
order by 1;



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


SELECT df.file_name, df.tablespace_name
FROM dba_data_files df
LEFT JOIN dba_extents de ON df.file_id = de.file_id
GROUP BY df.file_name, df.tablespace_name
HAVING COUNT(de.extent_id) = 0
ORDER BY df.tablespace_name, df.file_name;

SELECT df.file_name, df.FILE_ID
FROM dba_data_files df
where tablespace_name = 'TS_HDR_DATA';




SELECT segment_name, segment_type
FROM dba_segments
WHERE tablespace_name = 'TS_HDR_DATA';

SELECT dba_tables.TABLE_NAME, dba_tables.blocks, dba_tables.empty_blocks
FROM dba_tables, dba_segments
WHERE dba_tables.table_name = dba_segments.segment_name
AND dba_tables.owner = dba_segments.owner
AND dba_segments.tablespace_name = 'TS_HDR_DATA'
order by 2 desc;


SELECT segment_name, segment_type, MAX(block_id + blocks - 1) AS hwm
FROM dba_extents
WHERE file_id = (SELECT file_id FROM dba_data_files WHERE file_id = 44)
AND tablespace_name = 'TS_HDR_DATA'
GROUP BY segment_name, segment_type
ORDER BY 3 DESC;



desc dba_tables;


SELECT blocks - (blocks - empty_blocks) AS reclaimable_blocks
FROM dba_tables
WHERE table_name = 'TS_HDR_DATA';




SELECT tablespace_name, 
       SUM(bytes) / 1024 / 1024 / 1024 AS total_size_gb,
       SUM(bytes) / 1024 / 1024 / 1024 - 
       SUM(CASE WHEN segment_type = 'TABLE' THEN bytes ELSE 0 END) / 1024 / 1024 / 1024 AS fragmented_space_gb
FROM dba_segments
WHERE tablespace_name = 'TS_HDR_DATA'
GROUP BY tablespace_name;
