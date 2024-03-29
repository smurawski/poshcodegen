# 1. cd to the project directory
# 2. $connet_string = 'your connect string'


# ------------------------------------ Test 1 no parameter returns Resultset -------------------------------------------------

.\New-StoredProcFunction.ps1 $connet_string noparm_recordset

(noparm_recordset).tables[0]

# ------------------------------------ Test 2 no parameter  result by print -------------------------------------------------

.\New-StoredProcFunction.ps1 $connet_string noparm_print

noparm_print

# ------------------------------------ Test 3 no parameter  result by return value -------------------------------------------------

.\New-StoredProcFunction.ps1 $connet_string noparm_retval

noparm_retval

# ------------------------------------ Test 4 no in parameter  result via out parameter -------------------------------------------------

.\New-StoredProcFunction.ps1 $connet_string noinparm_outparm

noinparm_outparm

# ------------------------------------ Test 5  1 in  parameter  result as record set -------------------------------------------------
# ------------------------------------ Test 5a  parameter set -------------------------------------------------
# ------------------------------------ Test 5a  parameter $null -------------------------------------------------

.\New-StoredProcFunction.ps1 $connet_string echodate

(echodate (get-date 2000-01-01)).tables[0]

(echodate $null).tables[0]

# ------------------------------------ Test 6  3 in  parameter  result as record set, print and return  -------------------------------------------------

.\New-StoredProcFunction.ps1 $connet_string add3ints

(add3ints 1 2 $null).tables[0]
(add3ints 1 $null $null).tables[0]

(add3ints 1 '2' (get-date)).tables[0]
(add3ints $null $null (get-date)).tables[0]

$res = (add3ints 2 3 (get-date))
$res.tables[0]
write-Host "ReturnValue: $($res.ReturnValue)"

