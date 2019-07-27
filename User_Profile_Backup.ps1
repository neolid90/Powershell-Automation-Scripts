<#
Backup Tool.

This Script automates user profile folder backup.

Steps taken:

Requests a valid account profile name (aka login).

Validates the informtion entered for the user account (checks if profile folder exists).

Validates the backup destination path provided (checks if destination folder/Drive exists).
 
 Important note here, the script won't accept as destination the same directory or sub-directory
 as the source, in other words a folder inside the user profile which you are trying to copy the data from.
 This causes robocopy to loop.
  
Checks files and folders in the user profile.

Copies user profile data to the backup path.

Ruan Nunes
neolid17@gmail.com
#>

$ErrorActionPreference='silentlycontinue'
IF (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
$Host.UI.RawUI.WindowTitle = "Backup Tool"
[CMDLETBINDING()]

$Header = @" 
`n 
            =========================================================
            ====================== BACKUP TOOL ======================
            =========================================================
`n
"@

$Options = @"
`n
Choose an option and press Enter:
`n Type ' 1 ' To search for a another User Profile
`n Type ' Q ' To exit this script
`nYour Choice
"@

$Opt = @('y','ye','yes','N','No')

Function BackupUserValid
{
 CLS
 $Header
 $ErrorActionPreference='silentlycontinue'
 $login = Read-Host "Type the user login you want to backup"
 IF (Test-Path c:\users\$login)
 {
  $Size = "{0:N2} MB" -f ((gci C:\Users\$login -recurse | measure Length -sum).sum / 1mb)
  Write-host `n "This profile folder has approximately $Size in size (Not including Appdata)." `n
  $Choice = Read-Host "Do you wish to continue with backup? [Type Yes or Y To continue.]"
  IF ($Choice -like "y*")
  {
    BackupDestValid
  }
  ELSE {
        CLS
        Write-host `n "You did not type Y or Yes. I will assume you don't want to proceed with the backup."
        Start-Sleep -Seconds 3 
        CLS
        BackupUserValid
       }

 }
 ELSE 
 {
       Write-Host `n "Unable to find any folder for the username/login provided."
       Start-Sleep -Seconds 2
       BackupUserValid
 }
} #End of Function - BackupUserValid#

Function BackupDestValid
{
  $ErrorActionPreference='silentlycontinue'
  $dest = ''
  CLS
  $Size = "{0:N2} MB" -f ((gci C:\Users\$login -recurse | measure Length -sum).sum / 1mb)
  Write `n"User folder selected - c:\users\$login"`n`n"Folder size $Size"`n
  $dest = Read-host `n`n'Type the folder path where you want to save your Backup


  Format: [Drive Letter]:\[Folder Path] - Example: "D:\Backups\"


Path'
   
  IF ((Test-path $dest) -and ($dest -notlike "c:\users\$login*" -and $dest -notlike "c:\Windows*"))
  {
    BackupUser
  }
  ELSEIF ($dest -like "c:\users\$login*")
    {
      write-host `n "You can't save your data on a folder inside your backup source directory."
      write-host `n "Select a different folder or a different drive. " `n
      Start-Sleep -Seconds 5
      BackupDestValid
    }
  ELSEIF ($dest -like "c:\Windows*")
    {
      write-host `n "You can't backup your data to a folder inside c:\windows."
      write-host `n "Select a different folder or a different drive." `n
      Start-Sleep -Seconds 5
      BackupDestValid
    }
  ELSEIF 
  ((!(Test-path $dest)) -or $dest -eq "") #-and ($dest -notlike $Boundaries[0] -and $dest -notlike $Boundaries[1]))
  {
   Try 
   {
     $ErrorActionPreference="Stop"
     gci $dest
   }
   Catch 
   { 
     $Err = $Error[0] | out-string
        
     IF ($err -match "A drive with the name") 
     {
      Write `n`n"Drive / PSdrive not found - Check if the disk letter is correct or Exists - Example - C:, D:"
      Start-Sleep -Seconds 6
      BackupDestValid
     }
     ELSEIF ($err -match "Cannot find path") 
     {
      BackupDestNotExist
     }
   }
  }

} #End of Function BackupDestValid#



Function BackupDestNotExist
{ 
 $Opt = @('y','ye','yes','N','No')
 
 IF ($dest -notlike "c:\users\$login*" -and $dest -notlike "c:\Windows*")
  {
   Write-Host `n "Folder '$dest' doesn't exist or is unvailable."`n
 
   Try {
        $ErrorActionPreference="Stop"
        $inquiry = Read-Host `n 'Do you want me to create that folder on that path? 
         
["Yes" to confirm] or ["No" to cancel]'
        IF ($inquiry -notin $Opt)
        { 
         Write-host `n`n 'Input not recognized. Type "Yes" or "No".'`n`n
         Do {$inquiry = Read-Host `n 'Should I try to create a folder on that path? [ Type Yes or No ]'}
         until ($inquiry -in $Opt)
        }
        ELSEIF ($inquiry -in $Opt[0..2])
        {
         New-item -Type Directory $dest -ErrorAction SilentlyContinue
         CLS
         Write `n"Folder Created."
         Start-sleep -Seconds 3
         BackupUser
        }
        ELSEIF ($inquiry -in $Opt[3,4])
        {
         Write `n"You typed No. Going back to the Destination path screen"
         Start-sleep -Seconds 3
         BackupDestValid
        }
       } 
    Catch 
       { 
        $err = $Error[0]
        write`n "The following error prevented me from creating a folder on the path you provided: $err" 
        Write `n "Please make sure your storage media is available, has enough space and it's not locked by encryption."
        Start-sleep -Seconds 5
        BackupDestValid
       }
  }
 ELSEIF ($dest -like "c:\users\$login*")
  {
   write-host `n "You can't backup your data to a folder inside your backup source directory."
   write-host `n "Select a different folder or a different drive." `n
   Start-sleep -Seconds 5
   BackupDestValid
  }
 ELSEIF ($dest -like "c:\Windows*")
  {
   write-host `n "You can't backup your data to a folder inside c:\windows."
   write-host `n "Select a different folder or a different drive." `n
   Start-Sleep -Seconds 5
   BackupDestValid
  }

} #End of Function - BackupDestNotExist#

