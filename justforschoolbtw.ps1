# Requires Administrator Rights
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Run this script as Administrator!" -ForegroundColor Red
    Pause
    Exit
}

Clear-Host
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "     BENQ USB UNLOCKER - BY:Ahmetchimp     " -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Enable USBSTOR Service
Write-Host "[*] Enabling USBSTOR service..." -ForegroundColor Cyan
$usbStorPath = "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR"
if (-not (Test-Path $usbStorPath)) {
    New-Item -Path $usbStorPath -Force | Out-Null
}
Set-ItemProperty -Path $usbStorPath -Name "Start" -Value 3 -Type DWord -ErrorAction SilentlyContinue
Set-Service -Name "USBSTOR" -StartupType Manual -ErrorAction SilentlyContinue
Start-Service -Name "USBSTOR" -ErrorAction SilentlyContinue
Write-Host "[+] USBSTOR service status: ACTIVE" -ForegroundColor Green

# 2. Clear Removable Storage Policies (GPO / Registry)
Write-Host "[*] Resetting USB policies..." -ForegroundColor Cyan
$policyPaths = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
)

foreach ($path in $policyPaths) {
    if (Test-Path $path) {
        Remove-ItemProperty -Path $path -Name "Deny_All" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $path -Name "Deny_Read" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $path -Name "Deny_Write" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $path -Name "NoDrives" -ErrorAction SilentlyContinue
    }
}
Write-Host "[+] Storage policies cleared." -ForegroundColor Green

# 3. Enable Disabled USB PnP Controllers & Devices
Write-Host "[*] Scanning for disabled USB devices..." -ForegroundColor Cyan
$disabledDevices = Get-PnpDevice -Class "USB" -ErrorAction SilentlyContinue | Where-Object { $_.Status -ne "OK" }

if ($disabledDevices) {
    foreach ($dev in $disabledDevices) {
        try {
            Enable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction Stop
            Write-Host "[+] Enabled: $($dev.FriendlyName)" -ForegroundColor Green
        } catch {
            Write-Host "[-] Could not enable: $($dev.InstanceId)" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "[+] No disabled USB hardware found." -ForegroundColor Green
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " SUCCESS: USB ports unlocked. Reboot system." -ForegroundColor Yellow
Write-Host " BY:Ahmetchimp" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Pause