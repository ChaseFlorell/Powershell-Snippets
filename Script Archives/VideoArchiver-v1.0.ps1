$input = $args[0]
$mp3FileName = "RPC.MP3 - $input.mp3"
$mp4FileName = "RPC.MP4 - $input.mp4"
$outputFolder = "D:\outputmedia"
$Logfile = "D:\Logs\$(gc env:computername).log"
$currentYear = get-date -Format yyyy
$dropboxDir = "D:\Dropbox\Weekend Services\Sermon Videos\"
$videoArchiveDir = "\\192.168.0.113\media\Media Archives\HD\$currentYear\"
$audioArchiveDir = "\\192.168.0.113\media\Media Archives\Audio\$currentYear\"

Function LogWrite{
   Param ([string]$logstring)
   Add-content $Logfile -value $logstring
}

Function Pause($M="Press any key to continue . . . "){
	If($psISE){
		$S=New-Object -ComObject "WScript.Shell";$B=$S.Popup("Click OK to continue.",0,"Script Paused",0);Return
	};
	Write-Host -NoNewline $M;$I=16,17,18,20,91,92,93,144,145,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183;While($K.VirtualKeyCode -Eq $Null -Or $I -Contains $K.VirtualKeyCode){$K=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")};Write-Host
}

LogWrite("----------------------------------------------------------")
LogWrite("Processing video: " + (Get-Date))

Write-Host "Finishing video process....."  -ForegroundColor Green
Start-Sleep -s 5

$title = "Video Post-Processing"
$message = "Does this video need to be archived, copied to USB, or uploaded to vimeo?"

$all = New-Object System.Management.Automation.Host.ChoiceDescription "&All", `
    "Archive this recording, copy the video to a usb drive, and upload it to Vimeo. A local copy will be left in 'outputmedia'."
	
$local = New-Object System.Management.Automation.Host.ChoiceDescription "&Local", `
    "Archive this recording, and copy the video to a usb drive. A local copy will be left in 'outputmedia'."
	
$none = New-Object System.Management.Automation.Host.ChoiceDescription "&None", `
    "Leave a local copy of this recording in 'outputmedia'."
	
$delete = New-Object System.Management.Automation.Host.ChoiceDescription "&Delete", `
    "Discard the recording, no copies will be saved."
	
$options = [System.Management.Automation.Host.ChoiceDescription[]]($all, $local, $none, $delete)
$howToProcess = $host.ui.PromptForChoice($title, $message, $options, 0)

$userChoice = $options[$howToProcess].HelpMessage
LogWrite("User requested to $userChoice")

# Copy to USB
if(($howToProcess -eq 0) -or ($howToProcess -eq 1)){
	do {
	  	$UsbDisk = gwmi win32_diskdrive | ?{$_.interfacetype -eq "USB"} | %{gwmi -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($_.DeviceID.replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition"} |  %{gwmi -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($_.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"} | %{$_.deviceid} 
		if ( $UsbDisk -eq $null ) {  
			Write-Host "There is no USB drive detected, please insert a USB drive"
			LogWrite("Waiting for user to insert a USB drive")
			Pause 
		}
	}
	while ($UsbDisk -eq $null)
	
	# Format the disk
	Write-Host "You are about the erase all contents on the USB drive"-ForegroundColor Red
	LogWrite("Erasing the USB Drive")
	pause
	Remove-Item -Recurse -Force "$UsbDisk" -ErrorAction SilentlyContinue
	
	# Copy the video to the USB stick
	try{
		LogWrite("Copying the Video to the USB Drive")
		Copy-Item -LiteralPath "$outputFolder\$mp4FileName" -Destination "$UsbDisk" -Force
	}catch [system.Exception]{
		LogWrite("Exception: $_")
	}
}



# Copy the Video to Dropbox (hooks up with Vimeo Automagically
if($howToProcess -eq 0){
	try{
		LogWrite("Copying the video to Dropbox (used for Vimeo auto-upload)")
		Copy-Item -LiteralPath "$outputFolder\$mp4FileName" -Destination "$dropboxDir" -Force
	}catch [system.Exception]{
		LogWrite("Exception: $_")
	}
}



# Copy the Audio and Video to M:/ Archives
if(($howToProcess -eq 0) -or ($howToProcess -eq 1)){
	try{
		LogWrite("Copying the Audio and Video to the NAS for archival purposes")
		Copy-Item -LiteralPath "$outputFolder\$mp4FileName" -Destination "$videoArchiveDir" -Force
		Copy-Item -LiteralPath "$outputFolder\$mp3FileName" -Destination "$audioArchiveDir" -Force
	}catch [system.Exception]{2
		LogWrite("Exception: $_")
	}
}



# Delete the files
if($howToProcess -eq 3){
	try{
		LogWrite("Deleting audio and video files from the server.")
		Remove-Item -LiteralPath "$outputFolder\$mp4FileName" -force -recurse -ErrorAction SilentlyContinue
		Remove-Item -LiteralPath "$outputFolder\$mp3FileName" -force -recurse -ErrorAction SilentlyContinue
	}catch [system.Exception]{
		LogWrite("Exception: $_")
	}	
}

Write-Host "Process completed successfully, exiting..."  -ForegroundColor Green
LogWrite("Process completed successfully " + (Get-Date))
Start-Sleep -s 5