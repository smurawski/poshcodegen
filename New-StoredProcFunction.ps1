# New-StoredProcFunction.ps1
# Steven Murawski
# http://blog.usepowershell.com
# 04/08/2009
# Replaced the parsing of the stored procedure text and use Information_Schema.Parameters to get the parameter information
# Thanks to Chad Miller ( http://chadwickmiller.spaces.live.com/blog/ ) for the idea.
# 04/09/2009
# Refactored much of the code to create a number of helper functions
# Scriptblock for the function is now build from a here string to increase readability
# Thanks to Doug Finke for the suggestions ( http://dougfinke.com/blog )
# Specifically http://dougfinke.com/blog/index.php/2009/03/18/powershell-dsl-for-deploying-biztalk-applications/
# 

 
# Example: ./New-StoredProcFunction.ps1 'Data Source=MySqlServer;Database=Northwind;User=AnythingButSa;Password=abc123' sp_createnewcustomer
# Example 'sp_createnewcustomer | ./New-StoredProcFunction.ps1 'Data Source=MySqlServer;Database=Northwind;User=AnythingButSa;Password=abc123'

param($ConnectionString= 'Data Source=204.75.136.26; Initial Catalog=JustWare; User=sa; Password=newjersey;'
	, [String[]]$StoredProc= $null)
	
begin
{
	#Push stored proc names supplied as a parameter through the pipeline
	#to provide better pipeline support
	if ($StoredProc.count -gt 0)
	{
		$StoredProc | c:\scripts\powershell\new-storedprocfunction.ps1 $ConnectionString
	}
	
	#-------------------------------------------------------------------
	#Utility Functions
	
	function Invoke-SQLQuery()
	{
		param ($ConnectionString, $Query)
		$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
		$command = New-Object System.Data.SqlClient.SqlCommand $query,$connection
		$connection.Open()
		$adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
		$dataset = New-Object System.Data.DataSet
		[void] $adapter.Fill($dataSet)
		$result = $dataSet.Tables | Select-Object -ExpandProperty Rows
		$connection.Close() 
		return $result
	}
	function Get-FunctionParameter()
	{
		param($FunctionName, $ConnectionString)
		$query = @"
SELECT parameter_Name, data_type, character_maximum_length, parameter_mode
FROM INFORMATION_SCHEMA.Parameters
WHERE specific_NAME LIKE '$FunctionName'
"@
		$Rows = Invoke-SQLQuery $ConnectionString $Query 
		
		$Parameters = @()
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
		return $Parameters
	}
	function ProcessAllParameter()
	{
		param ([psobject]$Parameter)
		if ($Parameter.length -isnot [DBNull])
		{
			$ParamTemplate = '$command.Parameters.Add("{0}", [Data.SqlDBType]::{1}, {2})  | out-null ' -f $Parameter.Fullname, $Parameter.datatype, $Parameter.length
		}
		else
		{
			$ParamTemplate = '$command.Parameters.Add("{0}", [Data.SqlDBType]::{1})  | out-null ' -f $Parameter.fullname, $Parameter.datatype				
		}
		return $ParamTemplate
	}
	function ProcessInputParameter()
	{
		param ([psobject]$Parameter)
		
		$script:InputParameterList += $Parameter.ShortName
		
		$script:InputParameters += "`n"
		$script:InputParameters += ProcessAllParameter $Parameter
		$script:InputParameters += "`n" 
		$script:InputParameters += 'if (${0} -ne $null) ' -f $Parameter.ShortName
		$script:InputParameters += "`n { " 
		$script:InputParameters += '$command.Parameters["{0}"].Value = ${1} ' -f $Parameter.fullname, $Parameter.ShortName
		$script:InputParameters += " }`nelse { " 
		$script:InputParameters += ' $command.Parameters["{0}"].Value = [DBNull]::Value ' -f $Parameter.fullname
		$script:InputParameters += " }`n" 
	}
	function ProcessOutputParameter()
	{
		param ([psobject]$Parameter)
		$script:OutputParameters += ProcessAllParameter $Parameter
		$script:OutputParameters += "`n"
		$script:OutputParameters += '$command.Parameters["{0}"].Direction = [System.Data.ParameterDirection]::Output ' -f $Parameter.FullName
		$script:OutputParameters += "`n"
		$script:OutputParametersReturn += '$CommandOutput | Add-Member -Name {1} -Value $command.Parameters["{0}"].Value -MemberType NoteProperty' -f $Parameter.FullName, $Parameter.ShortName
		$script:OutputParametersReturn += "`n"
	}
	function ProcessParameters()
	{
		param ([psobject[]]$Parameters)
		
		foreach ($Parameter in $Parameters)
		{
			if ($Parameter.IsOutput)
			{
				ProcessOutputParameter $Parameter
			}
			else 
			{
				ProcessInputParameter $Parameter
			}
		}
	}
	function StandardCode()
	{
		param ($ConnectionString, $FunctionName)

		$CreateStoredProc = @'
$connection = New-Object System.Data.SqlClient.SqlConnection('{0}')
$command = New-Object System.Data.SqlClient.SqlCommand('{1}', $connection)
$command.CommandType = [System.Data.CommandType]::StoredProcedure
'@
		$script:CreateStoredProcCode = $CreateStoredProc -f $ConnectionString, $FunctionName
		
	}
	function CreateFunctionParameterStatement()
	{
		param ($InputParameterList)
		
		if ($InputParameterList.count -gt 0)
		{
			$OFS = ', $'
			$text = 'param (${0})' -f $InputParameterList
			$OFS = ','
			return $text
		}
	}
}
PROCESS
{
	if ($_ -ne $null)
	{
		$FunctionName = $_
		$InputParameterList = @()
		$InputParameters = ""
		$OutputParameters = ""
		$OutputParametersReturn = ""
		$CreateStoredProcCode = ""
		
		$OpenConnectionAndRun = @'
$connection.Open()  | out-null
$adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
$dataset = New-Object System.Data.DataSet
[void] $adapter.Fill($dataSet)
#$command.ExecuteNonQuery()
$connection.Close() | out-null

$CommandOutput = New-Object PSObject
$CommandOutput | Add-Member -Name Tables -Value $dataSet.Tables -MemberType NoteProperty
'@

		$Return = @'
return $CommandOutput 
'@


		$Parameters = Get-FunctionParameter $FunctionName $ConnectionString
		ProcessParameters $Parameters
		
		StandardCode $ConnectionString $FunctionName
		$ParameterDeclaration = CreateFunctionParameterStatement $InputParameterList
		
		#Build the function text
		$FunctionText = @"
#Input Parameters
$ParameterDeclaration

#Set up .NET code for calling stored proc
$CreateStoredProcCode

#Set up Stored Proc parameters
$InputParameters
$OutputParameters

#Run
$OpenConnectionAndRun

#Set output parameters
$CreateOutputObject
$OutputParametersReturn

#Close the connection and return the output object	
$Return
"@
		
		Set-Item -Path function:global:$FunctionName -Value $FunctionText
		Write-Verbose "Created function - $FunctionName"
	}
}
