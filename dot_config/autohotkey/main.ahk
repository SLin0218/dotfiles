#Requires AutoHotkey v2.0
#SingleInstance Force

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
    !e::Send("^e")
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

; 当 Alt+Tab 切换窗口的界面处于激活状态时，启用以下映射
#HotIf WinActive("ahk_class XamlExplorerHostIslandWindow") or WinActive("ahk_class TaskSwitcherWnd")
; ! 代表 Alt 键，{Blind} 确保发送按键时 Alt 键一直保持按下状态
!h::Send("{Blind}{Shift Down}{Tab}{Shift Up}")   ; 向左移动
!l::Send("{Blind}{Tab}")                         ; 向右移动
!k::Send("{Blind}{Up}")                          ; 向上移动
!j::Send("{Blind}{Down}")                        ; 向下移动

#HotIf
; ==========================================


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

; !q::
; {
;   WinClose("A")
; }
; 长按 Alt + Q 关闭当前窗口进程
!q::
{
    ; 等待 q 键被释放。t0.5 表示长按 0.5 秒触发，可以根据习惯修改这个时间
    if !KeyWait("q", "T1.5")
    {
        try {
            pname := WinGetProcessName("A")
            if (pname = "wps.exe")
            {
                try {
                    ProcessClose("wps.exe")
                }
                try {
                    ProcessClose("wpscloudsvr.exe")
                }
                try {
                    ProcessClose("wpscenter.exe")
                }
            }
            else
            {
                pid := WinGetPID("A")
                ProcessClose(pid)
            }
            ; 成功关闭后等待用户完全释放 q 键，防止连续触发
            KeyWait("q")
        }
    }
    else
    {
        ; 【短按逻辑】在 1.5 秒内释放了按键，正常关闭当前窗口
        try {
            WinClose("A")
        }
    }
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
    DetectHiddenWindows(False)
    if WinActive(winTitle)
    {
        ; TrayTip("Active winTitle: " . winTitle, "Debug", 4)
        WinActivate(winTitle)
    }
    else if WinExist(winTitle)
    {
        ; TrayTip("Exist winTitle: " . winTitle, "Debug", 4)
        WinActivate(winTitle)
    }
    else
    {
        Run(exeName, workingDir?, Options?)
    }
    DetectHiddenWindows(True)
}

CapsLock & i::
{
    ToggleApp("ahk_exe wezterm-gui.exe ahk_class org.wezfurlong.wezterm", "wezterm-gui.exe")
}
CapsLock & g::
{
    ToggleApp("Brave ahk_exe brave.exe", "brave.exe")
}
CapsLock & n::
{
    patternPath := A_ProgramsCommon . "\JetBrains\IntelliJ IDEA*.lnk"
    actualPath := ""
    Loop Files, patternPath {
        actualPath := A_LoopFileFullPath
    }
    ToggleApp("\s-\s ahk_exe idea64.exe", actualPath)
}
CapsLock & u::
{
    ToggleApp("飞书 ahk_exe Feishu.exe", A_Programs . "\飞书.lnk")
}
CapsLock & b::
{
    ToggleApp("WPS Office ahk_class OpusApp ahk_exe wps.exe", A_Programs . "\WPS Office.lnk")
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
    ToggleApp("企业微信 ahk_class WeWorkWindow ahk_exe WXWork.exe", A_StartMenuCommon . "\企业微信.lnk", ,"Max")
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