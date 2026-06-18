<#
.SYNOPSIS
    Recovers Alienware Command Center (AWCC) keyboard / LED lighting on a Dell G7
    when the FX controls go missing and the backlight won't turn on.

.DESCRIPTION
    Automates the manual recovery that fixed the issue:
      1. Removes phantom / ghost duplicate entries of the RGB lighting controller
         (USB\VID_1532&PID_0039) that confuse AWCC and hide the FX controls.
      2. Best-effort re-initializes the live lighting controller over USB.
      3. Fully stops the (often-wedged) AWCC app + service and re-scans hardware.
      4. Restarts the AWCC service and relaunches the app so it re-detects the
         controller and re-renders the FX color / behavior controls.

    The script self-elevates to Administrator (device ops + pnputil require it).

.NOTES
    Lighting controller on this machine is USB\VID_1532&PID_0039.
    If the laptop / keyboard is ever replaced, update $VidPid below.
    Device InstanceIds are discovered dynamically (their suffixes change per boot),
    so this keeps working across reboots and re-enumerations.
#>

#Requires -Version 5.1

# ----------------------------- Config ------------------------------------
$VidPid      = 'VID_1532&PID_0039'              # RGB lighting controller (Dell G7 / Razer-made)
$AwccPkgName = 'DellInc.AlienwareCommandCenter'  # Microsoft Store package name
# -------------------------------------------------------------------------

# ----------------------------- Self-elevate ------------------------------
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Requesting administrator rights...' -ForegroundColor Yellow
    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"") `
        -Verb RunAs
    exit
}

function Write-Step($n, $msg) { Write-Host "`n[$n] $msg" -ForegroundColor Cyan }
function Write-Info($msg)      { Write-Host "    $msg"      -ForegroundColor Gray }
function Write-Ok($msg)        { Write-Host "    $msg"      -ForegroundColor Green }
function Write-Warn($msg)      { Write-Host "    $msg"      -ForegroundColor Yellow }

Write-Host '=== Alienware Lighting Recovery ===' -ForegroundColor White

# 1. Remove phantom / ghost duplicate controller entries -------------------
Write-Step 1 'Removing phantom (non-present) lighting-controller entries...'
$phantoms = Get-PnpDevice | Where-Object { $_.InstanceId -match $VidPid -and $_.Status -eq 'Unknown' }
if ($phantoms) {
    foreach ($d in $phantoms) {
        Write-Info "remove: $($d.InstanceId)"
        pnputil /remove-device $d.InstanceId | Out-Null
    }
    Write-Ok "Removed $($phantoms.Count) phantom device(s)."
} else {
    Write-Info 'No phantom entries found (good).'
}

# 2. Best-effort re-init of the live controller over USB -------------------
Write-Step 2 'Re-initializing the live lighting controller...'
$live = Get-PnpDevice -PresentOnly | Where-Object {
    $_.InstanceId -match "^USB\\$VidPid\\" -and $_.Status -eq 'OK'
}
if ($live) {
    foreach ($d in $live) {
        Write-Info "restart-device: $($d.InstanceId)"
        pnputil /restart-device $d.InstanceId | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warn 'restart-device not supported here; skipping (phantom cleanup + AWCC restart usually suffices).'
        }
    }
} else {
    Write-Warn 'Live controller not present. A full RESTART (not Shut Down) may be required.'
}

# 3. Stop the (often-wedged) AWCC app + service, then rescan hardware ------
Write-Step 3 'Stopping AWCC app and service...'
Get-Process -Name 'AWCC', 'AWCC.Service' -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Info "kill: $($_.ProcessName) (PID $($_.Id))"
    $_ | Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2
Write-Info 'Re-scanning for hardware changes...'
pnputil /scan-devices | Out-Null

# 4. Restart service and relaunch AWCC ------------------------------------
Write-Step 4 'Restarting AWCC service and relaunching the app...'
Start-Service -Name 'AWCCService' -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$pkg = Get-AppxPackage -Name $AwccPkgName | Select-Object -First 1
if (-not $pkg) { $pkg = Get-AppxPackage -AllUsers -Name $AwccPkgName | Select-Object -First 1 }
if ($pkg) {
    try {
        $appId = (Get-AppxPackageManifest $pkg).Package.Applications.Application.Id
        Start-Process "shell:AppsFolder\$($pkg.PackageFamilyName)!$appId"
        Write-Ok "Launched AWCC ($($pkg.PackageFamilyName))."
    } catch {
        Write-Warn "Couldn't auto-launch AWCC; open it from the Start menu."
    }
} else {
    Write-Warn "AWCC package '$AwccPkgName' not found; open AWCC from the Start menu."
}

Write-Host "`nDone. Open AWCC > FX and check the lights + controls." -ForegroundColor White
Write-Host "If they're still missing, do a full RESTART (Start > Power > Restart --" -ForegroundColor White
Write-Host "NOT Shut Down) and make sure Fast Startup is disabled to stop this recurring." -ForegroundColor White
Write-Host "`nPress any key to close..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
