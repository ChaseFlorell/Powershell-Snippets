# Execute MSBuild against .NET 4.0
$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path
$solutionName = "MySolution.sln"
$v4_net_version = (ls "$env:windir\Microsoft.NET\Framework\v4.0*").Name

# Debug
cmd /c C:\Windows\Microsoft.NET\Framework\$v4_net_version\msbuild.exe "$directorypath\$solutionName" /p:Configuration=Debug 

#Release
cmd /c C:\Windows\Microsoft.NET\Framework\$v4_net_version\msbuild.exe "$directorypath\$solutionName" /p:Configuration=Release 