# Pause the script and wait for the user to press a key to continue
Function Pause($M="Press any key to continue... "){
	If($psISE){
		$S=New-Object -ComObject "WScript.Shell";$B=$S.Popup("Click OK to continue.",0,"Script Paused",0);Return
	};
	Write-Host -NoNewline $M;$I=16,17,18,20,91,92,93,144,145,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183;While($K.VirtualKeyCode -Eq $Null -Or $I -Contains $K.VirtualKeyCode){$K=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")};Write-Host
}