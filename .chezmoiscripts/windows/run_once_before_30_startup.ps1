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

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $targetScript
$Shortcut.WindowStyle = 7
$Shortcut.Save()
Write-Host "✅ autohotkey 开机自启快捷方式已成功创建！" -ForegroundColor Green


$targetPath = "$env:USERPROFILE\scoop\apps\wsl-ssh-pageant\current\wsl-ssh-pageant-gui.exe"
$arguments  = "--systray --winssh openssh-ssh-agent"
$shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\wsl-ssh-pageant.lnk"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $targetPath
$Shortcut.Arguments = $arguments
$Shortcut.WorkingDirectory = "$env:USERPROFILE"
$Shortcut.Save()

Write-Host "✅ wsl-ssh-pageant 开机自启快捷方式已成功创建！" -ForegroundColor Green

# 3. PinentryForWindows (PFW) Broker 开机自启动（注册表 Run 项）
$pfwBinary = "$env:USERPROFILE\scoop\apps\gnupg\current\bin\pfw.x64.exe"
$pfwBrokerDir = "$env:LOCALAPPDATA\PinentryForWindows\broker"
$pfwArgs = "--broker `"$pfwBrokerDir`""
$pfwShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\PinentryForWindowsBroker.lnk"

# 清理可能残留的重复快捷方式（避免与注册表 Run 项重复）
if (Test-Path $pfwShortcut) {
    Remove-Item $pfwShortcut -Force -ErrorAction SilentlyContinue
}

if (Test-Path $pfwBinary) {
    # 采用官方标准的注册表 HKCU 启动项
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "PinentryForWindowsBroker" -Value "`"$pfwBinary`" $pfwArgs"
    Write-Host "✅ PinentryForWindows Broker 开机自启配置成功（注册表 Run 项）！" -ForegroundColor Green
}