Function BackupUser
{ 
 $ErrorActionPreference='silentlycontinue'
 $Opt = @('y','ye','yes','n','no')
 Write-host `n"WARNING : This process will close ALL internet browsers currently open as well as Sticky Notes if open."
 $questn = Read-host `n`n'Do you wish to proceed?
        
[Type "Yes" to confirm or "No" to cancel]
  
Your answer'
 IF ($questn -notin $Opt)
  { 
   Write `n`n'Input not recognized. Type "Yes" or "No".'`n
   Do {$questn}
   until ($questn -in $Opt)
  }
 
 ELSEIF ($questn -in $Opt[3,4])
  {
   Write `n`n"You typed NO, going back to main screen"
   Start-sleep -Seconds 4
   BackupUserValid
  }
 
 ELSEIF ($questn -in $Opt[0..2]) # If Yes
  {
   Write `n"Initiating Backup process"`n
   Start-sleep -Seconds 2
   Write-host `n "Looking for Sticky Notes Files which to backup." 
   $stickysear = gci "$home\AppData\Local\" -include *'stickynotes'* -recurse | where {$_.DirectoryName -notlike "*Cortana*"}
   IF (!($stickysear -eq $null))
    { 
     $folder = $stickysear | select FullName | ft -HideTableHeaders | out-string
     $Stckfolder  = $folder.trim() 
      IF(Test-Path $Stckfolder)
        { 
         $Stickfold = $Stckfolder.split(“\”) | Select-Object -Last 4
         $StickySplit = $Stickfold -join "\"
          
          cls
          write-host `n "Making sure Sticky notes is not running"
          
          $proc = [bool](Get-Process *Microsoft.notes* -ea "silentlycontinue") 
          
            IF (!($proc -eq $false))
               {
                Get-Process *Microsoft.Notes* | Stop-Process
               }
                 
          Robocopy /e /xj /xc /xn /xo $Stckfolder $dest\$login\StickyNotes_BKP\$StickySplit
          Write-host "Done copying Sticky Notes"
        }
    }
    
