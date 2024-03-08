Function Find-AD {
<#
.SYNOPSIS
To lookup users and groups details in Active Directory

.DESCRIPTION
Yes, you could use Get-ADuser or Get-ADGroup...
However, this searches across all domains in the Forest and simplifies the search syntax

.PARAMETER user
Type the user's name you are looking for in the following formats:
FirstLast
FirstLast@domain.com
"First Last"
"Last, First M"

.PARAMETER group
Type a group name

.PARAMETER property
"company" gets company information about a user
"department" gets department information about a user
"description" gets description information about a user
"displayname" gets Display Name information about a user
"email" gets email address of user
"enabled" gets account status of user
"extension" gets telephone extension number of user
"first" gets first name of user
"groups" gets groups a user is a member of
"HRname" gets UltiPro user name
"ID" gets Employee ID of user
"manager" gets manager of user
"MobileTN" gets mobile telephone number of user
"office" gets office location of user
"Sam" gets Sam Account Name of user
"title" gets title of user
"UPN" gets Universal Principal Name of user
"UltiProID" gets UltiPro ID of user
"verify" verifies that account exists on domain(s)

.PARAMETER groupprop
"all" gets all information
"DN" gets Distinguished Name
"email" gets Email address
"members" gets all members
"memberOf" gets Groups it is a member of
"type" get whether is is Distribution or Security

.EXAMPLE
Find-AD -user FirstLast
Find-AD FirstLast

'Last, First M' | Find-AD
^ All examples above get all user account details ^

.EXAMPLE
Find-AD FirstLast manager
'First Last' | Find-AD -property manager

.EXAMPLE
Find-AD FirstLast groups

.EXAMPLE
Find-AD FirstLast verify
^ Gets boolean output ^

.EXAMPLE
Find-AD -group Distro-Name

'CN=group-name,CN=wherever,DC=domain,DC=com' | Find-ADObject
^ All examples above get all Group details ^

.NOTES
Author = Brad Lape
Role = Associate Windows Systems Administrator
Company = RackSquared
Module = ADtools
Total Cmdlets = 4
This Cmdlet = Find-AD
 #>
                    [CmdletBinding()]
                    Param (
                           [parameter(position=0,ValueFromPipeline,ParameterSetName='user')]
                           [string]$user,
                           [ValidateSet('all','company','department','description','displayname','dn','domain','email','enabled','extension','first','groups','HRname','ID','LastLogon','manager','managers','MobileTN','names','notes','office','Sam','SID','smtp','title','telephone','UPN','UltiproID','verify')]
                           [parameter(position=1,ParameterSetName='user')]
                           [string]$property='all',
                           [parameter(position=2,ParameterSetName='group')]
                           [string]$group,
                           [ValidateSet('all','closed','DN','email','members','memberOf','displayname','sam','senders','type')]
                           [parameter(position=3,ParameterSetName='group')]
                           [string[]]$groupprop='all',
                           [ValidateSet('distribution','security')]
                           [parameter(position=4,ParameterSetName='group')]
                           [string]$type,
                           [parameter(position=5,ParameterSetName='group')]
                           [switch]$recursive,
                           [parameter(position=6,ParameterSetName='group')]
                           [switch]$userssonly,
                           [parameter(position=7,ParameterSetName='group')]
                           [switch]$groupsonly,
                           [parameter(position=8,ParameterSetName='group')]
                           [switch]$simple,
                           [parameter(position=9,ParameterSetName='group')]
                           [parameter(ParameterSetName='user')]
                           [switch]$PassThru,
                           [parameter(position=10,ParameterSetName='group')]
                           [switch]$NoDisconnect                          
                           )


Begin {
       $domains = (Get-ADForest).domains
       Function Ladder {
                        [parameter(position=0,ValueFromPipeline,ParameterSetName='user')]
                        [string]$name

                        Begin { $ErrorActionPreference = 'SilentlyContinue' }
                        Process {
                                 $managers = $domains | get-aduser -server $_ -Identity "$name" -Properties Manager | Select-Object -ExpandProperty Manager
                                 $managers.Split(',')[0].Replace('CN=','')
                                 If ($managers.Count -gt 0) { ($domains | get-aduser -server $_ -Identity ($manager.Split(',')[0].Replace('CN=','') -Replace (' ','')) -Properties Manager | Select-Object -ExpandProperty Manager).Split(',')[0].Replace('CN=','') } 
                                 }           
                        }
       }

Process {
If (!$group) {
$ErrorActionPreference = 'SilentlyContinue'
clv adinfo -Force -ErrorAction SilentlyContinue
If ([bool][mailaddress]$user) {$adinfo = $domains | Foreach-Object {get-aduser -server $_ -LDAPfilter "(mail=$user)" -Properties *}}
If (!$adinfo) {
               $adinfo = $domains | Foreach-Object {
                                                    If (($user -notmatch ' ') -and ($user -notmatch ',')) {
                                                                                                           # user name has no space in it
                                                                                                           get-aduser -server $_ -Identity "$user" -Properties *
                                                                                                           }
                                                                                                           ElseIf (($user -match ' ') -and ($user -notmatch ',')) {
                                                                                                                                                                   # user name has a space in it
                                                                                                                                                                   Try {
                                                                                                                                                                        # use the space
                                                                                                                                                                        get-aduser -server $_ -LDAPfilter "(Name=$user)" -Properties *
                                                                                                                                                                        }
                                                                                                                                                                        Catch {
                                                                                                                                                                               # replace the space
                                                                                                                                                                               get-aduser -server $_ -Identity ($user.Replace(' ','')) -Properties *
                                                                                                                                                                               }
                                                                                                                                                                   }
                                                                                                                                                                   ElseIf (($user -match ',') -and ($user.Split().Count -ge '3')) {
                                                                                                                                                                                                                                   $last = ($user -split ',').Trim().Get(0)
                                                                                                                                                                                                                                   $first = ($user -split ',').Trim().Get(1).Replace('.','') -Replace (' ','')
                                                                                                                                                                                                                                   $user = "$last" + ', ' + "$first"
                                                                                                                                                                                                                                   get-aduser -server $_ -LDAPfilter "(HRName=$user)" -Properties * 
                                                                                                                                                                                                                                   clv lfsplit,last,first -Force -ErrorAction SilentlyContinue
                                                                                                                                                                                                                                   }
                                                                                                                                                                                                                                   Else {
                                                                                                                                                                                                                                         $last = ($user -split ',').Trim().Get(0)
                                                                                                                                                                                                                                         $first = ($user -split ',').Trim().Get(1).Replace('.','') -Replace (' ','')
                                                                                                                                                                                                                                         Try {
                                                                                                                                                                                                                                              $user = "$last" + ', ' + "$first" 
                                                                                                                                                                                                                                              get-aduser -server $_ -Filter "HRName -like ""*$user*""" -Properties * 
                                                                                                                                                                                                                                              }
                                                                                                                                                                                                                                              Catch {
                                                                                                                                                                                                                                                     $user = "$first" + "$last"
                                                                                                                                                                                                                                                     get-aduser -server $_ -Identity $user -Properties *
                                                                                                                                                                                                                                                     }
                                                                                                                                                                                                                                         }                                                    
                                                     }
              }

If ((!$adinfo) -and ($property -notmatch 'verify')) {
                                                     $ErrorActionPreference = 'Continue'
                                                     clv domains -Force -ErrorAction SilentlyContinue
                                                     Throw "$user not found, try FirstLast / FLast / ""Last, FirstM"" / email"
                                                     break
                                                     }

If ($PassThru) {
                # domain variable always populated/availble
                $script:server = $adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}
                }

Switch ($property) {
                    all {$adinfo}
                    company {$adinfo.Company}
                    department {$adinfo.Department}
                    description {$adinfo.Description}
                    displayname {$adinfo.DisplayName}
                    dn { If ($simple -match $true) {
                                                    ($adinfo.DistinguishedName -replace '(.+?),.+','$1').Replace('CN=','') 
                                                    }
                                                    Else {
                                                          $adinfo.DistinguishedName
                                                          } 
                        }
                    domain {$adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}}
                    email {$adinfo.EmailAddress}
                    enabled {$adinfo.Enabled}
                    extension {$adinfo.telephoneNumber}
                    first {$adinfo.GivenName}
                    groups {$adinfo.MemberOf}
                    HRname {$adinfo.HRname}
                    ID {$adinfo.EmployeeID}
                    LastLogon {[datetime]::fromfiletime($adinfo.lastLogonTimeStamp)}
                    manager {$adinfo.Manager.Split(',')[0].Replace('CN=','')}
                    managers {$adinfo.Manager.Split(',')[0].Replace('CN=',''); recursive ($adinfo.Manager.Split(',')[0].Replace('CN=','') -Replace (' ','')) }
                    MobileTN {$adinfo.Mobile}
                    names {$adinfo | Select-Object CanonicalName,CN,DistinguishedName,EmailAddress,GivenName,Surname,sn,mail,mailNickname,'msRTCSIP-PrimaryUserAddress',Name,ProxyAddresses,SamAccountName,targetAddress,UserPrincipalName}
                    notes {$adinfo.info}
                    Sam {$adinfo.SamAccountName}
                    SID {$adinfo.SID.Value}
                    smtp {($ADinfo.proxyAddresses | Select-String smtp) -Replace ('/.+$') | %{$_.trim()} | ? {$_}}
                    office {$adinfo.physicalDeliveryOfficeName}
                    title {$adinfo.Title}
                    telephone {($adinfo | Select-Object -ExpandProperty msRTCSIP-Line).Trim('tel:+').Replace(';',' ') -replace ('=',' ')}
                    UPN {$adinfo.UserPrincipalName}
                    UltiproID {$adinfo.serialNumber} 
                    verify {
                            If (!$adinfo) { $false }
                                                    ElseIf ($adinfo.Enabled -match $true) { $true }
                                                                                                  ElseIf ($adinfo.Enabled -match $false) {
                                                                                                                                          $true
                                                                                                                                          'Account Disabled'
                                                                                                                                          }
                                                                                                                                          ElseIf ($adinfo) { $true }
                                                                                                                                                                   Else { $false }
                    }
}
     clv user,adinfo -Force -ErrorAction SilentlyContinue
     $ErrorActionPreference = 'Continue'
     } # user / not group
     ElseIf ($group) {
                      $grpargs = @{'group'=$group}
                      If ($type) { $grpargs.Add('type', $type) }
                      If ($groupprop) {
                                       $grpargs.Add('property', $groupprop) 
                                       }
                      If ($groupsonly -eq $true) {
                                                  $grpargs.Add('groupsonly', $true) 
                                                  }
                      If ($userssonly -eq $true) {
                                                  $grpargs.Add('userssonly', $true) 
                                                  }
                      If ($recursive -eq $true) {
                                                 $grpargs.Add('recursive', $true)
                                                 }
                      If ($simple -eq $true) {
                                              $grpargs.Add('simple', $true)
                                              }
                      If ($NoDisconnect -eq $true) {
                                                    $grpargs.Add('NoDisconnect', $true)
                                                    }
                      Find-ADObject @grpargs
                      }
    }
End {
     clv domains -Force -ErrorAction SilentlyContinue
     # end of Function
     }     
}