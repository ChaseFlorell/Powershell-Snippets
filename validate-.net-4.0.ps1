# Validate whether or not the .NET Framework version 4.0 is installed on the local computer.

if( (ls "$env:windir\Microsoft.NET\Framework\v4.0*") -eq $null ) {
	throw "This project requires .NET 4.0 to compile. Unfortunatly .NET 4.0 doesn't appear to be installed on this machine."
}