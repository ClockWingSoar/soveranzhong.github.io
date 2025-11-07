# 模拟sed命令处理空白行的PowerShell脚本

Write-Host "=== 原始文件内容 ==="
Get-Content mixed_blank.txt

Write-Host "`n=== 仅删除纯空行（模拟 sed '/^$/d'）==="
Get-Content mixed_blank.txt | Where-Object { $_ -notmatch '^$' }

Write-Host "`n=== 删除所有空白行（模拟 sed '/^[[:space:]]*$/d'）==="
Get-Content mixed_blank.txt | Where-Object { $_ -notmatch '^\s*$' }

Write-Host "`n=== 文件十六进制表示（展示不同类型的空白行）==="
Format-Hex -Path mixed_blank.txt