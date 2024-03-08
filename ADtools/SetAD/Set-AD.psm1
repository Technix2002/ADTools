# to edit AD properties for a user
Function Set-AD {
<#
.SYNOPSIS
To set user's information in Active Directory

.DESCRIPTION
Yes, you could use Set-ADuser...
However, this searches across all domains in the Forest to set user's account information easily

.PARAMETER user
Input user name in a number of formats:
FirstLast
"First Last"
"Last, First MiddleInitial"

.PARAMETER property
"company" sets company information about a user
"department" sets department information about a user
"description" sets description information about a user
"disable" set account to disabled & coupled with "indays" to set to occur in X days (time is set for 5:01pm)
"displayname" sets Display Name information about a user
"email" sets email address of user
"extension" sets telephone extension number of user
"first" sets first name of user
"groups" adds a user to a group(s)
"HRname" sets UltiPro user name
"ID" sets Employee ID of user
"manager" sets manager of user
"MobileTN" sets mobile telephone number of user
"office" sets office location of user
"Sam" sets Sam Account Name of user
"title" sets title of user
"UPN" sets Universal Principlay Name of user
"UltiProID" sets UltiPro ID of user

.EXAMPLE
Set-AD -user FirstLast -property first -value firstname
Set-AD FirstLast first firstname

'First Last' | Set-AD -property first -value firstname

.EXAMPLE
Set-AD FirstLast manager "Mr Manager"
'First Last','FirstLast2','Name,HRformat' | Set-AD -property manager -value "Mr Manager"

.EXAMPLE
Set-AD FirstLast groups IMMA-Group-1,IMMA-Group2,IMMA-Group3

.EXAMPLE
Set-AD FirstLast disable -indays 7

.NOTES
Author = Brad Lape
Role = Associate Windows Systems Administrator
Company = RackSquared
Module = ADtools
Total Cmdlets = 4
This Cmdlet = Set-AD
 #>
                 [CmdletBinding()]
                 Param (
                        [parameter(position=0,ValueFromPipeline,mandatory='yes')]
                        [string]$user,
                        [ValidateSet('company','department','description','disable','displayname','email','extension','first','groups','HRname','ID','manager','MobileTN','office','Sam','state','title','UPN','UltiproID')]
                        [parameter(position=1,mandatory='yes')]
                        [string]$property,
                        [parameter(position=2,ValueFromPipeline)]
                        [string[]]$value = $null,
                        [int]$indays = $null,
                        [string]$ticket
                        )

Begin {
       $domains = (Get-ADForest).domains
       $now = (get-date).ToString('MM/dd/yyyy HH:mm:ss')
       $audit = (get-date).ToString('yy/MM/dd')
       }
Process {
clv adinfo -Force -ErrorAction SilentlyContinue
$ErrorActionPreference = 'SilentlyContinue'
$adinfo = Find-AD -user "$user"            

If (!$adinfo) {
               $ErrorActionPreference = 'Continue'
               clv domains,adinfo -Force -ErrorAction SilentlyContinue
               Throw "$user not found, try FirstLast / FLast / ""Last, FirstM"" / email"
               break
               }  

Switch ($property) {
                    company {
                             $prop = 'Company'
                             }
                    department {
                                $prop = 'Department'
                                }
                    description {
                                 $prop = 'Description'
                                 }
                    disable {
                             If ($indays) { 
                                           Set-ADAccountExpiration -Server ($adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}) -Identity $adinfo.SamAccountName -DateTime (get-date -Hour 17 -Minute 01 -Second 00).AddDays($indays).ToString('MM/dd/yyyy HH:mm:ss') -Confirm:$false -Verbose -ErrorVariable toerr
                                           Set-ADUser -Server ($adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}) -Identity $adinfo.SamAccountName -Replace @{info="Account expiration set by $env:USERNAME on $now"}
                                           $prop = 'AccountExpirationDate'  
                                           }
                                           Else {
                                                 $prop = 'enabled'
                                                 $value = $False
                                                 Disable-ADAccount -Server ($adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}) -Identity $adinfo.SamAccountName -Confirm:$false -Verbose -ErrorVariable toerr
                                                 Set-ADUser -Server ($adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}) -Identity $adinfo.SamAccountName -Replace @{info="Account disabled set by $env:USERNAME on $now"}
                                                 Set-ADUser -Server ($adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}) -Identity $adinfo.SamAccountName -Description "$audit - $ticket by $env:USERNAME" -Confirm:$false -ErrorVariable toerr
                                                 }
                             }
                    displayname {
                                 $prop = 'DisplayName'
                                 }
                    email {
                           $prop = 'EmailAddress'
                           }
                    extension {
                               $prop = 'telephoneNumber'
                               }
                    first {
                           $prop = 'GivenName'
                           }
                    groups {
                            Foreach ($group in $groups) {
                                                         Find-AD -group "$group" | %{ Add-ADGroupMember -Identity $_ -Members ($adinfo.DistinguishedName) -verbose -ErrorVariable toerr }
                                                         }
                            $prop = 'MemberOf'
                            }
                    HRname {
                            $prop = 'HRname'
                            }
                    ID {
                        $prop = 'EmployeeID'
                        }
                    manager {
                             $prop = 'Manager'
                             }
                    MobileTN {
                              $prop = 'MobilePhone'
                              }
                    office {
                            $prop = 'physicalDeliveryOfficeName'
                            }
                    Sam {
                         $prop = 'SamAccountName'
                         }
                    state {
                           $prop = 'enabled'
                           }
                    title {
                           $prop = 'Title'
                           }
                    UPN {
                         $prop = 'UserPrincipalName'
                         }
                    UltiproID {
                               $prop = 'serialNumber'
                               }      
                    }

$setparam = @{$prop = "$value"}
$ErrorActionPreference = 'Continue'
If (($property -notmatch 'group') -and ($property -notmatch 'disable')) { Set-ADuser -Server ($adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}) -Identity $adinfo.SamAccountName @setparam -Confirm:$false -ErrorVariable toerr -verbose }
If ($toerr) {$toerr}
                   Else {
                         ''
                         Write-Host "Property $prop has been set to:" -ForegroundColor Cyan
                         Get-ADUser -server ($adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}) -Identity "$user" -Properties $prop | Select-Object -ExpandProperty $prop
                         ''
                         If ($property -match 'disable') {
                                                          (Get-ADUser -server ($adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}) -Identity "$user" -Properties *).info
                                                          $DC = ($adinfo.DistinguishedName -Split ',' | Select-String 'DC=') -Join (',')
                                                          ''
                                                          Move-ADObject -Server ($adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}) -Identity $adinfo.DistinguishedName -TargetPath "OU=~Disabled User Accounts~,$DC" -Confirm:$false -Verbose -ErrorVariable toerr
                                                          ''
                                                          If (!$ticket) { Write-Host "Manually add Ticket # to description for user" $adinfo.DisplayName -ForegroundColor Yellow }
                                                          }
                         }
clv domains,adinfo,prop,value,setparam,now,audit,toerr -Force -ErrorAction SilentlyContinue
        }
End {
     Sync-Dir
     clv domains,adinfo,prop,vlaue,setparam,now,toerr -Force -ErrorAction SilentlyContinue
     # end of Function
     }
                }