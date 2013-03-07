# Check if a USB jump drive is inserted in the local computer.
do {
  	$UsbDisk = gwmi win32_diskdrive | ?{$_.interfacetype -eq "USB"} | %{gwmi -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($_.DeviceID.replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition"} |  %{gwmi -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($_.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"} | %{$_.deviceid} 
	if ( $UsbDisk -eq $null ) {  
		Write-Host "There is no USB drive detected, please insert a USB drive"
		# Use Pause.ps1 to have the user "press any key to continue"
		# DO NOT RUN THIS WITHOUT SOME SORT OF "PAUSE" function, otherwise this will loop until a USB stick is inserted.
	}
}
while ($UsbDisk -eq $null)

# After the do loop, $UsbDisk will be the name of the drive letter (example: E:)