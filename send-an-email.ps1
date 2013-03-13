# Requires 'base64-conversion.ps1'
$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDirectory base64-conversion.ps1)




Function Send-EMail {
    Param (
        [Parameter(Mandatory=$true)]
        [String]$EmailTo,

        [Parameter(Mandatory=$true)]
        [String]$Subject,

        [Parameter(Mandatory=$true)]
        [String]$Body,

        [Parameter(Mandatory=$true)]
        [String]$EmailFrom="me@example.com",

        [Parameter(mandatory=$true)]
        [String]$Password
    )

        $SMTPServer = "smtp.example.com" 
        $SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom,$EmailTo,$Subject,$Body)
        $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
        $SMTPClient.EnableSsl = $true 
        $SMTPClient.Credentials = New-Object System.Net.NetworkCredential($EmailFrom, $Password); 
        $SMTPClient.Send($SMTPMessage)
        Remove-Variable -Name SMTPClient
        Remove-Variable -Name Password

} #End Function Send-EMail

Send-EMail -EmailFrom "me@example.com"`
           -EmailTo "me@example.com"`
           -Body "Test Body"`
           -Subject "Test Subject"`
           -Password (Base64-Decode "SGVsbG8gV29ybGQ=") # This isn't "secure" but at least it's not plain text.

# To get the Base64 representation of your password, just go to
# http://www.opinionatedgeek.com/dotnet/tools/base64encode/