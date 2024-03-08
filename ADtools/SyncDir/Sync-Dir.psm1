<#
.SYNOPSIS
To Sync Active Directory with Azure

.DESCRIPTION
Yes, you could just type out the whole command every time or run a script...
But.. this makes it real easy

.EXAMPLE
Sync-Dir

.NOTES
Author = Brad Lape
Role = Associate Windows Systems Administrator
Company = RackSquared
Module = ADtools
Total Cmdlets = 4
This Cmdlet = Sync-Dir
#>

Function Sync-Dir {
Invoke-Command -ComputerName Your-OnPremise-AADserver  -ScriptBlock { Start-ADSyncSyncCycle -PolicyType Delta }
}