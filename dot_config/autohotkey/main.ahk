#Requires AutoHotkey v2.0
#SingleInstance Force
; #WinActivateForce

DetectHiddenWindows(True)

; 强制关闭 CapsLock 的大写锁定状态，避免干扰
SetCapsLockState("AlwaysOff")

; --- 单独按下 CapsLock 发送 Esc ---
*CapsLock::
{
    Send "{Blind}{Esc}"
}

ProgramFiles := "C:\Program Files\"
ProgramFilesX86 := "C:\Program Files (x86)\"

; 示例：使用 Hyper Key 组合键快捷操作
; Hyper + H/J/K/L 方向键映射

; 禁用单独按下 WIN
; ~LWin::Send("{Blind}{vkE8}")

; ==========================================
; 仅在指定 app 中生效的快捷键
; ==========================================
GroupAdd "TabeSwitchApp", "ahk_exe wezterm-gui.exe"
GroupAdd "TabeSwitchApp", "Brave ahk_exe brave.exe"

#HotIf WinActive("ahk_group TabeSwitchApp")
    ; Ctrl + ] 切换到下一个标签页
    CapsLock & ]::Send("^{Tab}")
    ; Ctrl + [ 切换到上一个标签页
    CapsLock & [::Send("^+{Tab}")
#HotIf

; ==========================================
; Win + H/J/K/L
; ==========================================
CapsLock & k::Send("{Up}")
CapsLock & j::Send("{Down}")
CapsLock & h::Send("{Left}")
CapsLock & l::Send("{Right}")

CapsLock & t::Send("^{t}")
CapsLock & f::
{
  WinMaximize("A")
}

#q::
{
  WinClose("A")
}
#w::Send("^{w}")
#r::Send("^{r}")
#a::Send("^{a}")
#f::Send("^{f}")
#1::Send("^{1}")
#2::Send("^{2}")
#3::Send("^{3}")
#4::Send("^{4}")
#5::Send("^{5}")
#6::Send("^{6}")
#7::Send("^{7}")
#8::Send("^{8}")
#9::Send("^{9}")

; 在 Brave 浏览器中 Win+][ => Alt+][ 前进/后退
#HotIf WinActive("Brave ahk_exe brave.exe")
    #[::Send("!{Left}")
    #]::Send("!{Right}")
#HotIf

; WinTab => AltTab
<#Tab::AltTab

#HotIf WinActive("ahk_exe idea64.exe")
    CapsLock & [::Send("!{Left}")
    CapsLock & ]::Send("!{Right}")
    #1::Send("!{1}")
    #2::Send("!{2}")
    #3::Send("!{3}")
    #4::Send("!{4}")
    #5::Send("!{5}")
    #6::Send("!{6}")
    #7::Send("!{7}")
    #8::Send("!{8}")
    #9::Send("!{9}")
    #0::Send("!{0}")
    #e::Send("^e")
    #+f::Send("^+f")
    #+r::Send("^+r")
    #f::Send("^f")
    #r::Send("^r")
    #w::Send("^{f4}")
#HotIf

#HotIf WinActive("ahk_exe wezterm-gui.exe")
    #c::Send("^+{c}")
    #v::Send("^+{v}")
#HotIf
#HotIf !WinActive("ahk_exe wezterm-gui.exe")
    #c::Send("^{c}")
    #v::Send("^{v}")
#HotIf

; ==========================================
; 触发 app
; ==========================================
ToggleApp(winTitle, exeName, workingDir?, Options?)
{
    if WinActive(winTitle)
    {
        WinMinimize(winTitle)
    }
    else if WinExist(winTitle)
    {
        WinActivate(winTitle)
    }
    else
    {
        Run(exeName, workingDir?, Options?)
    }
}


CapsLock & i::
{
    ToggleApp("ahk_exe wezterm-gui.exe", "wezterm-gui.exe")
}
CapsLock & g::
{
    ToggleApp("Brave ahk_exe brave.exe", "brave.exe")
}
CapsLock & n::
{
    ToggleApp("\s-\s ahk_exe idea64.exe", ProgramFiles . "JetBrains\IntelliJ IDEA 2026.2.1\bin\idea64.exe")
}
CapsLock & u::
{
    ToggleApp("WeLink ahk_exe WeLink.exe", ProgramFilesX86 . "WeLink\WeLink.exe")
}
CapsLock & e::
{
    ToggleApp("ahk_exe explorer.exe ahk_class CabinetWClass", "explorer.exe")
}
CapsLock & o::
{
    ToggleApp("ahk_class WeWorkWindow", ProgramFilesX86 . "WXWork\WXWork.exe", ,"Max")
}
CapsLock & m::
{
   ;; ToggleApp("Emacs ahk_exe msrdc.exe", "wsl.exe -- emacs", , "Hide")
   ToggleApp("ahk_exe emacs.exe", "runemacs.exe", EnvGet("HOME"))
}
; CapsLock & y::
; {
;    ToggleApp("qqmusic ahk_exe msrdc.exe", "wsl.exe -- qqmusic", , "Hide")
; }

#HotIf WinActive("Emacs ahk_exe msrdc.exe")
    CapsLock & Space::Send("^{\}")
#HotIf

#HotIf !WinActive("Emacs ahk_exe msrdc.exe")
    CapsLock & Space::Send("{LAlt down}{LShift down}{LShift up}{LAlt up}")
#HotIf

~F5:: {
    TrayTip "AHK 脚本正在重新加载...", "系统提示", 4
    Sleep 500
    Reload()
}


; 定义全局变量
global activeWindows := []       ; 存储过滤后的有效窗口ID
global currentIndex := 0         ; 当前窗口索引
global lastPressTime := 0        ; 上次按键时间
global timeoutThreshold := 1500  ; 1.5秒超时

#`:: {
    global activeWindows, currentIndex, lastPressTime, timeoutThreshold
    currentTime := A_TickCount
    timeElapsed := currentTime - lastPressTime
    ; 1. 如果超时或首次按下，重新获取并进行【深度过滤】
    if (timeElapsed > timeoutThreshold || activeWindows.Length == 0) {
        try {
            activeProcess := WinGetProcessName("A")
        } catch {
            return
        }
        ; 获取当前进程的所有窗口
        allWindows := WinGetList("ahk_exe " activeProcess)
        activeWindows := []
        for id in allWindows {
            ; --- 核心过滤逻辑：必须同时满足以下 4 个条件才是肉眼可见的正常窗口 ---
            title := WinGetTitle("ahk_id " id)
            style := WinGetStyle("ahk_id " id)
            exStyle := WinGetExStyle("ahk_id " id)
            ; 条件 1: 必须有窗口标题
            if (title == "")
                continue
            ; 条件 2: 必须包含 WS_VISIBLE 样式（0x10000000 即真正可见）
            if !(style & 0x10000000)
                continue
            ; 条件 3: 排除 WS_EX_TOOLWINDOW（工具悬浮窗/托盘等无任务栏图标窗口）
            if (exStyle & 0x00000080)
                continue
            ; 条件 4: 排除 Windows 10/11 的 UWP 虚拟挂起窗口 (Cloaked)
            try {
                isCloaked := DmGetWindowCloaked(id)
                if (isCloaked)
                    continue
            }
            ; 完美通过筛选，加入切换队列
            activeWindows.Push(id)
        }
        ; 如果过滤后没有足够多的有效窗口，直接退出
        if (activeWindows.Length <= 1) {
            activeWindows := []
            return
        }
        ; 第一次按，从第 1 个（当前活动窗口）开始计数
        currentIndex := 1
    }
    ; 2. 完美的索引循环
    currentIndex := currentIndex + 1
    if (currentIndex > activeWindows.Length) {
        currentIndex := 1
    }
    ; 3. 激活目标窗口
    targetWindow := activeWindows[currentIndex]
    if WinExist("ahk_id " targetWindow) {
        WinActivate("ahk_id " targetWindow)
    } else {
        activeWindows := [] ; 防错重置
    }
    lastPressTime := A_TickCount
}

; 辅助函数：检测窗口是否被 Windows 隐藏（针对 UWP 应用如应用商店、设置等）
DmGetWindowCloaked(hwnd) {
    cloaked := 0
    ; DWMWA_CLOAKED = 14
    res := DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 14, "Ptr*", &cloaked, "UInt", 4)
    return (res == 0) ? cloaked : 0
}


