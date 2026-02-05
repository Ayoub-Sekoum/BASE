$ConfirmPreference = 'None'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$SERIAL = (Get-CimInstance Win32_BIOS).SerialNumber
$Base = [System.AppDomain]::CurrentDomain.BaseDirectory.TrimEnd('\')
$FILEPATH = Join-Path $Base "Autopilot_$SERIAL.csv"

$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Install-PackageProvider NuGet -Force -Scope CurrentUser | Out-Null
Install-Script Get-WindowsAutopilotInfo -Force -Scope CurrentUser | Out-Null

Get-WindowsAutopilotInfo -OutputFile $FILEPATH