#Checks if user has Firefox intalled then copies it.#
     Write-host `n "Looking for Firefox folders"
     $Search = gci "C:\users\$login\AppData\"
     Foreach ($fold in $Search)
      {
       $moz = $fold | select  FullName | ft -HideTableHeaders | Out-String 
       $mozFolds = $moz.Trim() + "\Mozilla"
       $MozFull = $mozfolds.split(“\”) | Select-Object -Last 2
       $MozFulpath = $mozfull -join "\"
       IF (Test-path $mozFolds)
       {
       $proc = [bool](Get-Process *Firefox* -ea "silentlycontinue") 
          
            IF (!($proc -eq $false))
               {
                Get-Process *Firefox* | Stop-Process
               }

       Robocopy $mozfolds $dest\$login\Firefox_BKP\$MozFulpath /e /xj /xc /xn /xo 
        
       Write-host `n "Done copying Firefox folders" `n
       }
       ELSE 
       {
        Write-host `n "Did not find any Mozilla folder in $mozFolds" `n
       }
      }

#Checks if user has Google Chrome Installed then copies it.#

     Write-host `n "Looking for Chrome folders"
     $Search = gci "C:\users\$login\AppData\"
     Foreach ($fold in $Search)
      {
       $Chrom = $fold | select  FullName | ft -HideTableHeaders | Out-String 
       $ChromFolds = $Chrom.Trim() + "\Google\Chrome"
       $ChromFull = $Chromfolds.split(“\”) | Select-Object -Last 3
       $ChromFulpath = $Chromfull -join "\"
       IF (Test-path $ChromFolds)
       {
       $proc = [bool](Get-Process *chrome* -ea "silentlycontinue") 
          
            IF (!($proc -eq $false))
               {
                Get-Process *Chrome* | Stop-Process
               }

       Robocopy $Chromfolds $dest\$login\GoogleChrome_BKP\$ChromFulpath /e /xj /xc /xn /xo 
        
       Write-host `n "Done copying Chrome folders" `n
       }
       ELSE 
       {
        Write-host `n "Did not find any Mozilla folder in $ChromFolds" `n
       }
      }

#Checks if user has Internet Explorer cache data then copies it.#

     Write-host `n "Looking for Internet Explorer folders"
     $Search = gci "C:\users\$login\AppData\"
     Foreach ($fold in $Search)
      {
       $IE = $fold | select  FullName | ft -HideTableHeaders | Out-String 
       $IEFolds = $IE.Trim() + "\Microsoft\Internet Explorer"
       $IEFull = $IEfolds.split(“\”) | Select-Object -Last 3
       $IEFulpath = $IEfull -join "\"
       IF (Test-path $IEFolds)
       {
       $proc = [bool](Get-Process *iexplore* -ea "silentlycontinue") 
          
            IF (!($proc -eq $false))
               {
                Get-Process *iexplore* | Stop-Process
               }

       Robocopy $IEfolds $dest\$login\InternetExplorer_BKP\$IEFulpath /e /xj /xc /xn /xo /xd "CacheStorage" /xf *.log
        
       Write-host `n "Done copying Internet Explorer folders" `n
       }
       ELSE 
       {
        Write-host `n "Did not find any Internet Explorer data folder in $IEFolds" `n
       }
      }

#Copies profile folders(Dekstop, Documents, Downloads, etc)#
     Write-host "Copying all other profile sub-folders"
     Robocopy "C:\users\$login\" "$dest\$login\" /e /xj /xc /xn /xo /xd 'appdata'  /xf *.dat /xf *.log* /xf *.ini
     $Size2 = "{0:N2} MB" -f ((gci $dest\$login -recurse | measure Length -sum).sum / 1mb)
     CLS
     Write-Host `n "Done copying user profile sub-folders except Appdata." `n `n "Total size of Backup folder for this user profile is $Size2" `n `n "Data can be found in $dest\$login\"
     Start-sleep -Seconds 10
     Menu

   }
} #End of Function - BackupUser#

Function Menu
{
Do 
{ CLS 
    $input = Read-Host $Options
      Switch($input)
    {
        '1' {write 'You chose 1 - Going to back to main menu'
        BackupUserValid
         }
        default {
                 Write "Invalid input - Choose an option from the menu"
                 Start-sleep -Seconds 3
                 Menu
                } 
        'q' {Return}
 }
}
Until ($input -eq 'q')
{Exit}
}
BackupUserValid
