
-- LONG OPS VERSION 
--
-- set linesize 150 
-- SELECT TO_CHAR(START_TIME,'DD/MM/RRRR HH24:MI:SS') as BEGIN, TO_CHAR(SYSDATE,'DD/MM/RRRR HH24:MI:SS') as NOW, SID, SERIAL#, CONTEXT, SOFAR, TOTALWORK,ROUND(SOFAR/TOTALWORK*100,2) "%_COMPLETE",TIME_REMAINING/60/60 HOUR_REMAIN 
-- FROM V$SESSION_LONGOPS 
-- WHERE OPNAME LIKE 'RMAN%' 
-- AND OPNAME NOT LIKE '%aggregate%' 
-- AND TOTALWORK != 0 
-- AND SOFAR <> TOTALWORK;

--

-- https://plus.google.com/u/0/107075205411714880234/posts/L6QFgvCuGjL
--
-- Yury Velikanov
-- https://plus.google.com/u/0/107075205411714880234
-- 
-- Thanks folks for the comments and contribution. Long ops is generally good for the long operations monitoring as the name suggests :) RMAN view adds a bit more details on the speed of the recovery itself and allows to tune it playing with parallel execution numbers.﻿


set lines 180 pages 1000 numwidth 15
column OPERATION for a8
column STATUS for a10
column OPERATION for a10
alter session set nls_date_format='YYYY.MM.DD HH24:MI:SS';
select 
OPERATION, 
STATUS, 
MBYTES_PROCESSED/1024 GB_PROCESSED, 
START_TIME, 
END_TIME,
(END_TIME-START_TIME)*24*60 RUNTIME_MINS,
trunc(INPUT_BYTES/1024/1024/1024,2) INPUT_GB, 
trunc(OUTPUT_BYTES/1024/1024/1024,2) OUTPUT_GB
from V$RMAN_STATUS
where START_TIME > sysdate - 1
and OPERATION = 'RESTORE';




