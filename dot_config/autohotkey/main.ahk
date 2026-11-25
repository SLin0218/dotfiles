#Requires AutoHotkey v2.0
#SingleInstance Force

; 保持在后台运行
Persistent(true)
DetectHiddenWindows(True)
; 强制关闭 CapsLock 的大写锁定状态，避免干扰
SetCapsLockState("AlwaysOff")

; 注册系统 Shell 钩子
DllCall("RegisterShellHookWindow", "Ptr", A_ScriptHwnd)
MsgNum := DllCall("RegisterWindowMessage", "Str", "ShellHook")
OnMessage(MsgNum, ShellMessage)
ShellMessage(wParam, lParam, *) {
    ; 1 代表 HSHELL_WINDOWCREATED (窗口被创建)
    if (wParam = 1) {
        if WinExist(lParam) {
            ; 获取新窗口的进程名称
            try {
                processName := WinGetProcessName(lParam)
                if (processName = "pinentry-basic.exe" || processName = "pinentry.exe") {
                    WinActivate(lParam)       ; 聚焦/激活窗口
                    ; WinSetAlwaysOnTop(1, lParam) ; 强行置顶
                }
            }
        }
    }
}

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
; WSLg 应用的 AUMID 唯一特征常量
; ==========================================
global WSL_ALACRITTY := "Microsoft.RemoteApp.Ku6dRE3tq348GP4jeDgI31VkoKJWfObBXFWif6nZkCA="
global WSL_BRAVE     := "Microsoft.RemoteApp.DE5h9On/NmGZ34GGwQxZzMB8wUT8DZ/CpipCPAxF5+k="
global WSL_IDEA      := "Microsoft.RemoteApp.SR67TpuXk3JAGcUT8rOJInfJvgAr5Q/UpG7Lu3fD8iI="
global WSL_EMACS     := "Microsoft.RemoteApp.pOnqGn518sswxVIvIpBzRGlDUs9VDX85oMQOWuhYLik="

; ==========================================
; 仅在指定 app 中生效的快捷键
; ==========================================
GroupAdd "TabeSwitchApp", "ahk_exe wezterm-gui.exe"
GroupAdd "TabeSwitchApp", "Brave ahk_exe brave.exe"
GroupAdd "TabeSwitchApp", "ahk_exe WindowsTerminal.exe"
GroupAdd "TabeSwitchApp", "ahk_exe emacs.exe"
GroupAdd "TabeSwitchApp", "ahk_exe alacritty.exe"

