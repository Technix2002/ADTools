Function Remove-AD {
<#
.SYNOPSIS
To delete user or group in Active Directory or remove from Active Directory Groups

.DESCRIPTION
Yes, you could use Remove-ADuser or Remove-ADGroup...
However, this removes a user account or group from the domain that account is in by looking through all domains in the Forest first

.PARAMETER user
Input user name in a number of formats:
FirstLast
"First Last"
"Last, First MiddleInitial"

.PARAMETER property
"all" to delete user from groups and the domain
"groups" to remove user from all groups

.PARAMETER Office365
To also remove user from Office 365

.PARAMETER group
Input group name without any parameters to delete the group

.PARAMETER members
Provide a single user or list separated by commas
This is only used in conjunction with the group parameter
Only removes user(s) from a group

.EXAMPLE
Remove-AD -user FirstLast -property all
Remove-AD FirstLast all

'First Last','FirstLast2','Name,HRformat' | Remove-AD -property all
^ All examples of removing users from domain ^

.EXAMPLE
Remove-AD FirstLast groups
^ Remove provided user from all groups ^

.EXAMPLE
Remove-AD -group GroupName -member FirstLast
^ To remove a user(s) from a group ^

.EXAMPLE
Remove-AD -group GroupName
^ To remove a group from the domain ^

.NOTES
Author = Brad Lape
Role = Associate Windows Systems Administrator
Company = RackSquared
Module = ADtools
Total Cmdlets = 4
This Cmdlet = Remove-AD
#>
                 [CmdletBinding()]
                 Param (
                        [parameter(position=0,ValueFromPipeline,ParameterSetName='user')]
                        [string]$user,
                        [parameter(position=1,ValueFromPipeline,ParameterSetName='groups')]
                        [string[]]$groups,
                        [ValidateSet('all','groups')]
                        [parameter(position=2,ParameterSetName='user',mandatory='yes')]
                        [string]$property,
                        [parameter(position=3,ParameterSetName='groups')]
                        [string[]]$members,
                        [parameter(position=4,ParameterSetName='user')]
                        [switch]$Office365
                        )
Begin {
       $domains = (Get-ADForest).domains
       $now = (get-date).ToString('MM/dd/yyyy HH:mm:ss')
       }
Process {
        If ($user) {
                    clv adinfo -Force -ErrorAction SilentlyContinue
                    $ErrorActionPreference = 'SilentlyContinue'
                    $adinfo = Find-AD -user $user
              
                    If (!$adinfo) {
                                   $ErrorActionPreference = 'Continue'
                                   clv adinfo -Force -ErrorAction SilentlyContinue
                                   Throw "$user not found, try FirstLast / FLast / ""Last, FirstM"" / email"
                                   break
                                   }  

                    Switch ($property) {
                                        all {
                                             Foreach ($domain in $domains) {
                                                                            $adinfo.MemberOf | %{Remove-ADGroupMember -Server $domain -Identity "$_" -Members $adinfo.SamAccountName -Verbose -Confirm:$false -PassThru}
                                                                            }
                                             If ($Office365) {O365remove $adinfo.UserPrincipalName}
                                             Remove-ADobject $adinfo.distinguishedname -Recursive -server ($adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}) -Confirm:$false -Verbose -ErrorVariable toerr
                                             $prop = 'DisplayName'
                                             }
                                        groups {
                                                Foreach ($domain in $domains) {
                                                                               $adinfo.MemberOf | %{
                                                                                                    Remove-ADGroupMember -Server $domain -Identity "$_" -Members $adinfo.SamAccountName -Verbose -Confirm:$false -PassThru
                                                                                                    }
                                                                               }
                                                $groups = $adinfo.MemberOf -join "`r`n"
                                                Set-ADUser -Server ($adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}) -Identity $adinfo.SamAccountName -Replace @{info="$($adinfo.info)`n Removed from groups $groups by $env:USERNAME on $now"}
                                                $prop = 'MemberOf'
                                                clv groups -Force -ErrorAction SilentlyContinue
                                                }     
                                        } 

                    $ErrorActionPreference = 'Continue'
                    If ($toerr) {$toerr}
                                       Else {
                                             ''
                                             If ($property -match 'all') { Write-Host 'Verifying that' ($adinfo.SamAccountName) 'was removed from' ($adinfo.CanonicalName -Replace ('/.+$'))':' -ForegroundColor DarkYellow }
                                             ''
                                             get-aduser -server ($adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}) -Identity $adinfo.SamAccountName -Properties info | Select-Object -ExpandProperty info
                                             ''
                                             If ($property -match 'groups') {
                                                                             $leftovers = get-aduser -server ($adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}) -Identity $adinfo.SamAccountName -Properties $prop | Select-Object -ExpandProperty $prop
                                                                             If ($leftovers.Count -ge '1') {
                                                                                                            Write-Host 'Manually remove from the following Groups:' -ForegroundColor Yellow
                                                                                                            $leftovers
                                                                                                            }
                                                                             clv leftovers -Force -ErrorAction SilentlyContinue
                                                                             ''
                                                                             }
                                                                             Else {
                                                                                   get-aduser -server ($adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}) -Identity $adinfo.SamAccountName -Properties $prop | Select-Object -ExpandProperty $prop
                                                                                   }
                                             
                                             }
                    clv user,adinfo,prop,toerr -Force -ErrorAction SilentlyContinue
                    }
                    ElseIf ($groups) {
                                      Foreach ($group in $groups) {
                                                                   $DN = Find-ADgroup -group "$group" -property DN
                                                                   If (($DN) -and (!$members)) { Remove-ADGroup -Server $domain -Identity "$DN" -Confirm:$flase -Verbose }
                                                                                                                                                                         ElseIf (($DN) -and ($members)) {
                                                                                                                                                                                                         Foreach ($member in $members) {
                                                                                                                                                                                                                                        $adinfo = Find-AD -user "$member"
                                                                                                                                                                                                                                        Remove-ADGroupMember -Identity "$DN" -Members $adinfo -Confirm:$false -Verbose
                                                                                                                                                                                                                                        clv adinfo -Force -ErrorAction SilentlyContinue
                                                                                                                                                                                                                                        }
                                                                                                                                                                                                         }
                                                                                                                                                                                                         ElseIf (!$DN) {
                                                                                                                                                                                                                        clv adinfo,domains -Force -ErrorAction SilentlyContinue
                                                                                                                                                                                                                        $ErrorActionPreference = 'Continue'
                                                                                                                                                                                                                        Throw "$group not found, try Display Name / Name / Distinguished Name"
                                                                                                                                                                                                                        break 
                                                                                                                                                                                                                        }                                                                                                                                                                                            
                                                                }
                                 }

                }
End {
     clv adinfo,aduser,domains,now -Force -ErrorAction SilentlyContinue
     Invoke-Command -ComputerName dirsync.wasserstrom.com  -ScriptBlock {Start-ADSyncSyncCycle -PolicyType Delta}
     # end of Function
     }
                }