

#use the old net localgroup command to get members of the local Administrators group, then parse the text output, excluding the built-in Administrator user and Domain Admins group
$LocalAdmins = net localgroup administrators| where {$_ -and $_ -notmatch "command completed successfully" -and $_ -notmatch '^Administrator$'} | select -skip 4

#Convert the text to an array
$LocalAdmins = $LocalAdmins.Split([Environment]::NewLine) | ? { $_ -ne "" }

#Example of looping through the array
foreach ($user in $LocalAdmins) {
  Write-Host "Removing $user from local Administrators group"
    if ($env:dryRun) {
    Remove-LocalGroupMember -Group "Administrators" -Member $user -WhatIf
  } else {
    Remove-LocalGroupMember -Group "Administrators" -Member $user
  }
}