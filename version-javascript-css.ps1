#region Variables
    $directoryPath = Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path   # directory the script is running from (document root)
    $jsFilePath = "assets\scripts\"                                                  # scripts path will end with trailing slash "\"
    $cssFilePath = "assets\css\"                                                     # css path will end with a trailing slash "\"
    $jsFileNameRegex = [regex] '(nameOfYourProject\.).*(\.min\.js)'                  # myApp.asdf1234.min.js
    $cssFileNameRegex = [regex] '(nameOfYourProject\.).*(\.min\.css)'                # myApp.asdf1234.min.js
    $filesContainingVersionedResourceRefs = @("$directoryPath\index.html")           # array of files to search for script/css references
#endregion


#region Functions

# Function which versions javascript and css files using the content hash.
# NOTE: this assumes that you have two "default" versions of your combined files
#    nameOfYourProject.css/js
#    nameOfYourProject.min.css/js
function versionResource($fileToVersionRegex, $filePath){

    # Gets the default file name from the regex
    $defaultFileName = $fileToVersionRegex.ToString() -replace "(\()|(\))|(\\)|(\*)", ""
    $defaultFileName = $defaultFileName -replace "\.\.\.", "."

    # Gets the content of the default file and creates a hash
    $fileContent = Get-Content $filePath\$defaultFileName
    $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = new-object -TypeName System.Text.UTF8Encoding
    $hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($fileContent)))
    $versionHash = $hash.Replace('-', '')

    # Creates a new file name based on the content hash
    $newFileName = $defaultFileName -replace "\.min", ".$versionHash.min"

    # Tries to get the old versioned file name
    $fileToVersion = Get-ChildItem $filePath | Where-Object {$_.Name -match $fileToVersionRegex}
    if($fileToVersion -ne $null) {
        $oldFileName = $fileToVersion.Name
    }

    # $newFileName is still just a string at this point.
    # If the new version name doesn't match the old version name,
    # then we know that we need to update everything to the new version.
    if($oldFileName -ne $newFileName) {

        # OPTIONAL
        # remove the obsolete version of the file to be versioned
        # You may choose to NOT remove the versioned file, however
        # since it "should" be in your version control, you can roll back if necessary
        if($fileToVersion -ne $null) {
            Remove-Item $filePath$oldFileName -Force -ErrorAction SilentlyContinue
        }

        # rename the default file with the new file name
        Rename-Item -literalPath $filePath$defaultFileName -NewName $newFileName

        # loop through all of the specified source files and replace with the appropriate versioned file
        foreach($private:file in $filesContainingVersionedResourceRefs){
            $fileContent = Get-Content $private:file
            Clear-Content $file

            if($oldFileName -ne $null){
                # replace the old version string if it exists
                $newFileContent = $fileContent -replace "$oldFileName","$newFileName"
            } else {
                # replace the default version string if it exists
                $newFileContent = $fileContent -replace "$defaultFileName","$newFileName"                
            }

            Add-Content $private:file $newFileContent

        }
    }

    # OPTIONAL: remove original files
    # this just keeps your directory clean and free of unneeded versions of the css/js
    $private:nonMinifiedVersion = $defaultFileName -replace ".min", ""
    Remove-Item -LiteralPath $filePath$defaultFileName -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $filePath$private:nonMinifiedVersion -ErrorAction SilentlyContinue

}

# version the Javascript
versionResource $jsFileNameRegex $jsFilePath


# version the css
versionResource $cssFileNameRegex $cssFilePath
