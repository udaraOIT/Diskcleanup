<#
Usage

Copy the folder to C:\Program Files\WindowsPowerShell\Modules

Open Powershell as Administrator

   Import-Module Diskcleanup

Verify if Module was imported

   Get-Command -Module DiskCleanup

Run the following controller script

   $Users = Get-WmiObject  -Class Win32_UserAccount | Select Name, Status | where {$_.Status -eq 'OK'}

   $Users.Name | Get-Filepath | Remove-cache


#>



<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
Function Write-Logfile{
    
    [CmdletBinding()]
    
    Param
    (
    
        # Pass status messages in to this parameter as a string value
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [String[]]$LogMessage,

         # Pass the any other data to this parameter as a string value.
         [Parameter(Mandatory=$false,
         ValueFromPipeline=$true,
         Position=1)]
        [String[]]$Data

        
    )
    $timeStamp = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)

    $timestamp + $LogMessage | Out-file C:\temp\diskcleanup_oit.txt -append 
    $Data | Out-String | Out-file C:\temp\diskcleanup_oit.txt -append 




}#Function to get users



#Function to get paths and sizes


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-Filepath
{
    [CmdletBinding()]
    
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [String[]]$Users

        
    )

    Begin
    {
    }
    Process
    {

        $object = foreach($user in $Users){
    
            $wincachepath1= "C:\Users\$user\AppData\Local\Temp"
            $Chromecahe =  "C:\users\$user\AppData\Local\Google\Chrome\User Data\Default\cache"
        
            Try{
        
                    $firefoxAppDataPath = (Get-ChildItem "C:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles" -ErrorAction Stop| Where-Object { $_.Name -match 'Default' }[0]).FullName
        
                    #gives two profile paths for workstation user's firefox
        
                
                    $possibleCachePaths = @('cache','cache2\entries','thumbnails','cookies.sqlite','webappsstore.sqlite')
        
                    #take each possible cache and output
        
                    $firefoxcache = foreach($path in $firefoxAppDataPath){
        
                          
                    
                    
                                foreach($possibleCachePath in $possibleCachePaths){
                                    
                                        "$path"+ "\$possibleCachePath"
                    
                                    
                    
                            } #foreachpossiblecache
        
                            }#foreachfirefoxcache
                }Catch{
                    
                    Write-Logfile -LogMessage "Cannot find Firefox profile path for $user"
                    
                    $firefoxcache = "nopath"
                    
                }
        
              
        
                
              
        
        
            
                               $getfileHashtable = @{
                                                        user = $user   
                                                        path = $wincachepath1, $Chromecahe,$firefoxcache
                                                          
                                                   }
        
                                New-Object -TypeName PSObject -Property $getfileHashtable
            
            }
            
            $object

            $userpaths = $object | Format-List -Expand both | Out-String
            
            Write-Logfile -LogMessage "Following paths will be verified and cleaned" -Data "$userpaths"
               

    }
    End
    {
    }
}



#Function to delete data

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Remove-Cache
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String[]]$User,
        

        # Param1 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
      [String[]]$Path
        


    )

    Begin
    {
    }
    Process{

      $testpath = foreach ($unc in $path) {

         If(Test-Path -Path $unc){

                                          $Measure = Get-ChildItem $unc -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
          
                                          $Sum = '{0:N2}' -f ($Measure.Sum / 1Kb)
         
                                          $testpathhashtable = @{

                                                         Path = $unc   
                                                         Pathexists = "True"
                                                         Size = $Sum   
                                                                        }

                                          New-Object -TypeName PSObject -Property $testpathhashtable
                                          
                                          
                                          }else{
                                          
                                          
                                          $testpathhashtable2 = @{
                                                            Path = $unc   
                                                            Pathexists = "Flase"
                                                            Size = 0   
                                                                        }
                                          
                                          New-Object -TypeName PSObject -Property $testpathhashtable2
                                          
                                          
                                          }

      
     
             }#testpath_end
             
      $testpathdata = $testpath | format-list -expand both | Out-String

      Write-Logfile -LogMessage "Following paths were processed" -Data "$testpathdata"

      $truepaths = $testpath | Where-Object -Property Pathexists -eq "True"


$deleted =  Foreach($truepath in $truepaths){

                                 Try{
                                 
                                 
                                 Remove-Item -Path $truepath.Path -Recurse -ErrorAction Stop
                                 $myHashtable2 = @{
                                                     User = $user  
                                                     Path = $truepath.path 
                                                     Size = $truepath.size
                                                     Status = "Deleted"
                                                 }#hashtable

                                 New-Object -TypeName PSObject -Property $myHashtable2
                                 
                                 
                                 }catch{

                                 $deleteError = $_.ToString()

                                 $myHashtable2 = @{
                                                     User = $user  
                                                     Path = $truepath.path 
                                                     Size = $truepath.size
                                                     Status = "Failed to Delete"
                                                 }#hashtable

                                 New-Object -TypeName PSObject -Property $myHashtable2

                                 Write-Logfile -LogMessage "Error When trying to delete $($truepath.Path)" -Data "$deleteError"
                                 
                                 
                                 }

                                 
    

                         }#deleted_end

             $deleted            

             $output = $deleted | format-list -expand both | Out-String

             

             Write-Logfile -LogMessage "Cleaning up Data for $user" -Data "$output"  
                            


    }#process_end

    End
    {
        
    }
}#Function_end


#END