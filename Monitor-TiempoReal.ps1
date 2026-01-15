$ErrorActionPreference = "Continue"
Write-Host "MONITOR EN TIEMPO REAL" -ForegroundColor Green
Write-Host "Presiona Ctrl+C para salir" -ForegroundColor Yellow
Write-Host ""
while ($true) {
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue).CounterSamples.CookedValue
    $ram = Get-CimInstance Win32_OperatingSystem
    $ramUsed = [math]::Round(($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory) / 1MB, 2)
    $ramTotal = [math]::Round($ram.TotalVisibleMemorySize / 1MB, 2)
    $ramPercent = [math]::Round(($ramUsed / $ramTotal) * 100, 1)
    $disk = Get-PSDrive C
    $diskUsed = [math]::Round($disk.Used / 1GB, 2)
    $diskFree = [math]::Round($disk.Free / 1GB, 2)
    $diskPercent = [math]::Round(($diskUsed / ($diskUsed + $diskFree)) * 100, 1)
    Clear-Host
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host "   MONITOR EN TIEMPO REAL" -ForegroundColor White
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host ""
    $cpuRounded = [math]::Round($cpu, 1)
    if($cpu -gt 80){$cpuColor="Red"}elseif($cpu -gt 50){$cpuColor="Yellow"}else{$cpuColor="Green"}
    $cpuText = "  CPU:   " + $cpuRounded.ToString() + " porciento"
    Write-Host $cpuText -ForegroundColor $cpuColor
    if($ramPercent -gt 80){$ramColor="Red"}elseif($ramPercent -gt 60){$ramColor="Yellow"}else{$ramColor="Green"}
    $ramText = "  RAM:   " + $ramUsed.ToString() + " GB / " + $ramTotal.ToString() + " GB (" + $ramPercent.ToString() + " porciento)"
    Write-Host $ramText -ForegroundColor $ramColor
    if($diskPercent -gt 90){$diskColor="Red"}elseif($diskPercent -gt 70){$diskColor="Yellow"}else{$diskColor="Green"}
    $diskText = "  DISK:  " + $diskUsed.ToString() + " GB usado / " + $diskFree.ToString() + " GB libre (" + $diskPercent.ToString() + " porciento)"
    Write-Host $diskText -ForegroundColor $diskColor
    Write-Host ""
    Write-Host "  Actualizando cada 2 segundos..." -ForegroundColor Gray
    Start-Sleep -Seconds 2
}
