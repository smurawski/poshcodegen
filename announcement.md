what to expect in the next weeks
# Introduction #
  * Oracle using Oracle.DataAccess
  * Oracle using System.Data.OracleClient
  * Redesign into a PowerShell Module
  * many optional parameters
  * database sessions


# Details #

  * Adaption to Oracle using Oracle.DataAccess
> Baics are ready, including extracting parameter types. Todo catching server output.

  * Adaption to Oracle using System.Data.OracleClient
> Perhaps, I don't use this myself.

  * General redesign of New-StoredProcFunction.ps1 into a PowerShell Module. We can save state like connecting strings and open connections within a module.

  * $ConnectionString becoming a module variable an optional parameter in function calls. In praxis I want to use it, where i used Query Analyzer or SQL\*Plus.   I want to switch  on the fly not only between databases on the same server but between different servers too. in some cases (depending on strict conventions) even between different RDBMS types.

  * support for database sessions
> Nice to have. Perhaps we do it.