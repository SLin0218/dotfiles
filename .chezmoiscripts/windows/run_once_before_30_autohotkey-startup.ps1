# 1. 动态获取当前 Windows 的用户开机启动文件夹路径
$startupFolder = [System.IO.Path]::Combine($env:APPDATA, 'Microsoft\Windows\Start Menu\Programs\Startup')
$shortcutPath = [System.IO.Path]::Combine($startupFolder, 'AutoHotkey.lnk')

# 2. 定位到你在 Chezmoi 中托管的实际 AHK 启动脚本
$targetScript = [System.IO.Path]::Combine($env:USERPROFILE, '.config\autohotkey\main.ahk')

# 如果目标脚本不存在，说明尚未部署，直接跳过
if (-not (Test-Path -Path $targetScript)) {
    Write-Host "Warning: $targetScript not found, skipping shortcut creation."
    Exit 0
}

Write-Host "Creating startup shortcut for AutoHotkey..."

# 3. 使用 WScript.Shell 动态创建快捷方式
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $targetScript

# 4. 最关键的避坑设置：7 代表“最小化运行”，完美消除开机瞬间的 CMD 黑框弹窗
$Shortcut.WindowStyle = 7

# 5. 保存快捷方式
$Shortcut.Save()

Write-Host "Startup shortcut created successfully at: $shortcutPath"