; ==============================================================================
; ==============================================================================
; 0x04090409 = 美式布局
; 0x08040804 = 中文布局
SwitchToEnglish() {
    hwnd := WinActive("A")
    if (hwnd)
        PostMessage(0x0050, 0, 0x04090409, , "ahk_id " hwnd)
}

SwitchToChinese() {
    hwnd := WinActive("A")
    if (hwnd)
        PostMessage(0x0050, 0, 0x08040804, , "ahk_id " hwnd)
}

global EngApps := [
    "emacs.exe",
    "Code.exe",
    "WindowsTerminal.exe",
    "cmd.exe",
    "powershell.exe",
    "wezterm-gui.exe",
    "brave.exe",
    "idea64.exe"
]

global ChnApps := [
    "WeChat.exe",
    "WXWork.exe",
    "WINWORD.EXE",
    "DingTalk.exe",
    "Feishu.exe",
    "WeLink.exe"
]

global lastHwnd := 0

SetTimer(AutoSwitchIME, 200)

AutoSwitchIME() {
    global lastHwnd
    hwnd := WinActive("A")
    if (!hwnd || hwnd == lastHwnd)
        return
    lastHwnd := hwnd

    try {
        procName := WinGetProcessName("ahk_id " hwnd)

        for app in EngApps {
            if (procName = app) {
                SwitchToEnglish()
                return
            }
        }

        for app in ChnApps {
            if (procName = app) {
                SwitchToChinese()
                return
            }
        }
    }
}