# Bernd kriszio  http://pauerschell.blogspot.com/  2009-04-23
# Start of Oracle adaption

# to hide your true accounts and passwords put something like this in your profile, and the scripts can run unmodified
# $oracle_connet_string =  'Data Source=your_tns;User Id=scott;Password=tiger;Integrated Security=no' 

  
# -------------------------------------------------------------------------------------------

# Invoke-OraQuery "select 1 from dual"
# Invoke-OraQuery "select  from dual"
# Invoke-OraQuery "select OBJECT_NAME from user_objects where OBJECT_TYPE = 'PROCEDURE' ORDER BY 1"

# --- find the name of a stored procedure
# Invoke-OraQuery "select OBJECT_NAME from user_objects where OBJECT_TYPE = 'PROCEDURE' AND ROWNUM = 1"

<#
# --- and now find its parameters
$proc_name = (Invoke-OraQuery "select OBJECT_NAME from user_objects where OBJECT_TYPE = 'PROCEDURE' AND ROWNUM = 1").Object_name
Get-FunctionParameter $proc_Name
#>


# generating an error
# Invoke-OraQuery "select 1 / 0 from DUAL"


# this works for me

[System.Reflection.Assembly]::LoadWithPartialName("Oracle.DataAccess")
[System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient")

function Invoke-OraQuery()
{
    [cmdletbinding()]
	param (
        [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$false)]        
    $Query,
        [Parameter(Position=2,  Mandatory=$false, ValueFromPipeline=$false)]        
    $ConnectionString = $oracle_connet_string

    )
	$connection = New-Object System.Data.OracleClient.OracleConnection $connectionString
    #$handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {Write-Host "$($_)" }
    #$connection.add_InfoMessage($handler)
	$command = New-Object System.Data.OracleClient.OracleCommand $query, $connection
	$connection.Open()
	$adapter = New-Object System.Data.OracleClient.OracleDataAdapter $command
	$dataset = New-Object System.Data.DataSet
	[void] $adapter.Fill($dataSet)
	$result = $dataSet.Tables | Select-Object -ExpandProperty Rows
	$connection.Close() 
	return $result
}

#-------------------------------------------------------------------
#Utility Functions
	
function Get-FunctionParameter()
{
    [cmdletbinding()]
    param(
        [Parameter(Position=1, Mandatory=$True, ValueFromPipeline=$false)]        
        $FunctionName, 
        [Parameter(Position=2,  Mandatory=$false, ValueFromPipeline=$false)]        
        $ConnectionString = $oracle_connet_string
    )
    # the following query requires SQL-Server 2005 and better
	$query = @"
SELECT ARGUMENT_NAME parameter_Name, DATA_TYPE data_type, null character_maximum_length, in_out parameter_mode
FROM USER_ARGUMENTS
WHERE OBJECT_NAME = '$FunctionName'
AND PACKAGE_NAME is NULL
ORDER BY POSITION
"@
	$Rows = Invoke-OraQuery $Query $ConnectionString
	$Parameters = @()
    if ($rows -ne $null)
    {
		foreach ($Row in $Rows)
		{
			$Parameter =  New-Object PSObject  
			$Parameter | Add-Member -Name FullName -Value $row.parameter_Name -MemberType NoteProperty
			$Parameter | Add-Member -Name ShortName -Value $($row.parameter_Name -replace '@') -MemberType NoteProperty
			$Parameter | Add-Member -Name DataType -Value $Row.data_type -MemberType NoteProperty
			$Parameter | Add-Member -Name Length -Value $Row.character_maximum_length -MemberType NoteProperty
			$Parameter | Add-Member -Name IsOutput -Value $(if ($Row.parameter_mode -eq 'INOUT'){$true} else {$false}) -MemberType NoteProperty

			$Parameters += $Parameter
		}
    }
	return $Parameters
}

