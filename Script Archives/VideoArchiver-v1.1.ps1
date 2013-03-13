#region -------------------------------------
#
#     Version:           V1.1
#     Author:            Chase Florell
#     Date:              March 11, 2013
#     Email:             chase@florell.me 
#
#endregion ----------------------------------

#region Variables

    $input = $args[0]
    $mp3FileName = "RPC.MP3 - $input.mp3"
    $mp4FileName = "RPC.MP4 - $input.mp4"
    $outputFolder = "D:\outputmedia"
    $Logfile = "D:\Logs\$(gc env:computername).log"
    $currentYear = get-date -Format yyyy
    $dropboxDir = "D:\Dropbox\Weekend Services\Sermon Videos\"
    $videoArchiveDir = "\\192.168.0.113\media\Media Archives\HD\$currentYear\"
    $audioArchiveDir = "\\192.168.0.113\media\Media Archives\Audio\$currentYear\"

#endregion


#region Functions

	Function Write-Log{

        Param (
            [Parameter(Position=0)]
            [string]$logstring, 
            
			#Should be 'Error', 'Warn', 'Success', 'Info', or [nothing/null/blank]
            [Parameter(Position=1)]
            [AllowNull()]
            [string]$logType,
			
			[Parameter(Position=2)]
			[AllowNull()]
			[System.Boolean]$displayInConsole
        )
        
		# Default color if $logType is null
        $foregroundColor = "DarkCyan"

		# Set the logging colors
        if($logType -eq "Info"){    $foregroundColor = "DarkCyan" } 
        if($logType -eq "Warn"){    $foregroundColor = "Yellow" } 
        if($logType -eq "Error"){   $foregroundColor = "Red" } 
        if($logType -eq "Success"){ $foregroundColor = "Green" } 

		if($displayInConsole){
	        Write-Host("$logstring") -ForegroundColor $foregroundColor
		}
		
		#Write the log to the log file
        Add-content $Logfile -value $logstring
	}

	Function Pause($M="Press any key to continue . . . "){
		If($psISE){
			$S=New-Object -ComObject "WScript.Shell";$B=$S.Popup("Click OK to continue.",0,"Script Paused",0);Return
		};
		Write-Host -NoNewline $M;$I=16,17,18,20,91,92,93,144,145,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183;While($K.VirtualKeyCode -Eq $Null -Or $I -Contains $K.VirtualKeyCode){$K=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")};Write-Host
	}

	Function CopyToUSB{
	    # No USB Drive Detected
		do {
		  	$UsbDisk = gwmi win32_diskdrive | ?{$_.interfacetype -eq "USB"} | %{gwmi -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($_.DeviceID.replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition"} |  %{gwmi -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($_.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"} | %{$_.deviceid} 
			if ( $UsbDisk -eq $null ) {  
				Write-Log "There is no USB drive detected, please insert one." "Warn" $true
				Pause 
			}
		}
		while ($UsbDisk -eq $null)
		
		
		#region  QUESTION: Would you like to ERASE all content from the USB Device before copying files?
			$title = "Format USB Drive"
			$message = "Would you like to ERASE all content from the USB Device before copying files?"

			$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
				"All content will be left on the USB Drive. Nothing will be deleted"

			$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
				"All content will be deleted from the USB Drive. THIS CANNOT BE UNDONE"

			$options = [System.Management.Automation.Host.ChoiceDescription[]]($no, $yes)
			$eraseUsb = $host.ui.PromptForChoice($title, $message, $options, 0)
			Write-Log $options[$eraseUsb].HelpMessage "Info" $true
		#endregion
		
		# Erase the USB Drive
		if($eraseUsb -eq 1){
            Write-Log "All contents of the USB drive is being erased." "Warn" $true
			Remove-Item -Recurse -Force "$UsbDisk" -ErrorAction SilentlyContinue
		}
		
		# Copy the video to the USB stick
		try{
			Write-Log "Copying the Video to the USB Drive" "Info" $true
			Copy-Item -LiteralPath "$outputFolder\$mp4FileName" -Destination "$UsbDisk" -Force
		}catch [system.Exception]{
			Write-Log "Exception: $_" "Error" $true
		}
		
	}
	
	Function CopyToDropbox{
		try{
			Write-Log "Copying the video to Dropbox (used for Vimeo auto-upload)" "Info" $true
			Copy-Item -LiteralPath "$outputFolder\$mp4FileName" -Destination "$dropboxDir" -Force
		}catch [system.Exception]{
			Write-Log "Exception: $_" "Error" $true
		}
	}
	
	Function CopyToNas{
		# Copy the output files to the NAS
		try{
			Write-Log "Copying the Audio and Video to the NAS for archival purposes" "Info" $true
			Copy-Item -LiteralPath "$outputFolder\$mp4FileName" -Destination "$videoArchiveDir" -Force
			Copy-Item -LiteralPath "$outputFolder\$mp3FileName" -Destination "$audioArchiveDir" -Force
		}catch [system.Exception]{
			Write-Log "Exception: $_" "Error" $true
		}	
			
		# Verify that the video file was archived properly. 
		if(Test-Path -LiteralPath $videoArchiveDir$mp4FileName){ 
			Write-Log "Video successfully archived. Deleting video file from the 'outputmedia' folder." "Success" $true
			Remove-Item -LiteralPath "$outputFolder\$mp4FileName" -force -recurse -ErrorAction SilentlyContinue
		} else {
		    Write-Log "Video archive failed, a copy of the video is being left in 'outputmedia'" "Error" $true
		}
			
		# Verify that the audio file was archived properly.
		if(Test-Path -LiteralPath $audioArchiveDir$mp3FileName){ 
			Write-Log "Audio successfully archived. Deleting the audio file from the 'outputmedia' folder." "Success" $true
			Remove-Item -LiteralPath "$outputFolder\$mp3FileName" -force -recurse -ErrorAction SilentlyContinue
		} else {
		    Write-Log "Audio archive failed, a copy of the audio is being left in 'outputmedia'" "Error" $true
		}
	}
	
	Function DeleteOutputFiles{

        #region QUESTION: Would you like to upload your video to Vimeo?
		    $title = "Delete Recordings"
		    $message = "Are you sure you want to DELETE all trace of this recording?"

		    $confirm = New-Object System.Management.Automation.Host.ChoiceDescription "&Confirm", `
			    "Delete all Audio and Video files associated with the current recording."

		    $abort = New-Object System.Management.Automation.Host.ChoiceDescription "&Abort", `
			    "Abort the delete process."

		    $options = [System.Management.Automation.Host.ChoiceDescription[]]($confirm, $abort)
		    $deleteOutputFiles = $host.ui.PromptForChoice($title, $message, $options, 1)
			Write-Log $options[$deleteOutputFiles].HelpMessage "Info" $true
	    #endregion

        if($deleteOutputFiles -eq 0){
		    try{
			    Write-Log "Deleting audio and video files from the server." "Info" $true
			    Remove-Item -LiteralPath "$outputFolder\$mp4FileName" -force -recurse -ErrorAction SilentlyContinue
			    Remove-Item -LiteralPath "$outputFolder\$mp3FileName" -force -recurse -ErrorAction SilentlyContinue
		    }catch [system.Exception]{
			    Write-Log "Exception: $_" "Error" $true
		    }		
        } else {
            Write-Log "Delete Aborted, files were left in the 'outputmedia' folder" "Info" $true
        }
	}

#endregion



#Script Start
Write-Log "----------------------------------------------------------" 
$startTime = (Get-Date)
Write-Log "Processing video: $startTime" 

Write-Host "Finishing video process....."  -ForegroundColor Green
Start-Sleep -s 3


#region QUESTION: How would you like to finish processing this recording?
    $title = "Video Post-Processing"
    $message = "How would you like to finish processing this recording?"

    $all = New-Object System.Management.Automation.Host.ChoiceDescription "&All", `
        "Archive this recording, copy the video to a usb drive, and upload it to Vimeo. A local copy will be left in the 'outputmedia' folder."
	
    $choose = New-Object System.Management.Automation.Host.ChoiceDescription "&Choose", `
        "Choose advanced copy options. You will be prompted for each step."
	
    $none = New-Object System.Management.Automation.Host.ChoiceDescription "&None", `
        "Do nothing extra with the recording. A local copy will be left in the 'outputmedia' folder."
	
    $delete = New-Object System.Management.Automation.Host.ChoiceDescription "&Delete", `
        "Discard the recording, no copies will be saved."
	
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($all, $choose, $none, $delete)
    $howToProcess = $host.ui.PromptForChoice($title, $message, $options, 0)

    $userChoice = $options[$howToProcess].HelpMessage
    Write-Log $options[$howToProcess].HelpMessage "Info" $true

#endregion


# Copy to USB
if($howToProcess -eq 0){
	CopyToUSB
	CopyToDropbox
	CopyToNas
}


# Run user through advanced choice options
if($howToProcess -eq 1){


    #region QUESTION Would you like to copy your video to a USB drive?
		# Ask the user if the recording should be copied to the USB Drive
		$title = "Copy to USB"
		$message = "Would you like to copy your video to a USB drive?"

		$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
			"Copy the video to a USB drive"

		$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
			"Will not copy the video to a USB drive"

		$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
		$copyToUsb = $host.ui.PromptForChoice($title, $message, $options, 0)
		Write-Log $options[$copyToUsb].HelpMessage "Info" $true
	#endregion


    #region QUESTION: Would you like to archive your recordings?
		# Ask the user if the recording should be Archived
		$title = "Copy to USB"
		$message = "Would you like to archive your recordings?"

		$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
			"Copy the recordings to the network storage."

		$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
			"Will not copy the recordings to network storage."

		$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
		$copyToNas = $host.ui.PromptForChoice($title, $message, $options, 0)
		Write-Log $options[$copyToNas].HelpMessage "Info" $true
    #endregion


    #region QUESTION: Would you like to upload your video to Vimeo?
		$title = "Copy to USB"
		$message = "Would you like to upload your video to Vimeo?"

		$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
			"Copy the video to the Dropbox folder for automatic upload."

		$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
			"Will not copy the video to the Dropbox folder."

		$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
		$copyToDropbox = $host.ui.PromptForChoice($title, $message, $options, 0)
		Write-Log $options[$copyToDropbox].HelpMessage "Info" $true
	#endregion


	if($copyToUsb -eq 0){ CopyToUsb }
	if($copyToDropbox -eq 0){ CopyToDropbox }
	if($copyToNas -eq 0){ CopyToNas }
	if(($copyToUsb -eq 1) -and ($copyToDropbox -eq 1) -and ($copyToNas = 1)){
		Write-Log "No files were moved, a copy has been left in the 'outputmedia' folder" "Info" $true
	}

}


# ($howToProcess -eq 2) Do Nothing


# Delete the files
if($howToProcess -eq 3){
    DeleteOutputFiles
}


# Thank you for joining us on our adventure today. We hope you liked your experience.
$exitTime = (Get-Date)
Write-Log "Process completed successfully. - $exitTime" "Success" $true 
Write-Host "It is now safe to close this window."
do{}while($true)