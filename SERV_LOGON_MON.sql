create or replace TRIGGER SERV_LOGON_MON 
AFTER LOGON ON DATABASE
declare
-- v0.1 Initial version by yvelik on 04/06/2014
-- v0.2 Personalitation version by hmartinezlopez on 26/11/2014 
-- The trigger prevents default TNS service name to be used by clients to make sure that specific services are in use. Is specifically important to use custom service names in a RAC configuration.
-- The trigger allows exceptions to be introduced on host by host basis. To allow connections to the default host please insert a record to the serv_login_hosts_ext table
-- Information about all sessions that used the default DB service name is logged under serv_login_hosts_ext table
-- If the trigger raises unhandled exception then a line in the alert log is inserted

--# Objects used by the trigger (create those objects at the same time as the trigger)
--# create table serv_login_log as select * from gv$session where 1=2;
--# create table serv_login_hosts_ext (host varchar2(100), whoinserted varchar2(100), wheninserted date, description varchar2(4000));
--# create table serv_login_log_clients (wheninserted date, USERNAME varchar2(30), OSUSER varchar2(30), MACHINE varchar2(64), TERMINAL varchar2(30), PROGRAM varchar2(48), CLIENT_IDENTIFIER varchar2(64), SERVICE_NAME varchar2(64));
--# Example => insert into serv_login_hosts_ext values ('db01.yuryfun.com','yvelik',sysdate,'This is database host that we may connect to the default service from');

v_db_unique_name v_$parameter.value%type;
v_comp_db_unique_name v_$parameter.value%type;
v_parm_service_name v_$parameter.value%type;
v_db_domain v_$parameter.value%type;
v_session v_$session%rowtype;
v_msg varchar2(4000);
v_host_count number;
v_client_count number;

default_service_in_use EXCEPTION;

BEGIN
-- Let's the other world know where the SQLs are comimg from
DBMS_APPLICATION_INFO.SET_MODULE ('SERV_LOGON_MON',null); 
DBMS_APPLICATION_INFO.SET_CLIENT_INFO ('Logon trigger'); 

-- Select service name the session is connected to
select s.* into v_session from v$session s where sid=sys_context('USERENV', 'SID') and rownum<2;

-- Vista Top Clients en el EM
CASE lower(v_session.service_name)
-- Default
   WHEN 'odb11b.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Default');
   WHEN 'odb11b1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Default');
   WHEN 'odb11b2.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Default');
-- System
   WHEN 'SYS$BACKGROUND' THEN DBMS_SESSION.SET_IDENTIFIER('System');
   WHEN 'SYS$USERS' THEN DBMS_SESSION.SET_IDENTIFIER('System');
-- Desarrollo
   WHEN 'odescsi1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('CSI');
   WHEN 'odeshp01.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('HP');
-- HCIS
   WHEN 'ohciclu1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('HCIS');
-- EAI
   WHEN 'ohcipen1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('EAI');
   -- WHEN 'ohcipie1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('EAI');
   WHEN 'orhaper1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('EAI');
   WHEN 'orhaper2.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('EAI');
-- Zenworks
   WHEN 'ozenfla1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Zenworks');
   WHEN 'ozenflo1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Zenworks');
-- Dietetica
   WHEN 'odieaqu1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Dietetica');
   WHEN 'odieaqu2.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Dietetica');
   WHEN 'odiecli1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Dietetica');
-- eDelphyn
   WHEN 'oedecar1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('eDelphyn');
   WHEN 'oedecli1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('eDelphyn');
-- ePat
   WHEN 'opatene1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('ePat');
-- TeleForm
   WHEN 'otfocli1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('TeleForm');
-- dotNet
   WHEN 'osmgcli1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('dotNet');
   WHEN 'oceccli1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('dotNet');
   WHEN 'odpocli1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('dotNet');
   -- WHEN 'osaicli1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('dotNet');
   WHEN 'ofhrcli1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('dotNet');
-- Integraciones
   WHEN 'osioafr1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Integraciones');
   WHEN 'osioapo1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Integraciones');
   WHEN 'oomeshw.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Integraciones');
   WHEN 'oomesrv.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Integraciones');
   WHEN 'oevogal1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Integraciones');
   WHEN 'owebobe1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Integraciones');
   WHEN 'osicofe1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Integraciones');
   WHEN 'ohcionb1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Integraciones');
-- vCenter
   WHEN 'ovmwsal1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('vCenter');
   WHEN 'ovmwtau1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('vCenter');
-- Nimbus
   WHEN 'ovibvib1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('Nimbus');
-- OpenFire
   WHEN 'ooperus1.cspt.es' THEN DBMS_SESSION.SET_IDENTIFIER('OpenFire');
   ELSE DBMS_SESSION.SET_IDENTIFIER('Unknown');
END CASE;

-- Auditoria de clientes de base de datos (servidor, usuario)
select count(MACHINE) into v_client_count from serv_login_log_clients where MACHINE = nvl(v_session.machine,v_session.terminal) and USERNAME = v_session.username;
if v_client_count = 0
then
  insert into serv_login_log_clients select SYSDATE, USERNAME, OSUSER, nvl(MACHINE,TERMINAL), TERMINAL, PROGRAM, CLIENT_IDENTIFIER, SERVICE_NAME from gv$session where sid=sys_context('USERENV', 'SID') and inst_id=sys_context('USERENV', 'INSTANCE') and rownum<2;
end if;

-- Let's check if hosts exception list. If the session comes the host in the list we don't execute further checks
select count(host) into v_host_count from serv_login_hosts_ext where HOST = v_session.machine;

if v_host_count = 0
then
  -- Select the default services name
  select p.value into v_db_unique_name from v$parameter p where name = 'db_unique_name';
  -- Select db_domain from parameters list (cspt.es)
  select p.value into v_db_domain from v$parameter p where name = 'db_domain';
  -- Select service_names parameter list
  select p.value into v_parm_service_name from v$parameter p where name = 'service_names';

  -- There is a difference in naming depending if db_domain is set or not
  if v_db_domain is null 
  then v_comp_db_unique_name:=v_db_unique_name;
  else v_comp_db_unique_name:=v_db_unique_name||'.'||v_db_domain;
  end if;

  if upper(v_session.service_name) = upper(v_comp_db_unique_name)
  then
    RAISE default_service_in_use;
  end if;
end if;

-- Let's clean the application info
DBMS_APPLICATION_INFO.SET_MODULE (null, null); 
DBMS_APPLICATION_INFO.SET_CLIENT_INFO ( null ); 

EXCEPTION
WHEN default_service_in_use THEN
  -- For debug and log purposes. Let's record information about the session that uses the default TNS service
  insert into serv_login_log select * from gv$session where sid=sys_context('USERENV', 'SID') and inst_id=sys_context('USERENV', 'INSTANCE') and rownum<2;
  commit;
  -- Raise an exception (error_number is a negative integer in the range -20000 .. -20999 and message is a character string up to 2048 bytes long)
-- De momento solo auditamos
  -- v_msg := 'SERV_LOGON_MON: The session is not allowed to connects to the default TNS service '||v_session.service_name||'. Please use one of non-default services '||v_parm_service_name;
  -- RAISE_APPLICATION_ERROR (num=> -20111, msg=> v_msg);
WHEN OTHERS THEN
  -- Let's report a problem in the alert log if there is an unhandled exception note: 2 = write to the alert log
  dbms_system.ksdwrt(2, 'ORA-20042: AFTER LOGON trigger SERV_LOGON_MON failed with an error: '||SQLERRM);
END;