#Requires AutoHotkey v2.0
#SingleInstance Force
; #WinActivateForce

DetectHiddenWindows(True)

; 强制关闭 CapsLock 的大写锁定状态，避免干扰
SetCapsLockState("AlwaysOff")

; --- 单独按下 CapsLock 发送 Esc ---
*CapsLock::
{
    ; 等待 CapsLock 被释放
    KeyWait "CapsLock"

    ; 如果在按下到释放期间，你没有按过其他任何键，则判定为单独按下
    if (A_PriorKey == "CapsLock") {
        Send "{Blind}{Esc}"
    }
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
GroupAdd "TabeSwitchApp", "ahk_exe WindowsTerminal.exe"

#HotIf WinActive("ahk_group TabeSwitchApp")
    ; Ctrl + ] 切换到下一个标签页
    CapsLock & ]::Send("^{Tab}")
    ; Ctrl + [ 切换到上一个标签页
    CapsLock & [::Send("^+{Tab}")
#HotIf

; 在 Brave 浏览器中 Win+][ => Alt+][ 前进/后退
#HotIf WinActive("Brave ahk_exe brave.exe")
    ![::Send("!{Left}")
    !]::Send("!{Right}")
    !1::Send("^{1}")
    !2::Send("^{2}")
    !3::Send("^{3}")
    !4::Send("^{4}")
    !5::Send("^{5}")
    !6::Send("^{6}")
    !7::Send("^{7}")
    !8::Send("^{8}")
    !9::Send("^{9}")
#HotIf

#HotIf WinActive("ahk_exe idea64.exe")
    CapsLock & [::Send("^!+{[}")
    CapsLock & ]::Send("^!+{]}")
    CapsLock & 1::Send("^!{1}")
    CapsLock & 2::Send("^!{2}")
    CapsLock & 3::Send("^!{3}")
    CapsLock & 4::Send("^!{4}")
    CapsLock & 5::Send("^!{5}")
    CapsLock & 6::Send("^!{6}")
    CapsLock & 7::Send("^!{7}")
    CapsLock & 8::Send("^!{8}")
    CapsLock & 9::Send("^!{9}")
    CapsLock & 0::Send("^!{0}")

    #e::Send("^e")
    #+f::Send("^+f")
    #+r::Send("^+r")
    #f::Send("^f")
    #r::Send("^r")
    CapsLock & w::Send("^{f4}")
    #w::Send("^{f4}")
    !w::Send("^{f4}")
#HotIf

#HotIf !WinActive("ahk_exe idea64.exe")
    !w::Send("^{w}")
#HotIf


#HotIf WinActive("ahk_exe wezterm-gui.exe")
    !c::Send("^+{c}")
    !v::Send("^+{v}")
#HotIf
#HotIf !WinActive("ahk_exe wezterm-gui.exe")
    !c::Send("^{c}")
    !v::Send("^{v}")
#HotIf

; #HotIf WinActive("Emacs ahk_exe msrdc.exe")
;     CapsLock & Space::Send("^{\}")
; #HotIf

; #HotIf !WinActive("Emacs ahk_exe msrdc.exe")
;     CapsLock & Space::Send("{LAlt down}{LShift down}{LShift up}{LAlt up}")
; #HotIf

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
  state := WinGetMinMax("A")
  ; 1 表示当前是最大化状态
  if (state != 0)
      WinRestore("A")
  else
      WinMaximize("A")
}

!q::
{
  WinClose("A")
}
CapsLock & w::Send("^{w}")
CapsLock & r::Send("^{r}")
CapsLock & a::Send("^{a}")

; #1::Send("^{1}")
; #2::Send("^{2}")
; #3::Send("^{3}")
; #4::Send("^{4}")
; #5::Send("^{5}")
; #6::Send("^{6}")
; #7::Send("^{7}")
; #8::Send("^{8}")
; #9::Send("^{9}")
!f::Send("^{f}")

; WinTab => AltTab
<#Tab::AltTab

; ==========================================
; 触发 app
ToggleApp(winTitle, exeName, workingDir?, Options?)
{
    if WinActive(winTitle)
    {
        WinActivate(winTitle)
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
    ToggleApp("飞书 ahk_exe Feishu.exe", ProgramFilesX86 . A_AppData . "\..\Local\Feishu\Feishu.exe")
}
CapsLock & e::
{
    ToggleApp("ahk_exe explorer.exe ahk_class CabinetWClass", "explorer.exe")
}
CapsLock & s::
{
    ToggleApp("ahk_exe ApplicationFrameHost.exe ahk_class ApplicationFrameWindow", "ms-settings:")
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
CapsLock & y::
{
   ToggleApp("ahk_exe Spotify.exe", "Spotify.exe")
}
; ==========================================

~F9:: {
    TrayTip "AHK 脚本正在重新加载...", "系统提示", 4
    Sleep 500
    Reload()
}


; 定义全局变量
global activeWindows := []       ; 存储过滤后的有效窗口ID
global currentIndex := 0         ; 当前窗口索引
global lastPressTime := 0        ; 上次按键时间
global timeoutThreshold := 1500  ; 1.5秒超时

; 辅助函数：检测窗口是否被 Windows 隐藏（针对 UWP 应用如应用商店、设置等）
DmGetWindowCloaked(hwnd) {
    cloaked := 0
    ; DWMWA_CLOAKED = 14
    res := DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 14, "Ptr*", &cloaked, "UInt", 4)
    return (res == 0) ? cloaked : 0
}


; ==============================================================================
; 输入法切换
; ==============================================================================
; #HotIf WinActive("ahk_exe emacs.exe")
;     CapsLock & Space::send("^{\}")
; #HotIf

; #HotIf !WinActive("ahk_exe emacs.exe")
;     CapsLock & Space::send("^{space}")
; #HotIf

; 长按“后退”侧键 -> 屏幕连续【向右】滚动
XButton1:: {
    while GetKeyState("XButton1", "P") {
        Send("{WheelRight}")
        Sleep(40) ; 滚动速度，数值越小越快
    }
}

; 长按“前进”侧键 -> 屏幕连续【向左】滚动
XButton2:: {
    while GetKeyState("XButton2", "P") {
        Send("{WheelLeft}")
        Sleep(40)
    }
}

CapsLock & Space::send("^{space}")