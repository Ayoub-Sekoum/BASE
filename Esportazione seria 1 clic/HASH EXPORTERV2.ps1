Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ConfirmPreference = 'None'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ── GUI Setup ────────────────────────────────────────────────
$form = New-Object System.Windows.Forms.Form
$form.Text = "Autopilot Export"
$form.Size = New-Object System.Drawing.Size(520, 220)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(18, 18, 28)
$form.ForeColor = [System.Drawing.Color]::White
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Windows Autopilot Export"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255)
$lblTitle.Location = New-Object System.Drawing.Point(20, 20)
$lblTitle.Size = New-Object System.Drawing.Size(460, 30)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Initializing..."
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
$lblStatus.Location = New-Object System.Drawing.Point(20, 65)
$lblStatus.Size = New-Object System.Drawing.Size(460, 20)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$progressBar.Style = "Continuous"
$progressBar.Location = New-Object System.Drawing.Point(20, 95)
$progressBar.Size = New-Object System.Drawing.Size(460, 22)
$progressBar.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255)

$lblPercent = New-Object System.Windows.Forms.Label
$lblPercent.Text = "0%"
$lblPercent.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblPercent.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255)
$lblPercent.Location = New-Object System.Drawing.Point(20, 125)
$lblPercent.Size = New-Object System.Drawing.Size(460, 20)
$lblPercent.TextAlign = "MiddleRight"

$lblFooter = New-Object System.Windows.Forms.Label
$lblFooter.Text = ""
$lblFooter.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblFooter.ForeColor = [System.Drawing.Color]::FromArgb(120, 120, 120)
$lblFooter.Location = New-Object System.Drawing.Point(20, 150)
$lblFooter.Size = New-Object System.Drawing.Size(460, 20)

$form.Controls.AddRange(@($lblTitle, $lblStatus, $progressBar, $lblPercent, $lblFooter))

function Update-GUI {
    param($status, $percent)
    $lblStatus.Text = $status
    $progressBar.Value = $percent
    $lblPercent.Text = "$percent%"
    [System.Windows.Forms.Application]::DoEvents()
}

$form.Show()
[System.Windows.Forms.Application]::DoEvents()

# ── Step 1: Read Serial + Save path on USB (same folder as EXE) ──
Update-GUI "Reading BIOS Serial Number..." 10
$SERIAL = (Get-CimInstance Win32_BIOS).SerialNumber

# $Base points to the folder where the EXE is running (the USB)
$Base = [System.AppDomain]::CurrentDomain.BaseDirectory.TrimEnd('\')
$FILEPATH = Join-Path $Base "Autopilot_$SERIAL.csv"

# ── Step 2: Configure Environment ────────────────────────────
Update-GUI "Configuring Environment..." 25
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# ── Step 3: Install NuGet ─────────────────────────────────────
Update-GUI "Installing NuGet Provider..." 45
Install-PackageProvider NuGet -Force -Scope CurrentUser | Out-Null

# ── Step 4: Install Script ────────────────────────────────────
Update-GUI "Installing Get-WindowsAutopilotInfo..." 65
Install-Script Get-WindowsAutopilotInfo -Force -Scope CurrentUser | Out-Null

# ── Step 5: Refresh PATH ──────────────────────────────────────
Update-GUI "Refreshing environment path..." 75
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path","User")

$extraPaths = @(
    "$env:USERPROFILE\Documents\WindowsPowerShell\Scripts",
    "$env:ProgramFiles\WindowsPowerShell\Scripts",
    "$env:USERPROFILE\Documents\PowerShell\Scripts"
)
foreach ($p in $extraPaths) {
    if (Test-Path $p) { $env:Path += ";$p" }
}

# ── Step 6: Find and Run Script, save CSV to USB ─────────────
Update-GUI "Exporting Autopilot Data..." 85

$searchPaths = @(
    "$env:USERPROFILE\Documents\WindowsPowerShell\Scripts\Get-WindowsAutopilotInfo.ps1",
    "$env:ProgramFiles\WindowsPowerShell\Scripts\Get-WindowsAutopilotInfo.ps1",
    "$env:USERPROFILE\Documents\PowerShell\Scripts\Get-WindowsAutopilotInfo.ps1"
)

$scriptPath = $null
foreach ($p in $searchPaths) {
    if (Test-Path $p) {
        $scriptPath = $p
        break
    }
}

if (-not $scriptPath) {
    $scriptPath = Get-ChildItem -Path $env:USERPROFILE -Recurse -Filter "Get-WindowsAutopilotInfo.ps1" `
                  -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1
}

if ($scriptPath) {
    & $scriptPath -OutputFile $FILEPATH
} else {
    [System.Windows.Forms.MessageBox]::Show(
        "Could not find Get-WindowsAutopilotInfo.ps1`nPlease check the installation.",
        "Error", "OK", "Error")
    $form.Close()
    exit
}

# ── Done ──────────────────────────────────────────────────────
Update-GUI "Completed!" 100
$lblFooter.Text = "Saved on USB: Autopilot_$SERIAL.csv"
$lblFooter.ForeColor = [System.Drawing.Color]::FromArgb(80, 200, 120)
[System.Windows.Forms.Application]::DoEvents()

Start-Sleep -Seconds 3
$form.Close()
