# Read project overview
$base = "F:\LarkDesign1\原型设计"
Write-Host "=== 项目文件树 ==="
Get-ChildItem $base -Name -Recurse -Depth 2 | Where-Object {$_ -notmatch 'node_modules|\.git|\.yunque'} | ForEach-Object { Write-Output $_ }
Write-Host "=== WorkspaceLayout.vue (前2000字符) ==="
$c = Get-Content "$base\src\components\WorkspaceLayout.vue" -Raw
Write-Host $c.Substring(0, [Math]::Min(2000, $c.Length))
Write-Host "=== 技术可行性研究报告 (前3000字符) ==="
$r = Get-Content "$base\技术可行性研究报告.md" -Raw
Write-Host $r.Substring(0, [Math]::Min(3000, $r.Length))