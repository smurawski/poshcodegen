-- Testsuite for poshcodegen: Oracle Stored procedures
-- developed using Oracle 9i and 10g, I use SQL*Plus 
-- Bernd Kriszio 2009-04-25

-- Please add further test procedures as needed, but don't change existing ones
-- These Procedures do not depend on database state (but partially on actual time)

set serveroutput on size 1000000

------------ Test 1: noparm_recordset, no parameters, Result as Recordset ---------------

create or replace procedure noparm_recordset (
    rc_1 in out SYS_REFCURSOR
) as
begin
    Open rc_1 for
	SELECT * FROM product_component_version ;
end;
/

var r refcursor
exec noparm_recordset(:r)
print r
 
------------- Test 2: noparm_print, no Parameters, result via Print -----------------------
create or replace procedure noparm_recordset 
as
    v_product varchar2(255);
begin
	SELECT Product into v_product FROM product_component_version where product like 'Oracle%' ;
    dbms_output.put_line ('Using  dbms_output: ' || v_product );
end;
/

exec noparm_recordset

------------- Test 3: noparm_retval, no Parameters, result via returnvalue -----------------------

create or replace function noparm_retval  
	RETURN varchar2
as
    v_product varchar2(255);
begin
	SELECT Product into v_product FROM product_component_version where product like 'Oracle%' ;
	return v_product;
end;
/


select noparm_retval() from dual;



------------- Test 4: noinparm_outparm, no inParameters, result via out parameter -----------------------

create or replace procedure noinparm_outparm (
	o_version  out varchar(255)
)as
    v_product varchar2(255);
begin
	SELECT Product into o_version FROM product_component_version where product like 'Oracle%' ;
end;
/

declare @rc varchar(255)
exec noinparm_outparm @rc out
select 'The version  is' = @rc


------------- Test 5a: echodate 1 in parm set, result as recordset -----------------------
------------- Test 5b: echodate 1 in parm null, result as recordset -----------------------

create or replace procedure echodate (
    rc_1 in out SYS_REFCURSOR
	,p_dt date := null
) as
begin
    Open rc_1 for
    	select NVL(p_dt, SYSDATE) result from DUAL;
end;
/

var r refcursor
exec echodate (:r, TO_DATE('20000101', 'yyyyMMdd'))
print r


var r refcursor
exec echodate (:r)
print r

------------- Test 6: add3ints 3 in parms, result as resultset -----------------------


create or replace function add3ints (
    rc_1 in out SYS_REFCURSOR
	,p_sum1 NUMBER
	,p_sum2 varchar2
	,p_dt date
) 
	RETURN varchar2
as
begin
    dbms_output.put_line ('dies ist ein Test');
    Open rc_1 for
	select p_sum1 result from DUAL
	union all
	select cast (p_sum2 as integer ) from DUAL
	union all
	select NVL( p_sum1, 0) + NVL(p_sum2, 0) from DUAL
	union
	select To_Number(To_char(p_dt, 'MM')) from DUAL;
    return 'PowerShell rocks';
end;
/

var r refcursor
DECLARE return_value varchar2(255);
BEGIN
    return_value :=  add3ints(:r, 1, '2', null);
    dbms_output.put_line('return_value = '||TO_CHAR(return_value));END;
/
print r


