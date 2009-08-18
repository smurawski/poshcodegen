# ADO.NET
# http://msdn.microsoft.com/de-de/library/system.data.sqlclient.sqlcommand.parameters(VS.80).aspx
# http://decipherinfosys.wordpress.com/2007/08/29/bind-variables-usage-parameterized-queries-in-sql-server/

# static
# http://stackoverflow.com/questions/544804/powershell-how-do-you-add-a-property-to-a-function-object-on-the-psdrive-functio/546107#546107
function Invoke-SQLQuery()
{
 <# 
.SYNOPSIS 
    Execute SQL-quries using SQLClient    
.DESCRIPTION 
    Execute SQL-blocks. That's what is delimites by the go-statements, if you use Query-Analyzer
    or SQL-Management-Studio. Note go is NO SQL statement. It's just a command of those tools.
    Currently each Invoke-SQLQuery uses its own connection. That means Session settings within one call.
    For example setting datefirst to you local prefernces, have no influence to the following calls.
    
    The enforeced use of connectionless database queries corresponds with the increasing use of web-interfaces.
    
    It is not the best in every cases and I will try to extend the use of this function to opened connections.
    This depends on the transition of this code into a module.
          
.NOTES 
    File Name  : sql_dblayer.ps1 
    Author     : Bernd Kriszio - http://pauerschell.blogspot.com/ 
.LINK 
    http://code.google.com/p/poshcodegen - this is the project to which I contribute the database stuff
    http://www.codeplex.com/psisecream -  some ways to extract database stuff into ISE-Tabs can be found here
    
.PARAMETER Query
    This can be any batch of DDL (Create ...) or DML (select ... Insert .... Update ... Delete ...)
    Statements. Settings (Set ...) and Print ... work as well. You can even use comments if you like.
    But once again. 'go' is no SQL-Statement i's an artefact to cut the batch of statements in pieces, which
    are invoked in a single run.
.PARAMETER Query
    You can send each query to a different database is you like.
    If you are as lazy as I'm you set $sql_connect_string to your default SQL-Server connection String
.ReturnValue
    tables[]
    
    Using Command Text Mode you get a collection of resultsets. ADO.NET calles them tables
    The output of Print Statements is caught and output via Write-Host.
    I don't know if that's the final choise.
    Print statements are good for ad hoc testing.
    But perhaps I'm outing me here as hardcore 'printf'-user from the paehistoric age of unix.
    If you want to interface your database using some programming language. (NOTE PowerShell is one of them),
    better don't rely on using print. You don't allways get the output immediately. 
    
.EXAMPLE 
    Invoke-SQLQuery "select @@SERVERNAME + '.'+ db_name(0) [Current Default SQL-Server Database]"
.EXAMPLE
    # execute the following statements one by one to see both results
    # if you select the following 3 lines anf hit F6 you see only the first result 
    # seems to be one of those 'by design issues', which drive me crazy
    $res = 'Select 1 A_Numer ', 'Select 2 Eine_Zahl' | Invoke-SQLQuery
    $res[0]
    $res[1] 
        
#> 
   [cmdletbinding()]
	param (
        [Parameter(Position=1, Mandatory=$True, ValueFromPipeline=$True)]        
        $Query,
        [Parameter(Position=2,  Mandatory=$False, ValueFromPipeline=$false)]        
        $ConnectionString = $sql_connect_string

    )
    PROCESS
    {
        if ($ConnectionString -eq $null)
        {
            Write-Host "Please set `$sql_connect_string or supply `$ConnectionString parameter" 
        }
        else
        {
        	$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
            
            # the following code is for catching the output of PRINT statements
            $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {
                # it's funny if you write it to a file you get even a line number
                # perhaps some MVP will tell, why you don't get it via Write-Host
                # But honestly don't overuse SQL Print-Statements  
                #Out-File -I $_.Message -File 'I:\googlecode\poshcodegen\trunk\log.txt'
                #Out-File -I $_.Errors -File 'I:\googlecode\poshcodegen\trunk\log.txt' -A
                Write-Host $_
    #             Write-Host "Errors: $($_.Errors)"
    #             Write-Host "Message: $($_.Message)"
    #             Write-Host "Source: $($_.Source)"
    #             Write-Host "lineNumber $($_.LineNumber)"
    #             Write-Host ($_ | fl)
                 }
                 
            $connection.add_InfoMessage($handler)
        	$command = New-Object System.Data.SqlClient.SqlCommand $query, $connection
            # Text is the default CommandType you need not set it explicitly
            # using CommandType Text you can do nearly everthing
            # but not allways in the most perfomant ways.
            # I'm reflecting about renaming this function to Invoke-SQLText
            # Perhaps if I expose Invoke-SQLScalar or Get-SQLScalar
            #$command.CommandType = [System.Data.CommandType]::Text
        	$connection.Open()
        	$adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
        	$dataset = New-Object System.Data.DataSet
        	[void] $adapter.Fill($dataSet)
        	$result = $dataSet.Tables | Select-Object -ExpandProperty Rows
        	$connection.Close()
        	return $result
        }
    }
}

