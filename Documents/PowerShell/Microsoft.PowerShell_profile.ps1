# =====================================================================
# 编码与环境初始化 (解决中文乱码)
# =====================================================================
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# =====================================================================
# PSReadLine 智能补全与历史记录 (体验类似 Zsh)
# =====================================================================
if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Emacs

    # 开启类似 zsh-autosuggestions 的历史命令灰色预测
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle InlineView

    # Tab 键触发类 Linux 的网格菜单补全
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

    # 上下方向键根据已输入字符筛选历史记录
    Set-PSReadLineKeyHandler -Key UpArrow -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::HistorySearchBackward()
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    }

    Set-PSReadLineKeyHandler -Key DownArrow -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::HistorySearchForward()
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    }

    # 更改预测文本颜色为暗灰色
    Set-PSReadLineOption -Colors @{ InlinePrediction = "$([char]0x1b)[38;5;244m" }

    # -----------------------------------------------------------------
    # FZF 模糊搜索集成 (类似 Linux Zsh 体验)
    # -----------------------------------------------------------------
    if (Get-Module -ListAvailable PSFzf) {
        Import-Module PSFzf

        if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
            Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
        }

        # 替换 Tab 键：触发自动提示时，直接调用 fzf 进行交互式筛选 (极度丝滑)
        Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
            Invoke-FzfTabCompletion
        }
    } else {
        # 如果未检测到 PSFzf，降级使用类 Linux 的标准网格菜单补全
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    }

}

# =====================================================================
# Starship 提示符美化引擎集成
# =====================================================================
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
} else {
    Write-Host "提示: 未检测到 starship，请运行 'winget install starship' 安装。" -ForegroundColor Yellow
}

function gbash {
    & '~\scoop\apps\git\current\bin\bash.exe' @args
}

Set-Alias -Name vim -Value nvim
Set-Alias -Name ls -Value exa
Set-Alias -Name vim -Value nvim
Set-Alias -Name fetch -Value fastfetch

function ll {
  exa -al @args
}

function l {
  exa -l @args
}

function gst { git status @args }
function gl { git pull @args }
function gcl { git clone @args }
function gcms { git commit -m @args }
function gp { git puth @args }

# 自动完成
$CompletionDir = Join-Path (Split-Path $PROFILE) "completions"
if (Test-Path $CompletionDir) {
    Get-ChildItem (Join-Path $CompletionDir "*.ps1") | ForEach-Object { . $_.FullName }
}

# =============================================================================
#
# Utility functions for zoxide.
#

# Call zoxide binary, returning the output as UTF-8.
function global:__zoxide_bin {
    $encoding = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.Utf8Encoding]::new()
        $result = zoxide @args
        return $result
    } finally {
        [Console]::OutputEncoding = $encoding
    }
}

# pwd based on zoxide's format.
function global:__zoxide_pwd {
    $cwd = Microsoft.PowerShell.Management\Get-Location
    if ($cwd.Provider.Name -eq "FileSystem") {
        $cwd.ProviderPath
    }
}

# cd + custom logic based on the value of _ZO_ECHO.
function global:__zoxide_cd($dir, $literal) {
    $dir = if ($literal) {
        if ($null -eq $dir) {
            Microsoft.PowerShell.Management\Set-Location
        } else {
            Microsoft.PowerShell.Management\Set-Location -LiteralPath $dir -Passthru -ErrorAction Stop
        }
    } else {
        if ($dir -eq '-' -and ($PSVersionTable.PSVersion -lt 6.1)) {
            Microsoft.PowerShell.Utility\Write-Error "cd - is not supported below PowerShell 6.1. Please upgrade your version of PowerShell."
        }
        elseif ($dir -eq '+' -and ($PSVersionTable.PSVersion -lt 6.2)) {
            Microsoft.PowerShell.Utility\Write-Error "cd + is not supported below PowerShell 6.2. Please upgrade your version of PowerShell."
        }
        else {
            Microsoft.PowerShell.Management\Set-Location -Path $dir -Passthru -ErrorAction Stop
        }
    }
}

# =============================================================================
#
# Hook configuration for zoxide.
#

# Hook to add new entries to the database.
$global:__zoxide_oldpwd = __zoxide_pwd
function global:__zoxide_hook {
    $result = __zoxide_pwd
    if ($result -ne $global:__zoxide_oldpwd) {
        if ($null -ne $result) {
            zoxide add "--" $result
        }
        $global:__zoxide_oldpwd = $result
    }
}

# Initialize hook.
$global:__zoxide_hooked = (Microsoft.PowerShell.Utility\Get-Variable __zoxide_hooked -ErrorAction Ignore -ValueOnly)
if ($global:__zoxide_hooked -ne 1) {
    $global:__zoxide_hooked = 1
    $global:__zoxide_prompt_old = $function:prompt

    function global:prompt {
        if ($null -ne $__zoxide_prompt_old) {
            & $__zoxide_prompt_old
        }
        $null = __zoxide_hook
    }
}

# =============================================================================
#
# When using zoxide with --no-cmd, alias these internal functions as desired.
#

# Jump to a directory using only keywords.
function global:__zoxide_z {
    if ($args.Length -eq 0) {
        __zoxide_cd $null $true
    }
    elseif ($args.Length -eq 1 -and ($args[0] -eq '-' -or $args[0] -eq '+')) {
        __zoxide_cd $args[0] $false
    }
    elseif ($args.Length -eq 1 -and (Microsoft.PowerShell.Management\Test-Path -PathType Container -LiteralPath $args[0])) {
        __zoxide_cd $args[0] $true
    }
    elseif ($args.Length -eq 1 -and (Microsoft.PowerShell.Management\Test-Path -PathType Container -Path $args[0] )) {
        __zoxide_cd $args[0] $false
    }
    else {
        $result = __zoxide_pwd
        if ($null -ne $result) {
            $result = __zoxide_bin query --exclude $result "--" @args
        }
        else {
            $result = __zoxide_bin query "--" @args
        }
        if ($LASTEXITCODE -eq 0) {
            __zoxide_cd $result $true
        }
    }
}

# Jump to a directory using interactive search.
function global:__zoxide_zi {
    $result = __zoxide_bin query -i "--" @args
    if ($LASTEXITCODE -eq 0) {
        __zoxide_cd $result $true
    }
}

# =============================================================================
#
# Commands for zoxide. Disable these using --no-cmd.
#

Microsoft.PowerShell.Utility\Set-Alias -Name z -Value __zoxide_z -Option AllScope -Scope Global -Force
Microsoft.PowerShell.Utility\Set-Alias -Name zi -Value __zoxide_zi -Option AllScope -Scope Global -Force

# =============================================================================
#
# To initialize zoxide, add this to your configuration (find it by running
# `echo $profile` in PowerShell):
#
# Invoke-Expression (& { (zoxide init powershell | Out-String) })
