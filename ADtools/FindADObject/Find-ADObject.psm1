<#
.SYNOPSIS
To lookup groups and their members in Active Directory

.DESCRIPTION
Yes, you could use Get-ADgroup or Get-ADOrganizationalUnit...
However, this searches across all domains in the Forest and simplifies search syntax

.PARAMETER property
"all" gets all information
"DN" gets Distinguished Name
"email" gets Email address (if applies)
"members" gets all members
"memberOf" gets Groups it is a member of
"type" get whether is is Distribution or Security

.EXAMPLE
Find-ADObject -group Distro-Name

'CN=group-name,CN=wherever,DC=domain,DC=com' | Find-ADObject
^ All examples above get all Group details ^

.NOTES
Author = Brad Lape
Role = Associate Windows Systems Administrator
Company = RackSquared
Module = ADtools
Total Cmdlets = 5
This Cmdlet = Find-ADObject
 #>

Function Find-ADObject {
                       [CmdletBinding()]
                       Param (
                              [parameter(position=0,ValueFromPipelineByPropertyName,ValueFromPipeline,ParameterSetName='group')]
                              [string]$group,
                              [parameter(position=1,ParameterSetName='OU')]
                              [string]$OU,
                              [ValidateSet('all','closed','sam','displayname','dn','email','members','memberOf','senders','type')]
                              [parameter(position=2)]
                              [string[]]$property='all',
                              [ValidateSet('distribution','security')]
                              [parameter(position=3,ParameterSetName='group')]
                              [string]$type='*',
                              [switch]$recursive,
                              [switch]$userssonly,
                              [switch]$groupsonly,
                              [switch]$simple,
                              [switch]$NoDisconnect
                              )

Begin {
       $domains = (Get-ADForest).domains
       Function Nested-MemberOf {
                                 [CmdletBinding()]
                                 param (
                                        [parameter(position=0,ValueFromPipelineByPropertyName,ValueFromPipeline,mandatory='yes')]
                                        $identity
                                        )
                                 Begin { $ErrorActionPreference = 'SilentlyContinue' }
                                 Process {
                                          $groups = $domains | %{(Get-ADGroup -Server $_ -Identity $identity -Properties MemberOf -ErrorAction SilentlyContinue).MemberOf}
                                          $groups
                                          If ($groups.Count -gt 0) { $groups | % { Nested-MemberOf $_ } | Select -Unique }
                                          }
                                 }
       Function NestedOU-MemberOf {
                                   [CmdletBinding()]
                                   param (
                                         [parameter(position=0,ValueFromPipelineByPropertyName,ValueFromPipeline,mandatory='yes')]
                                         $identity
                                         )
                                   Begin {
                                          $ErrorActionPreference = 'SilentlyContinue'
                                          [void][reflection.assembly]::LoadWithPartialName("System.DirectoryServices")
                                          }
                                   Process {
                                            $groups = (Get-ADOrganizationalUnit -Server $domain -SearchBase $identity -Filter * -ResultSetSize 5000 -SearchScope Base | select *,@{l='Parent';e={(New-Object 'System.DirectoryServices.directoryEntry' "LDAP://$($_.DistinguishedName)").Parent}} | Select-Object -ExpandProperty Parent).Replace('LDAP://','')
                                            $groups
                                            If ($groups.Count -gt 0) { $groups | % { NestedOU-MemberOf $_ } | Select -Unique }
                                            }
                                   }
       Function Nested-Members {
                                [CmdletBinding()]
                                param (
                                       [parameter(position=0,ValueFromPipelineByPropertyName,ValueFromPipeline,mandatory='yes')]
                                       $identity
                                       )
                                Begin { $ErrorActionPreference = 'SilentlyContinue' }
                                Process {
                                         $groups = $domains | %{(Get-ADGroup -Server $_ -Identity $identity -Properties Members -ErrorAction SilentlyContinue).Members | ?{ $_ -like "*group*" }}
                                         $groups
                                         If ($groups.Count -gt 0) { $groups | % { Nested-Members $_ } | Select -Unique }
                                         }
                                }
       If ($simple -eq $true) {
                               $expndprop = @{ ExpandProperty = 'Name' } 
                               }
                               Else {
                                     $expndprop = @{ ExpandProperty = 'DistinguishedName' }
                                     }
       }

Process {
$ErrorActionPreference = 'SilentlyContinue'
clv adinfo -Force -ErrorAction SilentlyContinue
If ([bool][mailaddress]$group) {$adinfo = $domains |  Foreach-Object { Get-ADGroup -server $_ -Filter "mail -like ""$group""" -Properties * | Where-Object -Property GroupCategory -Like $type }}
If (!$adinfo) {
               $adinfo = $domains | Foreach-Object {
                                                    If ($group) {
                                                                 Try {
                                                                      Get-ADGroup -server $_ -Filter "(Name -like ""$group"") -or (SamAccountName -like ""$group"") -or (DisplayName -like ""$group"") -or (CN -like ""$group"")" -Properties * | Where-Object -Property GroupCategory -Like $type                  
                                                                      }
                                                                      Catch {
                                                                             Get-ADOrganizationalUnit -server $_ -LDAPFilter "(Name=*$group*)" -Properties *
                                                                             }
                                                                 }
                                                    If ($OU) {
                                                              Try {
                                                                   Get-ADOrganizationalUnit -server $_ -LDAPFilter "(Name=*$OU*)" -Properties *
                                                                   }
                                                                   Catch {
                                                                          Get-ADOrganizationalUnit -server $_ -Identity "$OU" -Properties *
                                                                          }
                                                             }
                                                    }
               }
              
If (!$adinfo) {
               $ErrorActionPreference = 'Continue'
               clv domains -Force -ErrorAction SilentlyContinue
               Throw "$group not found, try Distinguished Name or Canonical Name"
               break
               }

# domain variable always populated/availble
$global:domain = $adinfo.CanonicalName -Replace ('/.+$') | %{$_.trim()} | ? {$_}
              
Switch ($property) {
                    all { $adinfo }
                    closed {
                            Switch ($adinfo.msExchGroupJoinRestriction) { 
                                                                         '0' { 'Added by Owner' }
                                                                         '1' { 'Anyone can join' }
                                                                         '2' { 'Owner approval' }
                                                                         } 
                            }
                    displayname {$adinfo.DisplayName}
                    sam { $adinfo.SamAccountName }
                    dn { If ($simple -match $true) {
                                                    ($adinfo.DistinguishedName -replace '(.+?),.+','$1').Replace('CN=','') 
                                                    }
                                                    Else {
                                                          $adinfo.DistinguishedName
                                                          } 
                        }
                    email { $adinfo.mail }
                    members {
                             If (!$recursive) {
                                               If (!$userssonly) {
                                                                  If (!$groupsonly) { 
                                                                                     If ($adinfo.ObjectClass -match 'group') {
                                                                                                                              If ($simple -match $true) {
                                                                                                                                                         ($adinfo.Members -replace '(.+?),.+','$1').Replace('CN=','') 
                                                                                                                                                         }
                                                                                                                                                         Else {
                                                                                                                                                               $adinfo.Members
                                                                                                                                                               }
                                                                                                                              }
                                                                                                                              ElseIf ($adinfo.ObjectClass -match 'organizationalUnit') {
                                                                                                                                                                                        Get-ADOrganizationalUnit -Server $domain -SearchBase $adinfo.DistinguishedName -Filter * -ResultSetSize -SearchScope OneLevel | Select-Object @expndprop
                                                                                                                                                                                        Get-ADUser -Server $domain -SearchBase $adinfo.DistinguishedName -Filter * -ResultSetSize 5000 | Select-Object @expndprop
                                                                                                                                                                                        }
                                                                                     }
                                                                                     ElseIf ($groupssonly) {
                                                                                                            If ($adinfo.ObjectClass -match 'group') {
                                                                                                                                                     $adinfo.Members | ?{ $_ -like "*group*" } 
                                                                                                                                                     }
                                                                                                                                                     ElseIf ($adinfo.ObjectClass -match 'organizationalUnit') {
                                                                                                                                                                                                               Get-ADOrganizationalUnit -Server $domain -SearchBase $adinfo.DistinguishedName -Filter * -ResultSetSize -SearchScope OneLevel | Select-Object @expndprop
                                                                                                                                                                                                               }

                                                                                                            }
                                                                  }
                                                                  ElseIf ($userssonly) { 
                                                                                        If ($adinfo.ObjectClass -match 'group') {
                                                                                                                                 $adinfo.Members | ?{ $_ -notlike "*group*" }
                                                                                                                                 }
                                                                                                                                 ElseIf ($adinfo.ObjectClass -match 'organizationalUnit') {
                                                                                                                                                                                           Get-ADUser -Server $domain -SearchBase $adinfo.DistinguishedName -Filter * -ResultSetSize 5000 -SearchScope OneLevel | Select-Object @expndprop
                                                                                                                                                                                           }
                                                                                                                                  
                                                                                        }
                                               }
                                               ElseIf ($recursive) {
                                                                    If (!$userssonly) {
                                                                                       If (!$groupsonly) {
                                                                                                          If ($adinfo.ObjectClass -match 'group') {
                                                                                                                                                   $adinfo.Members | ?{ $_ -like "*group*" }
                                                                                                                                                   $adinfo.Members | ?{ $_ -like "*group*" } | %{ Nested-Members $_ } | Select -Unique
                                                                                                                                                   (Get-ADGroupMember -Server $domain -Identity $adinfo.DistinguishedName -Recursive).Name
                                                                                                                                                   }
                                                                                                                                                   ElseIf ($adinfo.ObjectClass -match 'organizationalUnit') {
                                                                                                                                                                                                             Get-ADOrganizationalUnit -Server $domain -SearchBase $adinfo.DistinguishedName -Filter * -ResultSetSize -SearchScope Subtree | Select-Object @expndprop
                                                                                                                                                                                                             Get-ADUser -Server $domain -SearchBase $adinfo.DistinguishedName -Filter * -ResultSetSize 5000 -SearchScope Subtree | Select-Object @expndprop
                                                                                                                                                                                                             }
                                                                                                          }
                                                                                                          ElseIf ($groupsonly) {
                                                                                                                                If ($adinfo.ObjectClass -match 'group') {
                                                                                                                                                                         $adinfo.Members | ?{ $_ -like "*group*" }
                                                                                                                                                                         $adinfo.Members | ?{ $_ -like "*group*" } | %{ Nested-Members $_ } | Select -Unique
                                                                                                                                                                         }
                                                                                                                                                                         ElseIf ($adinfo.ObjectClass -match 'organizationalUnit') {
                                                                                                                                                                                                                                   Get-ADOrganizationalUnit -Server $domain -SearchBase $adinfo.DistinguishedName -Filter * -ResultSetSize -SearchScope Subtree | Select-Object @expndprop
                                                                                                                                                                                                                                   }

                                                                                                                                }
                                                                                       }
                                                                                       ElseIf ($userssonly) { 
                                                                                                             If ($adinfo.ObjectClass -match 'group') {
                                                                                                                                                      Get-ADGroupMember -Server $domain -Identity $adinfo.DistinguishedName -Recursive | Select-Object @expndprop
                                                                                                                                                      }
                                                                                                                                                      ElseIf ($adinfo.ObjectClass -match 'organizationalUnit') {
                                                                                                                                                                                                                Get-ADUser -Server $domain -SearchBase $adinfo.DistinguishedName -Filter * -ResultSetSize 5000 -SearchScope Subtree | Select-Object @expndprop
                                                                                                                                                                                                                }
                                                                                                            }
                                                                    }
                             }                                                                                                                                        
                    memberOf {
                              If (!$recursive) {
                                                If ($adinfo.ObjectClass -match 'group') {
                                                                                         $adinfo.MemberOf
                                                                                         }
                                                                                         ElseIf ($adinfo.ObjectClass -match 'organizationalUnit') {
                                                                                                                                                   [void][reflection.assembly]::LoadWithPartialName("System.DirectoryServices")
                                                                                                                                                   (Get-ADOrganizationalUnit -Server $domain -SearchBase $adinfo.DistinguishedName -Filter * -ResultSetSize 5000 -SearchScope Base | select *,@{l='Parent';e={(New-Object 'System.DirectoryServices.directoryEntry' "LDAP://$($_.DistinguishedName)").Parent}} | Select-Object -ExpandProperty Parent).Replace('LDAP://','')
                                                                                                                                                   }
                                                }
                                                ElseIf ($recursive) {
                                                                     If ($adinfo.ObjectClass -match 'group') {
                                                                                                              $adinfo.MemberOf
                                                                                                              $adinfo.MemberOf | %{ Nested-MemberOf $_ } | Select -Unique
                                                                                                              }
                                                                                                              ElseIf ($adinfo.ObjectClass -match 'organizationalUnit') {
                                                                                                                                                                        NestedOU-MemberOf -Identity $adinfo.DistinguishedName
                                                                                                                                                                        }
                                                                     }
                              }
                    senders {
                             ExchgOnline
                             (Get-DistributionGroup $adinfo.cn).AcceptMessagesOnlyFromSendersOrMembers  
                             }
                    type { $adinfo.GroupCategory }
                    }

     clv group,OU,adinfo -Force -ErrorAction SilentlyContinue
     $ErrorActionPreference = 'Continue'      
     }

End {
     clv domains -Force -ErrorAction SilentlyContinue
     # end of Function
     If (($property -match 'senders') -and (!$NoDisconnect)) { ExchgOnline -Disconnect }
     }
            }                        