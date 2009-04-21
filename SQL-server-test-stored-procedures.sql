-- Testsuite for poshcodegen: SQL-Server Stored procedures
-- developed using SQL Server 2008, I hope it runs as well with 2000 and 2005
-- Bernd Kriszio 2009-04-21

-- Please add further test procedures as needed, but don't change existing ones
-- These Procedures do not depend on database state (but partially on actual time)

------------ Test 1: noparm_recordset, no parameters, Result as Recordset ---------------
if OBJECT_ID('noparm_recordset') > 0
	drop procedure noparm_recordset
go

create procedure dbo.noparm_recordset  as
	select @@version SQL_Version
go

------------- Test 2: noparm_recordset, no Parameters, result via Print -----------------------
if OBJECT_ID('noparm_print') > 0
	drop procedure noparm_print
go

create procedure dbo.noparm_print  as
	print @@version 
go

------------- Test 3: noparm_recordset, no Parameters, result via returnvalue -----------------------
if OBJECT_ID('noparm_retval') > 0
	drop procedure noparm_retval
go

create procedure dbo.noparm_retval  as
	-- SELECT SERVERPROPERTY('productversion') as ProductVersion
	declare @versionstring varchar(255)
	declare @version int
	SET @versionstring  = cast (SERVERPROPERTY('productversion') as varchar)
	SET @version = cast (left (@versionstring, CHARINDEX ('.', @versionstring) - 1) as int)
	return @version
go

/*
declare @version int
execute @version = noparm_retval 
Select @version
*/

-- noparm_print

------------- Test 4: noinparm_outparm, no inParameters, result via out parameter -----------------------
if OBJECT_ID('noinparm_outparm') > 0
	drop procedure noinparm_outparm
go

create procedure dbo.noinparm_outparm (
	@version  varchar(255) out
)as
	SET @version = @@Version
go

declare @rc varchar(255)
exec noinparm_outparm @rc out
select 'The version  is' = @rc


------------- Test 5a: 1 in parm set, result as recordset -----------------------
------------- Test 5b: 1 in parm null, result as recordset -----------------------

if OBJECT_ID('echodate') > 0
	drop procedure echodate
go

create procedure dbo.echodate (
	@dt datetime = null
) as
	select isnull(@dt, getdate()) result
go

-- echodate '20000101'
-- echodate

------------- Test 6: 3 in parms, result as resultset -----------------------


if OBJECT_ID('add3ints') > 0
	drop procedure add3ints
go

create procedure dbo.add3ints (
	@sum1 int,
	@sum2 varchar(10),
	@dt datetime
) as
	print 'dies ist ein Test'
	select @sum1 result
	union all
	select cast (@sum2 as integer )
	union all
	select ISNULL( @sum1, 0) + ISNULL(@sum2, 0)
	union
	select MONTH(@dt)
    return 1007
    
go

declare @now datetime set @now = getdate()
declare @rc int
exec @rc = add3ints 2, '3', @now
select 'The return code is'=@rc