#HotIf WinActive("ahk_group TabeSwitchApp") || IsAnyWSLAppActive(WSL_ALACRITTY, WSL_BRAVE, WSL_EMACS)
    ; Ctrl + ] 切换到下一个标签页
    CapsLock & ]::Send("^{Tab}")
    ; Ctrl + [ 切换到上一个标签页
    CapsLock & [::Send("^+{Tab}")
#HotIf

; 在 Brave 浏览器中 Win+][ => Alt+][ 前进/后退
#HotIf WinActive("Brave ahk_exe brave.exe") || IsWSLAppActive(WSL_BRAVE)
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

#HotIf IsWSLAppActive(WSL_IDEA)
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

#HotIf !IsWSLAppActive(WSL_IDEA)
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


; 输入法切换
CapsLock & Space::{
    if WinActive("ahk_exe emacs.exe") || WinActive("ahk_exe msrdc.exe")
        send("^{\}")
    else
        send("^{space}")
}

; ==========================================
; Win + H/J/K/L
; ==========================================
CapsLock & k::Send("{Blind}{Up}")
CapsLock & j::Send("{Blind}{Down}")
CapsLock & h::Send("{Blind}{Left}")
CapsLock & l::Send("{Blind}{Right}")

; 当 Alt+Tab 切换窗口的界面处于激活状态时，启用以下映射
#HotIf WinActive("ahk_class XamlExplorerHostIslandWindow") or WinActive("ahk_class TaskSwitcherWnd")
; ! 代表 Alt 键，{Blind} 确保发送按键时 Alt 键一直保持按下状态
!h::Send("{Blind}{Shift Down}{Tab}{Shift Up}")   ; 向左移动
!l::Send("{Blind}{Tab}")                         ; 向右移动
!k::Send("{Blind}{Up}")                          ; 向上移动
!j::Send("{Blind}{Down}")                        ; 向下移动

#HotIf
; ==========================================

; #HotIf WinActive("ahk_class AltWindowCycleThumbHost") or WinActive("ahk_class AltWindowCycleOverlay")
; !h::Send("{Blind}{Shift Down}``{Shift Up}")   ; 向左移动
; !l::Send("{Blind}``")                         ; 向右移动
; #HotIf

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
    global activeWindows
    activeWindows := [] ; 主动切换应用时清空 Alt+` 的窗口缓存
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

; 触发 WSLg 窗口（完全通过 AUMID 匹配，不依赖任何 Title）
ToggleWSLApp(aumidPattern, exeName, workingDir?, Options?)
{
    global activeWindows
    activeWindows := [] ; 主动切换应用时清空 Alt+` 的窗口缓存
    DetectHiddenWindows(False)

    targetHwnd := 0
    for hwnd in WinGetList("ahk_class RAIL_WINDOW") {
        appId := GetWindowAUMID(hwnd)
        if (appId != "" && InStr(appId, aumidPattern)) {
            targetHwnd := hwnd
            break
        }
    }

    if (targetHwnd)
    {
        WinActivate(targetHwnd)
    }
    else
    {
        Run(exeName, workingDir?, Options?)
    }
    DetectHiddenWindows(True)
}

CapsLock & i::
{
    ; ToggleApp("ahk_exe wezterm-gui.exe ahk_class org.wezfurlong.wezterm", "wezterm-gui.exe")
    ; ToggleApp("ahk_exe alacritty.exe", "alacritty.exe")
    ToggleWSLApp(WSL_ALACRITTY, "wsl.exe --cd ~ -- alacritty", , "Hide")
}
CapsLock & g::
{
    ; ToggleApp("Brave ahk_exe brave.exe", "brave.exe")
    ToggleWSLApp(WSL_BRAVE, "wsl.exe --cd ~ -- brave", , "Hide")
}
CapsLock & n::
{
    ToggleWSLApp(WSL_IDEA, "wsl.exe --cd ~ -- intellij-idea", , "Hide")
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
   ToggleWSLApp(WSL_EMACS, "wsl.exe --cd ~ -- emacs", , "Hide")
   ;; ToggleApp("ahk_exe emacs.exe", "runemacs.exe", EnvGet("HOME"))
}
CapsLock & y::
{
   ToggleApp("ahk_exe Spotify.exe", "C:\Users\USER\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Scoop Apps\Spotify.lnk Spotify.exe")
}
; ==========================================

~F9:: {
    TrayTip "AHK 脚本正在重新加载...", "系统提示", 4
    Sleep 500
    Reload()
}

; 按 F10 查看当前活动窗口信息并将 AUMID 拷入剪贴板
F10:: {
    hwnd := WinExist("A")
    aumid := GetWindowAUMID(hwnd)
    winClass := WinGetClass(hwnd)
    winTitle := WinGetTitle(hwnd)
    winProc := WinGetProcessName(hwnd)
    A_Clipboard := aumid
    MsgBox("AUMID 已复制到剪贴板！`n`n进程: " winProc "`n类名: " winClass "`n标题: " winTitle "`nAUMID: [" aumid "]")
}



; 定义全局变量
global activeWindows := []       ; 存储过滤后的有效窗口ID
global currentIndex := 0         ; 当前窗口索引
global lastPressTime := 0        ; 上次按键时间
global timeoutThreshold := 1500  ; 1.5秒超时

!`:: {
    global activeWindows, currentIndex, lastPressTime, timeoutThreshold
    currentTime := A_TickCount
    timeElapsed := currentTime - lastPressTime
    currentHwnd := WinExist("A")

    ; 判定是否发生外部切换（如通过 CapsLock+g、鼠标点击、Alt+Tab 切换了窗口）
    isExternalSwitch := (activeWindows.Length == 0
                     || currentIndex < 1
                     || currentIndex > activeWindows.Length
                     || currentHwnd != activeWindows[currentIndex])

    ; 1. 如果超时、首次按下、或检测到外部切换，重新获取并进行【深度过滤】
    if (timeElapsed > timeoutThreshold || isExternalSwitch) {
        try {
            currentAppId := GetAppId(currentHwnd)
            activeProcess := WinGetProcessName(currentHwnd)
        } catch {
            return
        }
        if (currentAppId == "" || currentAppId == "msrdc:unknown")
            return

        ; 获取当前进程的所有候选窗口
        allWindows := WinGetList("ahk_exe " activeProcess)
        activeWindows := []
        for id in allWindows {
            ; 【关键过滤】排除虽同属 msrdc 但属于不同 Linux 应用的窗口
            if (GetAppId(id) != currentAppId)
                continue

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

; 获取窗口的唯一应用分类标识（支持区分 WSLg/msrdc 下的各类子应用）
GetAppId(winTitle := "A") {
    try {
        hwnd := WinExist(winTitle)
        if !hwnd
            return ""
        proc := WinGetProcessName(hwnd)
    } catch {
        return ""
    }

    ; 普通 Windows 原生进程，直接返回进程名
    if (proc != "msrdc.exe") {
        return proc
    }

    ; 针对 WSLg (msrdc.exe) 窗口，完全使用 Windows 分配的唯一 AUMID 区分，彻底不依赖任何窗口标题
    aumid := GetWindowAUMID(hwnd)
    return (aumid != "") ? aumid : "msrdc:unknown"
}

; 辅助函数：判断当前激活窗口是否为指定的 WSLg 应用 (通过 AUMID 匹配，不看 Title)
IsWSLAppActive(aumidPattern) {
    hwnd := WinActive("ahk_class RAIL_WINDOW")
    return hwnd ? InStr(GetWindowAUMID(hwnd), aumidPattern) : false
}

; 辅助函数：判断当前窗口是否是指定的任意一个 WSLg 应用 (传入一个或多个 AUMID)
IsAnyWSLAppActive(patterns*) {
    hwnd := WinActive("ahk_class RAIL_WINDOW")
    if !hwnd
        return false
    aumid := GetWindowAUMID(hwnd)
    if (aumid == "")
        return false
    for pat in patterns {
        if InStr(aumid, pat)
            return true
    }
    return false
}

; 读取任意窗口的 AppUserModelID (AUMID)
GetWindowAUMID(hwnd) {
    static IID_IPropertyStore := Buffer(16)
    static PKEY_AppUserModel_ID := Buffer(20)
    static init := false

    if !init {
        DllCall("ole32\CLSIDFromString", "Str", "{886d8eeb-8cf2-4446-8d02-cdba1dbdcf99}", "Ptr", IID_IPropertyStore)
        DllCall("ole32\CLSIDFromString", "Str", "{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}", "Ptr", PKEY_AppUserModel_ID)
        NumPut("UInt", 5, PKEY_AppUserModel_ID, 16)
        init := true
    }

    pPropStore := 0
    if DllCall("shell32\SHGetPropertyStoreForWindow", "Ptr", hwnd, "Ptr", IID_IPropertyStore, "Ptr*", &pPropStore) != 0
        return ""

    propVar := Buffer(24, 0)
    ; IPropertyStore::GetValue (vtable index 5)
    ComCall(5, pPropStore, "Ptr", PKEY_AppUserModel_ID, "Ptr", propVar)

    ptrStr := NumGet(propVar, 8, "Ptr")
    aumid := ptrStr ? StrGet(ptrStr, "UTF-16") : ""
    DllCall("ole32\PropVariantClear", "Ptr", propVar)
    ObjRelease(pPropStore)
    return aumid
}

; 辅助函数：检测窗口是否被 Windows 隐藏（针对 UWP 应用如应用商店、设置等）
DmGetWindowCloaked(hwnd) {
    cloaked := 0
    ; DWMWA_CLOAKED = 14
    res := DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 14, "Ptr*", &cloaked, "UInt", 4)
    return (res == 0) ? cloaked : 0
}
