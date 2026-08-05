$conns = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in 5173,5174,5175,5176,5177,5178 }
foreach ($c in $conns) {
  Write-Host "Killing PID $($c.OwningProcess) on port $($c.LocalPort)"
  Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
}
Write-Host 'Done killing dev servers'
