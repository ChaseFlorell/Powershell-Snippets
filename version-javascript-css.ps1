#region Variables
    $directoryPath = Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path   # directory the script is running from (document root)
    $jsFilePath = "assets\scripts\"                                                  # scripts path will end with trailing slash "\"
    $cssFilePath = "assets\css\"                                                     # css path will end with a trailing slash "\"
    $jsFileNameRegex = [regex] '(nameOfYourProject\.).*(\.min\.js)'                  # myApp.asdf1234.min.js
    $cssFileNameRegex = [regex] '(nameOfYourProject\.).*(\.min\.css)'                # myApp.asdf1234.min.js
    $filesContainingVersionedResourceRefs = @("$directoryPath\index.html")           # array of files to search for script/css references
#endregion


#region Functions

    function versionResource($fileToVersionRegex, $filePath){
        $fileToVersion = Get-ChildItem $directoryPath\$filePath | Where-Object {$_.Name -match $fileToVersionRegex}
        $oldFileName = $fileToVersion.Name
        
        $fileContent = Get-Content $directoryPath\$filePath$fileToVersion
        $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
        $utf8 = new-object -TypeName System.Text.UTF8Encoding
        $hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($fileContent)))
        $versionHash = $hash.Replace('-', '')
        
        $fileToVersion -match $fileToVersionRegex > $null 
        $newFileName = "$($matches[1])$versionHash$($matches[2])"
        
        if($oldFileName -ne $newFileName) {
            Write-Host "Renaming the file"
            Rename-Item $directoryPath\$filePath$fileToVersion -NewName $newFileName
            
            foreach($file in $filesContainingVersionedResourceRefs){
                $fileContent = Get-Content $file
                Clear-Content $file

                $newFileContent = $fileContent -replace "$oldFileName","$newFileName"
                
                Add-Content $file $newFileContent
                
            }
        }
    }
    
#endregion

versionResource $jsFileNameRegex $jsFilePath
versionResource $cssFileNameRegex $cssFilePath  
