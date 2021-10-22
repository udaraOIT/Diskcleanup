# Diskcleanup

Usage

Copy the folder to C:\Program Files\WindowsPowerShell\Modules

Open Powershell as Administrator

Import-Module Diskcleanup

Verify if Module was imported

Get-Command -Module DiskCleanup

Run the following controller script

$Users = Get-WmiObject  -Class Win32_UserAccount | Select Name, Status | where {$_.Status -eq 'OK'}

$Users.Name | Get-Filepath | Remove-cache
