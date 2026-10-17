# Sets the AC power mode based on the wattage of the attached USB-C adapter,
# as reported by the Lenovo power service. setup-windows.ps1 registers the
# PowerModeByAdapter scheduled task that runs this on adapter attach and logon.
#   >= 60W  -> Best performance
#   <  60W  -> Balanced (power banks, weak chargers)

$ThresholdW = 60
$BestPerf   = 'ded574b5-45a0-4f42-8737-46345c09c238'
$Balanced   = '00000000-0000-0000-0000-000000000000'
$Log        = Join-Path $env:LOCALAPPDATA 'power-mode-by-adapter.log'

Start-Sleep -Seconds 3  # let the AC status settle after attach

Add-Type -AssemblyName System.Windows.Forms
if ([System.Windows.Forms.SystemInformation]::PowerStatus.PowerLineStatus -ne 'Online') { exit }

$e = Get-WinEvent -FilterHashtable @{ LogName = 'Lenovo-Power-BaseModule/Operational'; Id = 105 } -MaxEvents 1 -ErrorAction SilentlyContinue
if (-not $e -or $e.Message -notmatch '(\d+)W') { exit }
$watts = [int]$Matches[1]

if ($watts -ge $ThresholdW) { $mode = 'Best performance'; $guid = $BestPerf }
else                        { $mode = 'Balanced';         $guid = $Balanced }

powercfg /overlaysetactive $guid
"{0:s}  {1}W adapter -> {2}" -f (Get-Date), $watts, $mode | Add-Content $Log
