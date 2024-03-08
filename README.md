  # ADTools
PowerShell on premise Active Directory Tools (cmdlets)

  # Installation
Get entire ADTools folder (extract if compressed) from GitHub
dir -Path "c:\Directory-where-ADTools-is" -Recurse | Unblock-File
Copy that directory and all it's contents to C:\Windows\System32\WindowsPowerShell\v1.0\Modules

  # Function Find-AD
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


  # Function Find-ADObject
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


  # Function Remove-AD
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


  # Function Set-AD
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
"UPN" sets Universal Principal Name of user
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


  # Sync-Dir
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