function New-Connection ($connectionString)
{
    $global:connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {Write-Host "$($_)" }
    $connection.add_InfoMessage($handler)
    $global:command = $null
    $connection.Open()  | out-null

}


function Close-Connection
{
    $global:connection.Close() | out-null
    $global:command = $null
}

$global:commands = @{}

function New-InsertStatement
{
    [cmdletbinding()]
    param ($table_name, $columns , $defaults, $comment, [switch]$fillNulls )

	$query = @" 
select COLUMN_NAME, 
    -- ORDINAL_POSITION, 
    IS_NULLABLE, 
    DATA_TYPE, 
    -- CHARACTER_MAXIMUM_LENGTH, 
    COLUMNPROPERTY(object_id(TABLE_NAME), COLUMN_NAME, 'IsIdentity') has_identity
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = '$table_name'
ORDER BY ORDINAL_POSITION
"@


	$Rows = Invoke-SQLQuery $Query $sql_connect_string
    #if ($fillNulls){ 'fillNulls is on' } else { 'fillNulls is off' }
    
    $functionName = "I-" + $table_name
    
    $parms = ($columns  | % {"`$$($_)" } ) -join ", `r`n           "
    
    $columnList = ($rows |% {$_.COLUMN_Name}) -join ", "
    
    $ValueList =  ($rows |% {
        if ($columns -contains $_.COLUMN_Name ) {
            '@' + $_.COLUMN_Name
        }elseif ($defaults.keys -contains $_.COLUMN_Name){
             $defaults[$_.COLUMN_Name]
        }else{ # -- todo else null or if not nullable 0, '', ' '
            'null'
        }
    }) -join ", "
    
    $SetParameter = ($columns |% { "`$command.Parameters['@$($_)'].Value = `$$($_)" }) -join "`r`n"
    
    $AddParameter = ($rows |%{ 
        $col = $_.COLUMN_Name
        $type = $_.DATA_TYPE
        if ($columns -contains $col)
        {
            # -- todo further types ----
            if ($type -eq 'varchar') {
                $type = 'String'
            }elseif (('bit', 'smallint') -contains $type)
            {
                $type = 'int'
            }
            "`$command.Parameters.Add('@$col', [Data.SqlDBType]::$Type)  | out-null " 
        }
    } ) -join "`r`n             "
    
    $functionText = @"
    param ($parms)

if (! `$commands['$functionName'])
{
    Write-Host 'initializing...'

    #set up querry
    `$query = "Insert into  $table_name ($columnList) 
    Select $valueList"

    `$command = New-Object System.Data.SqlClient.SqlCommand(`$query, `$connection)
    `$command.CommandType = [System.Data.CommandType]::Text

    #Set up parameters

    $AddParameter 

    #`$connection.Open()  | out-null
    `$commands['$functionName'] = `$command
}
else
{
    # Write-Host 'Reusing...'
    `$command = `$commands['$functionName']
}


$SetParameter

`$command.ExecuteNonQuery() | Out-Null

"@
    
    Write-Verbose $FunctionText
    
    Set-Item -Path function:global:$FunctionName -Value $FunctionText
}
