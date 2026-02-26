$ConfirmPreference = 'None'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Step tracking
$steps = @(
    "Reading BIOS Serial Number",
    "Configuring Environment",
    "Installing NuGet Provider",
    "Installing Get-WindowsAutopilotInfo",
    "Exporting Autopilot Data"
)
$totalSteps = $steps.Count

function Show-Progress {
    param($step, $status, $percent)
    Write-Progress -Activity "Autopilot Export" `
                   -Status "Step $step/$totalSteps - $status" `
                   -PercentComplete $percent
}

# Step 1
Show-Progress 1 $steps[0] 10
$SERIAL = (Get-CimInstance Win32_BIOS).SerialNumber
Start-Sleep -Milliseconds 300

# Step 2
Show-Progress 2 $steps[1] 25
$Base = [System.AppDomain]::CurrentDomain.BaseDirectory.TrimEnd('\')
$FILEPATH = Join-Path $Base "Autopilot_$SERIAL.csv"
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Start-Sleep -Milliseconds 300

# Step 3
Show-Progress 3 $steps[2] 45
$ProgressPreference = 'SilentlyContinue'
Install-PackageProvider NuGet -Force -Scope CurrentUser | Out-Null
$ProgressPreference = 'SilentlyContinue'

# Step 4
Show-Progress 4 $steps[3] 65
Install-Script Get-WindowsAutopilotInfo -Force -Scope CurrentUser | Out-Null

# Step 5
Show-Progress 5 $steps[4] 85
Get-WindowsAutopilotInfo -OutputFile $FILEPATH

# Completed
Write-Progress -Activity "Autopilot Export" -Status "Completed!" -PercentComplete 100
Start-Sleep -Milliseconds 500
Write-Progress -Activity "Autopilot Export" -Completed

Write-Host "`n✅ Export completed: $FILEPATH" -ForegroundColor Green
