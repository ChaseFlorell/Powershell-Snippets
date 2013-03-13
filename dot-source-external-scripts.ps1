# I found this to be a more reliable way of DOT SOURCING external scripts.

$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDirectory some-script.ps1)