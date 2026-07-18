; =================================================================
;                  D3KeyHelper  (MIT License)
; 转载请注明原作者
; 
; 
; 查看最新更新：https://github.com/Misaka10091/D3keyHelper
; 欢迎提交bug，PR
; =================================================================

;@Ahk2Exe-IgnoreBegin
AHK_MIN_VERSION:="1.1.33.00"
if (A_AhkVersion < AHK_MIN_VERSION)
    MsgBox, 0x40, 若遇到错误请升级AHK软件！, % Format("本按键助手基于AHK v{:s}开发。`n你的AHK版本为：v{:s}。", AHK_MIN_VERSION, A_AhkVersion)
;@Ahk2Exe-IgnoreEnd

#SingleInstance Force
#NoEnv
#InstallKeybdHook
#InstallMouseHook
APP_DIRECTORY:=A_IsCompiled ? A_ScriptDir : RegExReplace(A_ScriptDir, "\\src$")
SetWorkingDir %APP_DIRECTORY%
SetBatchLines -1
Thread, interrupt, 0
CoordMode, Pixel, Client
CoordMode, Mouse, Client
Process, Priority, , High

CONFIG_SCHEMA_VERSION:=260403 ; 仅在配置结构变化时递增，与应用发布版本无关
DISPLAY_VERSION:="development"
PROFILE_DIRECTORY:="profiles"
SETTINGS_FILE:="settings.ini"
PROJECT_HOMEPAGE:="https://github.com/Misaka10091/D3keyHelper"
PROJECT_MAINTAINER:="Misaka10091"
ORIGINAL_AUTHOR:="Oldsand"
if (A_IsCompiled and DISPLAY_VERSION="development")
{
    FileGetVersion, executableVersion, %A_ScriptFullPath%
    if RegExMatch(executableVersion, "^\d+\.\d+\.\d+\.\d+$")
        DISPLAY_VERSION:=executableVersion
}
DISPLAY_VERSION_LABEL:=(DISPLAY_VERSION="development") ? DISPLAY_VERSION : "v" DISPLAY_VERSION
MainWindowW:=900
MainWindowH:=570
CompactWindowW:=551
TitleBarHight:=25
;@Ahk2Exe-Obey U_Y, U_Y := A_YYYY
;@Ahk2Exe-Obey U_M, U_M := A_MM
;@Ahk2Exe-Obey U_D, U_D := A_DD
;@Ahk2Exe-SetFileVersion 1.4.%U_Y%.%U_M%%U_D%
;@Ahk2Exe-SetProductVersion 1.4.%U_Y%.%U_M%%U_D%
;@Ahk2Exe-SetLanguage 0x0804
;@Ahk2Exe-SetDescription 暗黑3技能连点器
;@Ahk2Exe-SetProductName D3keyHelper
;@Ahk2Exe-SetCopyright Misaka10091
;@Ahk2Exe-Bin Unicode 64-bit.bin
; ========================================来自配置文件的全局变量===================================================
currentProfile:=ReadCfgFile(SETTINGS_FILE, tabs, profileFiles, combats, others, generals)
SendMode, % generals.sendmode
tabsarray:=StrSplit(tabs, "`|")
tabslen:=ObjCount(tabsarray)
safezone:={}
isCompact:= generals.compactmode
runOnStart:= generals.runonstart
d3only:= generals.d3only
maxreforge:= (generals.maxreforge)?generals.maxreforge:10
TitleString:=(d3only)? "暗黑3技能连点器":"鼠标键盘连点器"
TITLE:=TitleString " " DISPLAY_VERSION_LABEL "   by " PROJECT_MAINTAINER
helperMouseSpeed:= generals.helpermousespeed
helperAnimationDelay:= generals.helperanimationdelay
gameResolution:= InStr(generals.gameresolution, "x")? generals.gameresolution:"Auto"
hBMPButtonLeft_Normal := isCompact? hBMPButtonExpand_Normal:hBMPButtonBack_Normal
hBMPButtonLeft_Hover := isCompact? hBMPButtonExpand_Hover:hBMPButtonBack_Hover
hBMPButtonLeft_Pressed := isCompact? hBMPButtonExpand_Pressed:hBMPButtonBack_Pressed
Loop, Parse, % generals.safezone, CSV
{
    safezone[A_LoopField]:=1
}
#If WinActive((d3only)?"ahk_class D3 Main Window Class":"A")
gameGamma:=(generals.gamegamma>=0.5 and generals.gamegamma<=1.5)? generals.gamegamma:1
buffpercent:=(generals.buffpercent>=0 and generals.buffpercent<=1)? generals.buffpercent:0.05
; ==============================================================================================================
GuiCreate()
SetTrayMenu()
StartUp()
if !FileExist(SETTINGS_FILE)
    SaveCfgFile(SETTINGS_FILE, profileFiles, currentProfile, safezone, CONFIG_SCHEMA_VERSION)
showMainWindow(isCompact? CompactWindowW:MainWindowW, MainWindowH)

OnExit("OnUnload")
Return

; =================================== User Functions =====================================
/*
在程序载入时执行的一些初始化
参数：
    无
返回：
    无
*/
OnLoad(){
    Global
    Static Init := OnLoad() ; 在所有语句之前运行

    ; ============================================全局变量===========================================================
    vRunning:=False
    vPausing:=False
    vFront:=True
    helperDelay:=100
    mouseDelay:=2
    helperRunning:=False
    helperBreak:=False
    profileKeybinding:={}
    keysOnHold:={}
    lastpotion:=[]
    DblClickTime:=DllCall("GetDoubleClickTime", "UInt")
    RightButtonState:=0
    LeftButtonState:=0
    _CloseButtonNormal := "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAZCAYAAAAmNZ4aAAAAM0lEQVRIiWMYBaNgFIyCUUAsYCSkrnLe2v/khGZ7UjBes5lGo2gUjIJRMApGAVbAwMAAAMjYBAQ0LnL/AAAAAElFTkSuQmCC"
    _CloseButtonHover := "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAZCAYAAAAmNZ4aAAAARklEQVRIiWN8Iaj8n2EAANNAWMowavGoxaMWj1pMCWAhpFfi/V2yjH8hqIxXfvD6mJDLyQWjqXrU4lGLRy0etZg4wMDAAACGJAZtrV+pPwAAAABJRU5ErkJggg=="
    _CloseButtonPressed := "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAZCAYAAAAmNZ4aAAAARklEQVRIiWO85B32n2EAANNAWMowavGoxaMWj1pMCWAhpNftwjGyjN9lYIVXfvD6mJDLyQWjqXrU4lGLRy0etZg4wMDAAACzuwbMPgoPPgAAAABJRU5ErkJggg=="
    _BackButtonNormal := "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAZCAYAAAAmNZ4aAAAAr0lEQVRIie2UwQ3CMAwA7Sa0ZhJGYAOWoCswDSuUJdiAFViEtIkw8gMJEKiOan4+KY9Iji+2nIDjOFagJs/xfHnb853345gGItoA4vUz/rDbzuZsagsQaUq3IYQA36RaqsRPaYwRVm2r6tYv1GJLKWjF1lIhaoJkkJgZcs6yWHFk9nIqcddRb12xqtXY4Ilo3ZdSIE+TpmIb8T/kVc/JUl79gbzKZdqXyB3HWQ4APACzI1jSHwESAQAAAABJRU5ErkJggg=="
    _BackButtonHover := "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAZCAYAAAAmNZ4aAAAAn0lEQVRIiWOUbL31n2EAANNAWMowavGoxYPO4j/XdzK8qFFn+Pf+Ef0sBln6ekkuAzMLCwOToBx9LIZZysLKyiDacJVsS0mymJqWEm0xtS0FAaLKalBC+v+f+CJdsvUWQTUsxBgkEj2J6j4mKqhZNN0ZRGMmM/z5/ZvhdYM2/SymheUkZSdqWk5yAYJsOSi1kwtGWyCjFo9aTB3AwMAAAPFsSKyupuluAAAAAElFTkSuQmCC"
    _BackButtonPressed := "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAZCAYAAAAmNZ4aAAAAn0lEQVRIiWM0nnz/P8MAAKaBsJRh1OJRiwedxZ8v7WA4l6fE8OvtI/pZDLL01uxMBmYWFgY2YTn6WAyzlIWVlUG/7xbZlpJkMTUtJdpialsKAkSV1aCE9P8/8UW68eT7BNWwEGOQaso0qvuYqKDm1fNgUEudzvDn92+Gi0Vq9LOYFpaTlJ2oaTnJBQiy5aDUTi4YbYGMWjxqMXUAAwMDALPRSRXM0WlaAAAAAElFTkSuQmCC"
    _ExpandButtonNormal := "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAZCAYAAAAmNZ4aAAAAVUlEQVRIiWMYBaOAVoCRkLmV89b+J8fu9qRgvGYzDVSUEvTx//9keZiBkRG/0QPm45FnMQshBVXz15EXyQTSz2iqphsYTdUYYNil6lEwCoYZYGBgAACe2A+sakz0agAAAABJRU5ErkJggg=="
    _ExpandButtonHover := "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAZCAYAAAAmNZ4aAAAASklEQVRIiWOUbL31n2EAANNAWMowajE9AQshu55Xq5HlHMnWW0PUx4RcTi4YzU50A6OpGgOMpuohb/FoqsYAo6l61OKhZTEDAwMAZw0QHWhren8AAAAASUVORK5CYII="
    _ExpandButtonPressed := "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAZCAYAAAAmNZ4aAAAASklEQVRIiWM0nnz/P8MAAKaBsJRh1GJ6AhZCdp3NVSTLOcaT7w9RHxNyOblgNDvRDYymagwwmqqHvMWjqRoDjKbqUYuHlsUMDAwASU0Q0fLg6gAAAAAASUVORK5CYII="
    DllCall("LoadLibrary", "Str", "Crypt32.dll")
    DllCall("LoadLibrary", "Str", "Shlwapi.dll")
    DllCall("LoadLibrary", "Str", "Gdiplus.dll")
    VarSetCapacity(GdiplusStartupInput, (A_PtrSize = 8 ? 24 : 16), 0) ; GdiplusStartupInput structure
    NumPut(1, GdiplusStartupInput, 0, "UInt") ; GdiplusVersion
    DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", pToken, "Ptr", &GdiplusStartupInput, "Ptr", 0) ; Initialize GDI+

    hBMPButtonClose_Normal := GdipCreateFromBase64(_CloseButtonNormal)
    hBMPButtonClose_Hover := GdipCreateFromBase64(_CloseButtonHover)
    hBMPButtonClose_Pressed := GdipCreateFromBase64(_CloseButtonPressed)
    hBMPButtonBack_Normal := GdipCreateFromBase64(_BackButtonNormal)
    hBMPButtonBack_Hover := GdipCreateFromBase64(_BackButtonHover)
    hBMPButtonBack_Pressed := GdipCreateFromBase64(_BackButtonPressed)
    hBMPButtonExpand_Normal := GdipCreateFromBase64(_ExpandButtonNormal)
    hBMPButtonExpand_Hover := GdipCreateFromBase64(_ExpandButtonHover)
    hBMPButtonExpand_Pressed := GdipCreateFromBase64(_ExpandButtonPressed)
}

/*
在程序退出时执行的清理工作
参数：
    无
返回：
    无
*/
OnUnload(ExitReason, ExitCode){
    Global ; Assume-Global mode
    ; Clean up resources used by GDI+
    DllCall("GdiplusShutdown", "Ptr", pToken)
    DllCall("DeregisterShellHookWindow", "Ptr", A_ScriptHwnd)
    if (hHookMouse){
        DllCall("UnhookWindowsHookEx", "Uint", hHookMouse)
    }
}

/*
创建图形界面
参数：
    无
返回：
    无
*/
GuiCreate(){
    Global
    local tabw:=MainWindowW-357
    local tabh:=MainWindowH-35-TitleBarHight
    local helperSettingGroupx:=MainWindowW-345

    Gui Font, s11, Segoe UI
    Gui -MaximizeBox -MinimizeBox +Owner +DPIScale +LastFound -Caption -Border
    Gui, Margin, 5, % TitleBarHight+10
    ; SS_BITMAP:=0x40
    ; SS_REALSIZECONTROL:=0x0E
    ; 0x4E=SS_BITMAP|SS_REALSIZECONTROL
    Gui, Add, Picture, % "x1 y1 w" MainWindowW-2 " h" TitleBarHight " +0x4E hwndTitlebarID vTitlebar"
    Gui, Add, Picture, % "x1 y+0 w" MainWindowW-2 " h1 +0x4E hwndTitlebarLineID"
    Gui, Add, Picture, % "x0 y0 w" MainWindowW " h1 +0x4E hwndBorderTopID vBorderTop"
    Gui, Add, Picture, % "x0 y" MainWindowH-1 " w" MainWindowW " h1 +0x4E hwndBorderBottomID vBorderBottom"
    Gui, Add, Picture, % "x0 y1 w1 h" MainWindowH-2 " +0x4E hwndBorderLeftID vBorderLeft"
    Gui, Add, Picture, % "x" MainWindowW-1 " y1 w1 h" MainWindowH-2 " +0x4E hwndBorderRightID vBorderRight"
    Gui, Add, Text, % "x1 y1 h" TitleBarHight " hwndTitleBarTextID vTitleBarText +BackgroundTrans +0x200", %TITLE%
    Gui, Add, Picture, % "x" MainWindowW-31 " y1 w-1 h" TitleBarHight " hwndUIRightButtonID vUIRightButton gdummyFunction +BackgroundTrans", % "HBITMAP:*" hBMPButtonClose_Normal
    AddToolTip(UIRightButtonID, "左键：保存设置并最小化窗口至右下角`n右键：保存设置并退出程序")
    Gui, Add, Picture, % "x" 1 " y1 w-1 h" TitleBarHight " hwndUILeftButtonID vUILeftButton gdummyFunction +BackgroundTrans", % "HBITMAP:*" hBMPButtonLeft_Normal
    AddToolTip(UILeftButtonID, "点击以在完整，紧凑布局中切换")
    GuiControlGet, TitleBarSize, Pos , TitleBarText
    Gui Add, Tab3, xm ym w%tabw% h%tabh% vActiveTab gSetTabFocus AltSubmit, %tabs%
    Gui Font, s9, Segoe UI
    local skillLabels:=["技能一：", "技能二：", "技能三：", "技能四：", "左键技能：", "右键技能："]
    Loop, parse, tabs, `|
    {
        local currentTab:=A_Index
        Gui Tab, %currentTab%
        Gui Add, Hotkey, x0 y0 w0 w0
        
        Gui Add, GroupBox, xm+10 ym+40 w520 h260 section, 按键宏设置
        Gui Add, Text, xs+90 ys+20 w60 center section, 快捷键
        Gui Add, Text, x+10 w80 center, 策略
        Gui Add, Text, x+15 w110 center, 执行间隔（毫秒）
        Gui Add, Text, x+5 w90 center, 延迟（毫秒）
        Gui Add, Text, x+0 center, 延迟随机
        Loop, 6
        {
            Gui Add, Text, xs-75 w70 yp+34 center, % skillLabels[A_Index]
            local ac:=combats[currentTab][A_Index]["action"]
            local rd:=combats[currentTab][A_Index]["random"]
            switch A_Index
            {
                case 1,2,3,4:
                    Gui Add, Hotkey, x+5 yp-2 w60 vskillset%currentTab%s%A_Index%hotkey, % combats[currentTab][A_Index]["hotkey"]
                case 5:
                    Gui Add, Edit, x+5 yp-2 w60 vskillset%currentTab%s%A_Index%hotkey +Disabled, LButton
                case 6:
                    Gui Add, Edit, x+5 yp-2 w60 vskillset%currentTab%s%A_Index%hotkey +Disabled, RButton
            }
            Gui Add, DropDownList, x+10 w80 AltSubmit Choose%ac% gSetSkillsetDropdown vskillset%currentTab%s%A_Index%dropdown, 禁用||按住不放||连点||保持Buff||按键触发
            Gui Add, Edit, vskillset%currentTab%s%A_Index%edit x+20 w90 Number
            Gui Add, Updown, vskillset%currentTab%s%A_Index%updown gSetSkillQueueWarning Range20-60000, % combats[currentTab][A_Index]["interval"]
            Gui Add, Edit, vskillset%currentTab%s%A_Index%delayedit hwndskillset%currentTab%s%A_Index%delayeditID x+25 w70
            Gui Add, Updown, vskillset%currentTab%s%A_Index%delayupdown Range-30000-30000, % combats[currentTab][A_Index]["delay"]
            AddToolTip(skillset%currentTab%s%A_Index%delayeditID, "正数代表策略延后执行，负数代表策略提前执行，设为0可以关闭延迟")
            Gui Add, Checkbox, x+35 yp+2 Checked%rd% vskillset%currentTab%s%A_Index%randomckbox hwndskillset%currentTab%s%A_Index%randomckboxID
            AddToolTip(skillset%currentTab%s%A_Index%randomckboxID, "勾选后，每次策略执行时的实际延迟为0至设置值之间的随机数")
        }
        Gui Add, GroupBox, xm+10 yp+45 w520 h192 section, 额外设置
        Gui Add, Text, xs+20 ys+27, 快速切换至本配置：
        Gui Add, DropDownList, % "x+5 yp-3 w90 AltSubmit Choose" others[currentTab].profilemethod " vskillset" currentTab "profilekeybindingdropdown gSetProfileKeybinding", 无||鼠标中键||滚轮向上||滚轮向下||侧键1||侧键2||键盘按键
        Gui Add, Hotkey, x+15 w100 vskillset%currentTab%profilekeybindinghkbox gSetProfileKeybinding, % others[currentTab].profilehotkey
        Gui Add, Checkbox, % "x+15 yp+3 Checked" others[currentTab].autostartmarco " vskillset" currentTab "autostartmarcockbox hwndskillset" currentTab "autostartmarcockboxID", 切换后自动启动宏
        AddToolTip(skillset%currentTab%autostartmarcockboxID, "开启后，以懒人模式启动的战斗宏可以在运行中无缝切换")

        Gui Add, Text, xs+20 yp+35, 宏启动方式：
        Gui Add, DropDownList, % "x+5 yp-3 w90 AltSubmit Choose" others[currentTab].lazymode " hwndprofileStartModeDropdown" currentTab "ID vskillset" currentTab "profilestartmodedropdown gSetStartMode", 懒人模式||仅按下时||仅按一次
        AddToolTip(profileStartModeDropdown%currentTab%ID, "懒人模式：按下战斗宏快捷键时开启宏，再按一下关闭宏`n仅按下时：仅在战斗宏快捷键被压下时启动宏`n仅按一次：按下战斗宏快捷键即按下所有“按住不放”的技能键一次")
        Gui Add, Checkbox, % "x+20 yp+3 Checked" others[currentTab].useskillqueue " hwnduseskillqueueckbox" currentTab "ID vskillset" currentTab "useskillqueueckbox gSetSkillQueue", 使用单线程按键队列（毫秒）：
        AddToolTip(useskillqueueckbox%currentTab%ID, "开启后按键不会被立刻按下而是存储至一个按键队列中`n连点会使技能加入队列头部，保持buff会使技能加入队列尾部`n并且连点时会自动按下强制站立")
        Gui Add, Edit, vskillset%currentTab%useskillqueueedit hwnduseskillqueueedit%currentTab%ID x+0 yp-3 w50 Number
        Gui Add, Updown, vskillset%currentTab%useskillqueueupdown gSetSkillQueueWarning Range50-1000, % others[currentTab].useskillqueueinterval
        AddToolTip(useskillqueueedit%currentTab%ID, "按键队列中的连点按键会以此间隔一一发送至游戏窗口")
        Gui Add, Text, x+8  yp+3 vskillset%currentTab%skillqueuewarningtext hwndskillset%currentTab%skillqueuewarningtextID gdummyFunction +cRed +Hidden, % "注意！"
        AddToolTip(skillset%currentTab%skillqueuewarningtextID, "按键队列功能设置有误")

        Gui Add, Checkbox, % "xs+20 yp+35 Checked" others[currentTab].enablequickpause " vskillset" currentTab "clickpauseckbox gSetQuickPause", 快速暂停：
        Gui Add, DropDownList, % "x+0 yp-3 w50 AltSubmit Choose" others[currentTab].quickpausemethod1 " vskillset" currentTab "clickpausedropdown1 gSetQuickPause", 双击||单击||压住
        Gui Add, DropDownList, % "x+5 yp w75 AltSubmit Choose" others[currentTab].quickpausemethod2 " vskillset" currentTab "clickpausedropdown2 gSetQuickPause", 鼠标左键||鼠标右键||鼠标中键||侧键1||侧键2
        Gui Add, Text, x+5 yp+3 vskillset%currentTab%clickpausetext1, 则
        Gui Add, DropDownList, % "x+5 yp-3 w140 AltSubmit Choose" others[currentTab].quickpausemethod3 " vskillset" currentTab "clickpausedropdown3", 暂停按键宏||暂停宏且连点左键
        Gui Add, Edit, vskillset%currentTab%clickpauseedit x+5 yp w60 Number
        Gui Add, Updown, vskillset%currentTab%clickpauseupdown Range500-5000, % others[currentTab].quickpausedelay
        Gui Add, Text, x+5 yp+3 vskillset%currentTab%clickpausetext2, 毫秒

        Gui Add, Text, xs+20 yp+35, 走位辅助：
        Gui Add, DropDownList, % "x+5 yp-3 w150 AltSubmit Choose" pfmv:=others[currentTab].movingmethod " vskillset" currentTab "movingdropdown gSetMovingHelper", 无||强制站立||强制走位（按住不放）||强制走位（连点）
        Gui Add, Text, vskillset%currentTab%movingtext x+10 yp+3, 执行间隔（毫秒）：
        Gui Add, Edit, vskillset%currentTab%movingedit x+5 yp-3 w60 Number
        Gui Add, Updown, vskillset%currentTab%movingupdown Range20-3000, % others[currentTab].movinginterval

        Gui Add, Text, xs+20 yp+35, 药水辅助：
        Gui Add, DropDownList, % "x+5 yp-3 w120 AltSubmit Choose" pfpo:=others[currentTab].potionmethod "hwndpotionDropdown" currentTab "ID vskillset" currentTab "potiondropdown gSetMovingHelper", 无||定时连点||保持药水CD
        AddToolTip(potionDropdown%currentTab%ID, "定时连点：以固定时间间隔连续点击药水按键`n保持药水CD：仅在药水CD结束时连点，从而使药水尽快重新进入CD")
        Gui Add, Text, vskillset%currentTab%potiontext x+10 yp+3, 执行间隔（毫秒）：
        Gui Add, Edit, vskillset%currentTab%potionedit x+5 yp-3 w60 Number
        Gui Add, Updown, vskillset%currentTab%potionupdown Range200-30000, % others[currentTab].potioninterval
    }
    Gui Tab
    GuiControl, Choose, ActiveTab, % currentProfile

    Gui Add, GroupBox, x%helperSettingGroupx% ym+40 w338 h470 section, 辅助功能
    utilityHelperHK:=generals.helperhotkey
    Gui Font,s10
    Gui Add, Text, xs+20 ys+30 +cRed, 助手宏启动快捷键：
    Gui Font,s9
    Gui Add, DropDownList, % "x+0 yp-3 w75 vhelperKeybindingdropdown gSetHelperKeybinding AltSubmit Choose" generals.helpermethod, 无||鼠标中键||滚轮向上||滚轮向下||侧键1||侧键2||键盘按键
    Gui Add, Hotkey, x+5 w70 vhelperKeybindingHK gSetHelperKeybinding, %utilityHelperHK%

    Gui Add, Text, xs+20 yp+40 hwndhelperSpeedTextID gdummyFunction, 助手宏动画速度：
    AddToolTip(helperSpeedTextID, "当网络延迟较高时，适当降低动画速度可以减少宏出错的概率")
    Gui Add, DropDownList, % "x+5 yp-3 w90 vhelperAnimationSpeedDropdown hwndhelperAnimationSpeedDropdownID AltSubmit Choose" generals.helperspeed, 非常快||快速||中等||慢速||自定义
    AddToolTip(helperAnimationSpeedDropdownID, "非常快：鼠标速度0，动画延迟50`n快速：鼠标速度1，动画延迟100`n中等：鼠标速度2，动画延迟150`n慢速：鼠标速度3，动画延迟200`n自定义：使用“应用设置”中的高级参数")

    Gui Add, Text, x+20 yp+4 w80 hwndhelperSafeZoneTextID vhelperSafeZoneText gdummyFunction
    AddToolTip(helperSafeZoneTextID, "可在“应用设置”中设置安全格`n左上角编号为1，右上角为10，左下角为51，右下角为60")

    Gui Add, CheckBox, % "xs+20 yp+35 hwndextraGambleHelperCKboxID vextraGambleHelperCKbox gSetGambleHelper Checked" generals.enablegamblehelper, 血岩赌博助手：
    AddToolTip(extraGambleHelperCKboxID, "赌博时按下助手快捷键可以自动点击右键")
    Gui Add, Text, vextraGambleHelperText x+5 yp, 发送右键次数
    Gui Add, Edit, vextraGambleHelperEdit x+10 yp-4 w60 Number
    Gui Add, Updown, vextraGambleHelperUpdown Range2-60, % generals.gamblehelpertimes

    Gui Add, CheckBox, % "xs+20 yp+40 hwndextraLootHelperCkboxID vextraLootHelperCkbox gSetLootHelper Checked" generals.enableloothelper, 快速拾取助手：
    AddToolTip(extraLootHelperCkboxID, "拾取装备时按下助手快捷键可以自动点击左键")
    Gui Add, Text, vextraLootHelperText x+5 yp, 发送左键次数
    Gui Add, Edit, vextraLootHelperEdit x+10 yp-4 w60 Number
    Gui Add, Updown, vextraLootHelperUpdown Range2-99, % generals.loothelpertimes

    Gui Add, CheckBox, % "xs+20 yp+40 hwndextraSalvageHelperCkboxID vextraSalvageHelperCkbox gSetSalvageHelper Checked" generals.enablesalvagehelper, 铁匠分解助手：
    Gui Add, DropDownList, % "x+5 yp-4 w180 AltSubmit hwndextraSalvageHelperDropdownID vextraSalvageHelperDropdown gSetSalvageHelper Choose" generals.salvagehelpermethod, 快速分解||一键分解||智能分解||智能分解（留神圣，无形，太古）||智能分解（只留太古）
    AddToolTip(extraSalvageHelperCkboxID, "分解装备时按下助手快捷键可以自动执行所选择的策略")
    AddToolTip(extraSalvageHelperDropdownID, "快速分解：按下快捷键即等同于点击鼠标左键+回车`n一键分解：一键分解背包内所有非安全格的装备`n智能分解：同一键分解，但会跳过远古，神圣，太古`n智能分解（留神圣，无形，太古）：只保留神圣，无形，太古装备`n智能分解（只留太古）：只保留太古装备")

    Gui Add, CheckBox, % "xs+20 yp+40 hwndextraReforgeHelperCkboxID vextraReforgeHelperCkbox gSetReforgeHelper Checked" generals.enablereforgehelper, 魔盒重铸助手：
    Gui Add, DropDownList, % "x+5 yp-4 w180 AltSubmit hwndextraReforgeHelperDropdownID vextraReforgeHelperDropdown Choose" generals.reforgehelpermethod, 重铸一次||重铸直到远古，太古||重铸直到太古
    AddToolTip(extraReforgeHelperCkboxID, "当魔盒打开且在重铸页面时，按下助手快捷键可以自动执行所选择的重铸策略`n最大重铸次数可在“应用设置”中修改")
    local strMaxReforge1:= "不停重铸鼠标指针处的装备，直到变为远古或者太古装备，最多重铸" maxreforge "次"
    local strMaxReforge2:= "不停重铸鼠标指针处的装备，直到变成太古装备，最多重铸" maxreforge "次"
    AddToolTip(extraReforgeHelperDropdownID, "重铸一次：重铸鼠标指针处的装备一次`n重铸直到远古，太古：" strMaxReforge1 "`n重铸直到太古：" strMaxReforge2 "`n***重铸过程中再次按下助手快捷键可以打断宏！***")

    Gui Add, CheckBox, % "xs+20 yp+40 hwndextraUpgradeHelperCkboxID vextraUpgradeHelperCkbox gSetSalvageHelper Checked" generals.enableupgradehelper, 魔盒升级助手
    AddToolTip(extraUpgradeHelperCkboxID, "当魔盒打开且在升级页面时，按下助手快捷键即自动升级所有非安全格内的稀有（黄色）装备")

    Gui Add, CheckBox, % "x+20 yp+0 hwndextraConvertHelperCkboxID vextraConvertHelperCkbox gSetSalvageHelper Checked" generals.enableconverthelper, 魔盒转化助手
    AddToolTip(extraConvertHelperCkboxID, "当魔盒打开且在转化材料页面时，按下助手快捷键即自动使用所有非安全格内的装备进行材料转化")

    Gui Add, CheckBox, % "xs+20 yp+36 hwndextraAbandonHelperCkboxID vextraAbandonHelperCkbox gSetSalvageHelper Checked" generals.enableabandonhelper, 一键丢装助手
    AddToolTip(extraAbandonHelperCkboxID, "当背包栏打开且鼠标指针位于背包栏内时，按下助手快捷键即自动丢弃所有非安全格的物品`n若储物箱（银行）打开且鼠标位于银行格子内时，宏会存储所有非安全格内的物品至储物箱")

    Gui Add, CheckBox, % "xs+20 yp+55 vextraSoundonProfileSwitch Checked" generals.enablesoundplay, 快捷键切换配置成功时播放声音
    Gui Add, CheckBox, % "x+20 yp+0 hwndextraSmartPauseID vextraSmartPause Checked" generals.enablesmartpause, 智能暂停
    AddToolTip(extraSmartPauseID, "开启后，游戏中按tab键可以暂停宏`n回车键，M键，T键会停止宏")

    Gui Add, CheckBox, % "xs+20 yp+35 vextraCustomStanding gSetCustomStanding Checked" generals.customstanding, 使用自定义强制站立按键：
    Gui Add, Hotkey, x+5 yp-3 w70 vextraCustomStandingHK gSetCustomStanding, % generals.customstandinghk

    Gui Add, CheckBox, % "xs+20 yp+35 vextraCustomMoving gSetCustomMoving Checked" generals.custommoving, 使用自定义强制移动按键：
    Gui Add, Hotkey, x+5 yp-3 w70 Limit14 vextraCustomMovingHK gSetCustomMoving, % generals.custommovinghk

    Gui Add, CheckBox, % "xs+20 yp+35 vextraCustompotion gSetCustomPotion Checked" generals.custompotion, 使用自定义药水按键：
    Gui Add, Hotkey, x+5 yp-3 w70 Limit14 vextraCustompotionHK gSetCustomPotion, % generals.custompotionhk

    startRunHK:=generals.starthotkey
    Gui Font, s10
    Gui Add, Text, x570 ym+3 +cRed, 战斗宏启动快捷键：
    Gui Font, s9
    Gui Add, DropDownList, % "x+5 yp-3 w90 vStartRunDropdown gSetStartRun AltSubmit Choose" generals.startmethod, 鼠标右键||鼠标中键||滚轮向上||滚轮向下||侧键1||侧键2||键盘按键
    Gui Add, Hotkey, x+5 yp w70 vStartRunHKinput gSetStartRun, %startRunHK%

    Gui Add, Text, % "x10 y" MainWindowH-20 " section", 当前激活配置：
    Gui Font, s11
    Gui Add, Text, x+5 ys-4 w300 +cRed vStatuesSkillsetText, % tabsarray[currentProfile]
    Gui Add, Text, x505 yp +cRed hwndCurrentmodeTextID gdummyFunction, % A_SendMode
    Gui Font, s9
    Gui Add, Text, xp-95 ys hwndSendmodeTextID gdummyFunction, 按键发送模式：
    AddToolTip(SendmodeTextID, "点击“应用设置”可切换按键发送模式")
    AddToolTip(CurrentmodeTextID, "Event：默认模式，最佳兼容性`nInput：推荐模式，最佳速度但可能会被一些杀毒防护软件屏蔽干扰")
    Gui Add, Button, x570 ys-8 w55 h25 gShowAbout, 关于
    Gui Add, Link, x635 ys hwndAboutLinkID, <a href="https://github.com/Misaka10091/D3keyHelper">项目主页</a>
    AddToolTip(AboutLinkID, PROJECT_HOMEPAGE)
    Gui Add, Button, x710 ys-8 w75 h25 vSaveButton gSaveNow, 保存
    AddToolTip(SaveButton, "立即保存全局设置和所有 profile")
    Gui Add, Button, x795 ys-8 w90 h25 gShowAppSettings, 应用设置
    Return
}

ShowAboutWindow(){
    Global
    Gui, 4:Destroy
    Gui, 4:New, +Owner1 +OwnDialogs -MaximizeBox -MinimizeBox, 关于 D3KeyHelper
    Gui, 4:Margin, 20, 16
    Gui, 4:Font, s14 Bold, Segoe UI
    Gui, 4:Add, Text, x20 y18 w400 Center, D3KeyHelper
    Gui, 4:Font, s9 Normal, Segoe UI
    Gui, 4:Add, Text, x20 y55 w400 Center, % "版本 " DISPLAY_VERSION_LABEL
    Gui, 4:Add, Text, x20 y86 w400 Center, % "维护者：" PROJECT_MAINTAINER "    原作者：" ORIGINAL_AUTHOR
    Gui, 4:Add, Text, x20 y116 w400 Center c666666, 基于 MIT License 开源
    Gui, 4:Add, Text, x20 y150 w400 Center, 项目主页
    Gui, 4:Add, Link, x20 y174 w400 Center, <a href="https://github.com/Misaka10091/D3keyHelper">https://github.com/Misaka10091/D3keyHelper</a>
    Gui, 4:Add, Text, x20 y211 w400 Center c666666, % "配置目录：" APP_DIRECTORY
    Gui, 4:Add, Button, x180 y246 w80 h28 Default gCloseAbout, 确定
    Gui, 4:Show, w440 h294
    Return
}

ShowAppSettingsWindow(){
    Global
    Gui, 2:Destroy
    Gui, 2:New, +Owner1 +OwnDialogs -MaximizeBox -MinimizeBox, 应用设置
    Gui, 2:Margin, 16, 14
    Gui, 2:Font, s9, Segoe UI

    Gui, 2:Add, GroupBox, x16 y14 w458 h120 section, 运行与按键
    Gui, 2:Add, CheckBox, xs+18 ys+25 vsettingsD3Only Checked%d3only%, 仅在暗黑破坏神 III 窗口中启用按键宏
    Gui, 2:Add, CheckBox, xs+18 yp+28 vsettingsRunOnStart Checked%runOnStart%, 启动战斗宏时立即执行一次策略
    Gui, 2:Add, Text, xs+18 yp+32, 按键发送模式：
    Gui, 2:Add, DropDownList, x+8 yp-3 w120 vsettingsSendMode, Event|Input|Play|InputThenPlay
    GuiControl, 2:ChooseString, settingsSendMode, %A_SendMode%
    Gui, 2:Add, Text, x+25 yp+3, 游戏分辨率：
    Gui, 2:Add, ComboBox, x+8 yp-3 w105 vsettingsResolution, Auto|1280x720|1366x768|1600x900|1920x1080|2560x1440|3840x2160
    GuiControl, 2:Text, settingsResolution, %gameResolution%

    Gui, 2:Add, GroupBox, x16 y144 w458 h126 section, 检测参数
    Gui, 2:Add, Text, xs+18 ys+28, 背包安全格：
    Gui, 2:Add, Edit, x+8 yp-3 w280 vsettingsSafeZone, % keyJoin(",", safezone)
    Gui, 2:Add, Text, xs+18 yp+29 c666666, 使用英文逗号分隔编号；留空表示不保护任何格子。
    Gui, 2:Add, Text, xs+18 yp+31, 游戏 Gamma：
    Gui, 2:Add, ComboBox, x+8 yp-3 w75 vsettingsGameGamma, 0.80|0.90|1.00|1.10|1.20|1.30|1.40|1.50
    GuiControl, 2:Text, settingsGameGamma, %gameGamma%
    Gui, 2:Add, Text, x+28 yp+3, Buff 提前刷新：
    Gui, 2:Add, ComboBox, x+8 yp-3 w65 vsettingsBuffPercent, 0|2.5|5|7.5|10|15|20
    GuiControl, 2:Text, settingsBuffPercent, % Round(buffpercent*100, 2)
    Gui, 2:Add, Text, x+4 yp+3, % "%"

    Gui, 2:Add, GroupBox, x16 y280 w458 h126 section, 助手高级参数
    Gui, 2:Add, Text, xs+18 ys+28, 最大重铸次数：
    Gui, 2:Add, ComboBox, x+8 yp-3 w70 vsettingsMaxReforge, 10|25|50|100|250|500
    GuiControl, 2:Text, settingsMaxReforge, %maxreforge%
    Gui, 2:Add, Text, x+28 yp+3, 自定义鼠标速度：
    Gui, 2:Add, ComboBox, x+8 yp-3 w70 vsettingsMouseSpeed, 0|1|2|3|5|10
    GuiControl, 2:Text, settingsMouseSpeed, %helperMouseSpeed%
    Gui, 2:Add, Text, xs+18 yp+31, 自定义动画延迟：
    Gui, 2:Add, ComboBox, x+8 yp-3 w70 vsettingsAnimationDelay, 50|100|150|200|300|500|1000
    GuiControl, 2:Text, settingsAnimationDelay, %helperAnimationDelay%
    Gui, 2:Add, Text, x+8 yp+3, 毫秒
    Gui, 2:Add, Text, xs+18 yp+31 c666666, 选择“自定义”助手速度时使用以上两个参数。

    Gui, 2:Add, GroupBox, x16 y416 w458 h110 section, Profile 管理
    Gui, 2:Add, Text, xs+18 ys+27, 当前：
    Gui, 2:Add, DropDownList, x+8 yp-4 w150 AltSubmit vsettingsProfileSelection Choose%currentProfile%, %tabs%
    Gui, 2:Add, Button, x+8 yp-2 w58 h25 gAddProfile, 新增
    Gui, 2:Add, Button, x+5 yp w58 h25 gRenameProfile, 重命名
    Gui, 2:Add, Button, x+5 yp w58 h25 gDeleteProfile, 删除
    Gui, 2:Add, Text, xs+18 yp+36, % tabslen " 个 profile 分别保存在 " PROFILE_DIRECTORY " 目录"
    Gui, 2:Add, Button, x+15 yp-6 w90 h25 gOpenProfileDirectory, 打开目录
    Gui, 2:Add, Button, x+6 yp w115 h25 gShowSkillAdvanced, 高级技能设置

    Gui, 2:Add, Text, x16 y544 w280 h22 vSettingsFeedback c348017
    Gui, 2:Add, Button, x302 y538 w82 h28 Default gSaveAppSettings, 应用并保存
    Gui, 2:Add, Button, x392 y538 w82 h28 gCloseAppSettings, 取消
    Gui, 2:Show, w490 h582
    Return
}

ShowSkillAdvancedWindow(profileIndex){
    Global
    advancedProfileIndex:=profileIndex
    Gui, 3:Destroy
    Gui, 3:New, +Owner2 +OwnDialogs -MaximizeBox -MinimizeBox, % "高级技能设置 - " tabsarray[profileIndex]
    Gui, 3:Margin, 16, 14
    Gui, 3:Font, s9, Segoe UI
    Gui, 3:Add, Text, x90 y16 w55 Center, 优先级
    Gui, 3:Add, Text, x160 y16 w65 Center, 重复次数
    Gui, 3:Add, Text, x240 y16 w75 Center, 重复间隔
    Gui, 3:Add, Text, x330 y16 w105 Center, 按键触发键
    skillLabels:=["技能一", "技能二", "技能三", "技能四", "左键技能", "右键技能"]
    Loop, 6
    {
        rowY:=44+(A_Index-1)*34
        priority:=combats[profileIndex][A_Index]["priority"]
        repeatCount:=combats[profileIndex][A_Index]["repeat"]
        repeatInterval:=combats[profileIndex][A_Index]["repeatinterval"]
        triggerButton:=combats[profileIndex][A_Index]["triggerbutton"]
        if (triggerButton="")
            triggerButton:="LButton"
        Gui, 3:Add, Text, % "x16 y" rowY+4 " w65 Right", % skillLabels[A_Index] "："
        Gui, 3:Add, Edit, % "x92 y" rowY " w52 Number"
        Gui, 3:Add, UpDown, % "vskillAdvanced" A_Index "Priority Range1-100", %priority%
        Gui, 3:Add, Edit, % "x166 y" rowY " w52 Number"
        Gui, 3:Add, UpDown, % "vskillAdvanced" A_Index "Repeat Range1-100", %repeatCount%
        Gui, 3:Add, Edit, % "x246 y" rowY " w65 Number"
        Gui, 3:Add, UpDown, % "vskillAdvanced" A_Index "RepeatInterval Range0-5000", %repeatInterval%
        Gui, 3:Add, Edit, % "x334 y" rowY " w100 vskillAdvanced" A_Index "Trigger", %triggerButton%
    }
    Gui, 3:Add, Text, x16 y255 w280 c666666, 按键触发键仅在策略选择“按键触发”时使用。
    Gui, 3:Add, Button, x276 y282 w80 h28 Default gSaveSkillAdvanced, 保存
    Gui, 3:Add, Button, x364 y282 w80 h28 gCloseSkillAdvanced, 取消
    Gui, 3:Show, w460 h326
    Return
}

ApplyAppSettings(){
    Global
    Gui, 2:Submit, NoHide
    settingsResolution:=Trim(settingsResolution)
    settingsSafeZone:=StrReplace(Trim(settingsSafeZone), " ", "")

    if (!RegExMatch(settingsResolution, "i)^(Auto|[1-9]\d{2,4}x[1-9]\d{2,4})$"))
    {
        MsgBox, 48, 设置有误, 游戏分辨率应为 Auto 或“宽x高”，例如 1920x1080。
        Return False
    }
    if (!RegExMatch(settingsGameGamma, "^\d+(\.\d+)?$") or settingsGameGamma<0.5 or settingsGameGamma>1.5)
    {
        MsgBox, 48, 设置有误, 游戏 Gamma 必须在 0.5 到 1.5 之间。
        Return False
    }
    if (!RegExMatch(settingsBuffPercent, "^\d+(\.\d+)?$") or settingsBuffPercent<0 or settingsBuffPercent>100)
    {
        MsgBox, 48, 设置有误, Buff 提前刷新百分比必须在 0 到 100 之间。
        Return False
    }
    if (!RegExMatch(settingsMaxReforge, "^\d+$") or settingsMaxReforge<1 or settingsMaxReforge>999)
    {
        MsgBox, 48, 设置有误, 最大重铸次数必须是 1 到 999 之间的整数。
        Return False
    }
    if (!RegExMatch(settingsMouseSpeed, "^\d+$") or settingsMouseSpeed<0 or settingsMouseSpeed>100)
    {
        MsgBox, 48, 设置有误, 自定义鼠标速度必须是 0 到 100 之间的整数。
        Return False
    }
    if (!RegExMatch(settingsAnimationDelay, "^\d+$") or settingsAnimationDelay<0 or settingsAnimationDelay>5000)
    {
        MsgBox, 48, 设置有误, 自定义动画延迟必须是 0 到 5000 之间的整数。
        Return False
    }

    newSafeZone:={}
    if (settingsSafeZone!="")
    {
        Loop, Parse, settingsSafeZone, CSV
        {
            if (!RegExMatch(A_LoopField, "^\d{1,2}$") or A_LoopField<1 or A_LoopField>99)
            {
                MsgBox, 48, 设置有误, 安全格必须是 1 到 99 的整数，并使用英文逗号分隔。
                Return False
            }
            newSafeZone[A_LoopField]:=1
        }
    }

    safezone:=newSafeZone
    d3only:=settingsD3Only
    runOnStart:=settingsRunOnStart
    gameResolution:=RegExMatch(settingsResolution, "i)^auto$") ? "Auto" : settingsResolution
    gameGamma:=settingsGameGamma+0
    buffpercent:=(settingsBuffPercent+0)/100
    maxreforge:=settingsMaxReforge
    helperMouseSpeed:=settingsMouseSpeed
    helperAnimationDelay:=settingsAnimationDelay
    SendMode, %settingsSendMode%

    TitleString:=(d3only)? "暗黑3技能连点器":"鼠标键盘连点器"
    TITLE:=TitleString " " DISPLAY_VERSION_LABEL "   by " PROJECT_MAINTAINER
    GuiControl, 1:, TitleBarText, %TITLE%
    GuiControl, 1:, CurrentmodeText, %A_SendMode%
    Gui, 1:Default
    SetSalvageHelper()
    Gui, 1:Submit, NoHide
    SaveCfgFile(SETTINGS_FILE, profileFiles, currentProfile, safezone, CONFIG_SCHEMA_VERSION)
    Return True
}

/*
在Gui创建完成后行的一些初始化
参数：
    无
返回：
    无
*/
StartUp(){
    Global
    Gosub, SetSkillsetDropdown
    Gosub, SetStartRun
    Gosub, SetProfileKeybinding
    Gosub, SetMovingHelper
    Gosub, SetHelperKeybinding
    Gosub, SetQuickPause
    SetGambleHelper()
    SetLootHelper()
    SetReforgeHelper()
    SetSalvageHelper()
    SetCustomStanding()
    SetCustomMoving()
    SetCustomPotion()
    SetSkillQueue()
    SetStartMode()

    DllCall("RegisterShellHookWindow", "Ptr", A_ScriptHwnd)
    hHookMouse:=0
    OnMessage(DllCall("RegisterWindowMessage", "Str", "SHELLHOOK"), "Watchdog")
    Watchdog(4, 0)
}

/*
设置右下角图标菜单
参数：
    无
返回：
    无
*/
SetTrayMenu(){
    Global
    Menu, Tray, NoStandard
    Menu, Tray, Add, 显示主窗口, GuiShowMainWindow
    Menu, Tray, Add, 应用设置, ShowAppSettings
    Menu, Tray, Add, 保存所有设置, SaveNow
    Menu, Tray, Add, 关于, ShowAbout
    Menu, Tray, Add
    Menu, Tray, Add, 退出, GuiExit
    Menu, Tray, Default, 显示主窗口
    Menu, Tray, Click, 1
    Menu, Tray, Tip, %TITLE%
    Menu, Tray, Icon, , , 1
}

/*
读取配置文件，无配置文件则返回默认设置
参数：
    cfgFileName：文件名
    tabs：ByRef String，存储由竖线“|”分隔的配置名，用于初始化Tab控件
    profileFiles：ByRef Array，按界面顺序存储Profile文件名
    combats：ByRef Array，存储战斗宏相关配置
    others：ByRef Array，存储额外配置
    generals：ByRef Array，存储一些通用配置
返回：
    上次退出时激活的配置编号，用于初始化Tab控件
*/
ReadCfgFile(cfgFileName, ByRef tabs, ByRef profileFiles, ByRef combats, ByRef others, ByRef generals){
    local
    Global CONFIG_SCHEMA_VERSION, PROFILE_DIRECTORY

    activatedProfileFile:=""
    generals:={"enablegamblehelper":1, "gamblehelpertimes":15, "helperhotkey":"F5", "helpermethod":7
    , "d3only":1, "maxreforge":10, "startmethod":7, "starthotkey":"F2", "enablesmartpause":1
    , "salvagehelpermethod":1, "reforgehelpermethod":1, "enablesalvagehelper":0, "enablesoundplay":1
    , "enableconverthelper":0, "enablereforgehelper":0, "enableupgradehelper":0, "enableabandonhelper":0
    , "runonstart":1, "custommoving":0, "custommovinghk":"e", "customstanding":0, "customstandinghk":"LShift"
    , "custompotion":0, "custompotionhk":"q", "helpermousespeed":2, "safezone":"61,62,63"
    , "helperspeed":3, "gamegamma":1.000000, "sendmode":"Event", "helperanimationdelay":150
    , "buffpercent":0.050000, "enableloothelper":0, "loothelpertimes":30, "compactmode":0, "gameresolution":"Auto"}

    if FileExist(cfgFileName)
    {
        IniRead, ver, %cfgFileName%, General, version, 0
        if (CONFIG_SCHEMA_VERSION != ver)
            MsgBox, 配置文件版本不匹配。程序会尽量兼容读取，请在“应用设置”中检查后重新保存。
        IniRead, activatedProfileFile, %cfgFileName%, General, activatedprofile
        IniRead, helperhotkey, %cfgFileName%, General, helperhotkey, F5
        IniRead, helpermethod, %cfgFileName%, General, helpermethod, 7
        IniRead, enablegamblehelper, %cfgFileName%, General, enablegamblehelper, 1
        IniRead, gamblehelpertimes, %cfgFileName%, General, gamblehelpertimes, 15
        IniRead, enablesalvagehelper, %cfgFileName%, General, enablesalvagehelper, 0
        IniRead, salvagehelpermethod, %cfgFileName%, General, salvagehelpermethod, 1
        IniRead, reforgehelpermethod, %cfgFileName%, General, reforgehelpermethod, 1
        IniRead, enablereforgehelper, %cfgFileName%, General, enablereforgehelper, 0
        IniRead, enableconverthelper, %cfgFileName%, General, enableconverthelper, 0
        IniRead, enableupgradehelper, %cfgFileName%, General, enableupgradehelper, 0
        IniRead, enablesmartpause, %cfgFileName%, General, enablesmartpause, 0
        IniRead, enablesoundplay, %cfgFileName%, General, enablesoundplay, 1
        IniRead, enableabandonhelper, %cfgFileName%, General, enableabandonhelper, 0
        IniRead, startmethod, %cfgFileName%, General, startmethod, 7
        IniRead, starthotkey, %cfgFileName%, General, starthotkey, F2
        IniRead, custommoving, %cfgFileName%, General, custommoving, 0
        IniRead, custommovinghk, %cfgFileName%, General, custommovinghk, e
        IniRead, customstanding, %cfgFileName%, General, customstanding, 0
        IniRead, customstandinghk, %cfgFileName%, General, customstandinghk, LShift
        IniRead, custompotion, %cfgFileName%, General, custompotion, 0
        IniRead, custompotionhk, %cfgFileName%, General, custompotionhk, q
        IniRead, safezone, %cfgFileName%, General, safezone, "61,62,63"
        IniRead, helperspeed, %cfgFileName%, General, helperspeed, 3
        IniRead, gamegamma, %cfgFileName%, General, gamegamma, 1.000000
        IniRead, sendmode, %cfgFileName%, General, sendmode, Event
        IniRead, buffpercent, %cfgFileName%, General, buffpercent, 0.050000
        IniRead, compactmode, %cfgFileName%, General, compactmode, 0
        IniRead, runonstart, %cfgFileName%, General, runonstart, 1
        IniRead, gameresolution, %cfgFileName%, General, gameresolution, Auto
        IniRead, enableloothelper, %cfgFileName%, General, enableloothelper, 0
        IniRead, loothelpertimes, %cfgFileName%, General, loothelpertimes, 30
        IniRead, helpermousespeed, %cfgFileName%, General, helpermousespeed, 2
        IniRead, helperanimationdelay, %cfgFileName%, General, helperanimationdelay, 150
        IniRead, d3only, %cfgFileName%, General, d3only, 1
        IniRead, maxreforge, %cfgFileName%, General, maxreforge, 10
        generals:={"helpermethod":helpermethod, "helperhotkey":helperhotkey, "maxreforge":maxreforge
        , "enablesalvagehelper":enablesalvagehelper, "salvagehelpermethod":salvagehelpermethod, "reforgehelpermethod":reforgehelpermethod
        , "d3only":d3only, "enablereforgehelper":enablereforgehelper, "runonstart":runonstart, "gameresolution":gameresolution
        , "enablegamblehelper":enablegamblehelper, "gamblehelpertimes":gamblehelpertimes, "helpermousespeed":helpermousespeed
        , "startmethod":startmethod, "starthotkey":starthotkey, "enableupgradehelper":enableupgradehelper, "helperanimationdelay":helperanimationdelay
        , "enablesmartpause":enablesmartpause, "enablesoundplay":enablesoundplay, "enableconverthelper":enableconverthelper, "enableabandonhelper":enableabandonhelper
        , "custommoving":custommoving, "custommovinghk":custommovinghk, "customstanding":customstanding, "customstandinghk":customstandinghk
        , "custompotion":custompotion, "custompotionhk":custompotionhk, "safezone":safezone, "helperspeed":helperspeed
        , "gamegamma":gamegamma, "sendmode":sendmode, "buffpercent":buffpercent, "enableloothelper":enableloothelper
        , "loothelpertimes":loothelpertimes, "compactmode":compactmode}
    }

    FileCreateDir, %PROFILE_DIRECTORY%
    profileFileList:=""
    Loop, Files, % PROFILE_DIRECTORY "\*.ini", F
        profileFileList .= A_LoopFileName "`n"
    Sort, profileFileList
    profileFileList:=RTrim(profileFileList, "`n")
    if (profileFileList="")
    {
        defaultProfileFile:="配置1.ini"
        CreateDefaultProfileFile(PROFILE_DIRECTORY "\" defaultProfileFile)
        profileFileList:=defaultProfileFile
    }

    tabs:=""
    profileFiles:=[]
    combats:=[]
    others:=[]
    currentProfile:=1
    Loop, Parse, profileFileList, `n, `r
    {
        profileFileName:=A_LoopField
        if (profileFileName="")
            Continue
        profileFiles.Push(profileFileName)
        profileName:=RegExReplace(profileFileName, "i)\.ini$")
        tabs .= (tabs="" ? "" : "|") profileName
        if (profileFileName=activatedProfileFile)
            currentProfile:=A_Index
        sourceFile:=PROFILE_DIRECTORY "\" profileFileName
        trow:=[]
        Loop, 6
        {
            IniRead, hk, %sourceFile%, Profile, skill_%A_Index%, %A_Index%
            IniRead, ac, %sourceFile%, Profile, action_%A_Index%, 1
            IniRead, iv, %sourceFile%, Profile, interval_%A_Index%, 300
            IniRead, dy, %sourceFile%, Profile, delay_%A_Index%, 10
            IniRead, rd, %sourceFile%, Profile, random_%A_Index%, 1
            IniRead, pr, %sourceFile%, Profile, priority_%A_Index%, 1
            IniRead, rp, %sourceFile%, Profile, repeat_%A_Index%, 1
            IniRead, rpiv, %sourceFile%, Profile, repeatinterval_%A_Index%, 30
            IniRead, tgbt, %sourceFile%, Profile, triggerbutton_%A_Index%, LButton
            trow.Push({"hotkey":hk, "action":ac, "interval":iv, "delay":dy, "random":rd, "priority":pr
            , "repeat":rp, "repeatinterval":rpiv, "triggerbutton":tgbt})
        }
        combats.Push(trow)
        IniRead, pfmd, %sourceFile%, Profile, profilehkmethod, 1
        IniRead, pfhk, %sourceFile%, Profile, profilehkkey
        IniRead, pfmv, %sourceFile%, Profile, movingmethod, 1
        IniRead, pfmi, %sourceFile%, Profile, movinginterval, 100
        IniRead, pfpo, %sourceFile%, Profile, potionmethod, 1
        IniRead, pfpi, %sourceFile%, Profile, potioninterval, 500
        IniRead, pflm, %sourceFile%, Profile, lazymode, 1
        IniRead, pfqp, %sourceFile%, Profile, enablequickpause, 0
        IniRead, pfqpm1, %sourceFile%, Profile, quickpausemethod1, 1
        IniRead, pfqpm2, %sourceFile%, Profile, quickpausemethod2, 1
        IniRead, pfqpm3, %sourceFile%, Profile, quickpausemethod3, 1
        IniRead, pfqpdy, %sourceFile%, Profile, quickpausedelay, 1500
        IniRead, pfusq, %sourceFile%, Profile, useskillqueue, 0
        IniRead, pfusqiv, %sourceFile%, Profile, useskillqueueinterval, 200
        IniRead, pfasm, %sourceFile%, Profile, autostartmarco, 0
        others.Push({"profilemethod":pfmd, "profilehotkey":pfhk, "movingmethod":pfmv, "movinginterval":pfmi
        , "potionmethod":pfpo, "potioninterval":pfpi, "lazymode":pflm, "enablequickpause":pfqp
        , "quickpausemethod1":pfqpm1, "quickpausemethod2":pfqpm2, "quickpausemethod3":pfqpm3
        , "quickpausedelay":pfqpdy, "useskillqueue":pfusq, "useskillqueueinterval":pfusqiv, "autostartmarco":pfasm})
    }
    Return currentProfile
}

/*
保存配置文件
参数：
    cfgFileName：文件名
    profileFiles：Array，按界面顺序存储Profile文件名
    currentProfile：int， 当前激活的配置页面编号
    safezone： Array，安全区域的配置int
    configSchemaVersion：int，配置格式版本
返回：
    无
*/
SaveCfgFile(cfgFileName, profileFiles, currentProfile, safezone, configSchemaVersion){
    Gui, 1:Default
    createOrTruncateFile(cfgFileName)

    GuiControlGet, extraGambleHelperCKbox
    GuiControlGet, extraGambleHelperUpdown
    GuiControlGet, helperKeybindingdropdown
    GuiControlGet, helperKeybindingHK  
    GuiControlGet, extraLootHelperCkbox
    GuiControlGet, extraLootHelperUpdown
    GuiControlGet, extraSmartPause
    GuiControlGet, extraSalvageHelperCkbox
    GuiControlGet, extraSalvageHelperDropdown
    GuiControlGet, extraReforgeHelperCkbox
    GuiControlGet, extraReforgeHelperDropdown
    GuiControlGet, extraConvertHelperCkbox
    GuiControlGet, extraUpgradeHelperCkbox
    GuiControlGet, extraSoundonProfileSwitch
    GuiControlGet, extraAbandonHelperCkbox
    GuiControlGet, extraCustomMoving
    GuiControlGet, extraCustomMovingHK
    GuiControlGet, extraCustomStanding
    GuiControlGet, extraCustomStandingHK
    GuiControlGet, extraCustomPotion
    GuiControlGet, extraCustomPotionHK
    GuiControlGet, helperAnimationSpeedDropdown

    IniWrite, %configSchemaVersion%, %cfgFileName%, General, version
    IniWrite, % profileFiles[currentProfile], %cfgFileName%, General, activatedprofile
    IniWrite, %extraGambleHelperCKbox%, %cfgFileName%, General, enablegamblehelper
    IniWrite, %extraGambleHelperUpdown%, %cfgFileName%, General, gamblehelpertimes
    IniWrite, %extraSmartPause%, %cfgFileName%, General, enablesmartpause
    IniWrite, %extraSalvageHelperCkbox%, %cfgFileName%, General, enablesalvagehelper
    IniWrite, %extraSalvageHelperDropdown%, %cfgFileName%, General, salvagehelpermethod
    IniWrite, %extraReforgeHelperCkbox%, %cfgFileName%, General, enablereforgehelper
    IniWrite, %extraReforgeHelperDropdown%, %cfgFileName%, General, reforgehelpermethod
    Global maxreforge
    IniWrite, %maxreforge%, %cfgFileName%, General, maxreforge
    IniWrite, %extraUpgradeHelperCkbox%, %cfgFileName%, General, enableupgradehelper
    IniWrite, %extraConvertHelperCkbox%, %cfgFileName%, General, enableconverthelper
    IniWrite, %extraAbandonHelperCkbox%, %cfgFileName%, General, enableabandonhelper
    IniWrite, %extraLootHelperCkbox%, %cfgFileName%, General, enableloothelper
    IniWrite, %extraLootHelperUpdown%, %cfgFileName%, General, loothelpertimes
    IniWrite, %extraSoundonProfileSwitch%, %cfgFileName%, General, enablesoundplay
    IniWrite, %helperKeybindingHK%, %cfgFileName%, General, helperhotkey
    IniWrite, %helperKeybindingdropdown%, %cfgFileName%, General, helpermethod
    IniWrite, %extraCustomMoving%, %cfgFileName%, General, custommoving
    IniWrite, %extraCustomMovingHK%, %cfgFileName%, General, custommovinghk
    IniWrite, %extraCustomStanding%, %cfgFileName%, General, customstanding
    IniWrite, %extraCustomStandingHK%, %cfgFileName%, General, customstandinghk
    IniWrite, %extraCustomPotion%, %cfgFileName%, General, custompotion
    IniWrite, %extraCustomPotionHK%, %cfgFileName%, General, custompotionhk
    IniWrite, %helperAnimationSpeedDropdown%, %cfgFileName%, General, helperspeed
    safezone:=keyJoin(",", safezone)
    IniWrite, %safezone%, %cfgFileName%, General, safezone
    Global gameGamma, buffpercent, isCompact, runOnStart, gameResolution, helperAnimationDelay, helperMouseSpeed, d3only
    IniWrite, %d3only%, %cfgFileName%, General, d3only
    IniWrite, %gameGamma%, %cfgFileName%, General, gamegamma
    IniWrite, %A_SendMode%, %cfgFileName%, General, sendmode
    IniWrite, %buffpercent%, %cfgFileName%, General, buffpercent
    IniWrite, %isCompact%, %cfgFileName%, General, compactmode
    IniWrite, %runOnStart%, %cfgFileName%, General, runonstart
    IniWrite, %gameResolution%, %cfgFileName%, General, gameresolution
    IniWrite, %helperAnimationDelay%, %cfgFileName%, General, helperanimationdelay
    IniWrite, %helperMouseSpeed%, %cfgFileName%, General, helpermousespeed
    
    GuiControlGet, StartRunDropdown
    GuiControlGet, StartRunHKInput
    IniWrite, %StartRunDropdown%, %cfgFileName%, General, startmethod
    IniWrite, %StartRunHKInput%, %cfgFileName%, General, starthotkey
    global combats, PROFILE_DIRECTORY
    FileCreateDir, %PROFILE_DIRECTORY%
    for cSection, profileFileName in profileFiles
    {
        profileFile:=PROFILE_DIRECTORY "\" profileFileName
        createOrTruncateFile(profileFile)
        profileSection:="Profile"
        Loop, 6
        {
            GuiControlGet, skillset%cSection%s%A_Index%hotkey
            GuiControlGet, skillset%cSection%s%A_Index%dropdown
            GuiControlGet, skillset%cSection%s%A_Index%updown
            GuiControlGet, skillset%cSection%s%A_Index%delayupdown
            GuiControlGet, skillset%cSection%s%A_Index%randomckbox
            pr:=combats[cSection][A_Index]["priority"]
            rp:=combats[cSection][A_Index]["repeat"]
            rpiv:=combats[cSection][A_Index]["repeatinterval"]
            tgbt:=combats[cSection][A_Index]["triggerbutton"]
            IniWrite, % skillset%cSection%s%A_Index%dropdown, %profileFile%, %profileSection%, action_%A_Index%
            IniWrite, % skillset%cSection%s%A_Index%updown, %profileFile%, %profileSection%, interval_%A_Index%
            IniWrite, % skillset%cSection%s%A_Index%delayupdown, %profileFile%, %profileSection%, delay_%A_Index%
            IniWrite, % skillset%cSection%s%A_Index%randomckbox, %profileFile%, %profileSection%, random_%A_Index%
            IniWrite, % pr, %profileFile%, %profileSection%, priority_%A_Index%
            IniWrite, % rp, %profileFile%, %profileSection%, repeat_%A_Index%
            IniWrite, % rpiv, %profileFile%, %profileSection%, repeatinterval_%A_Index%
            IniWrite, % tgbt, %profileFile%, %profileSection%, triggerbutton_%A_Index%
            if (A_Index < 5)
            {
                IniWrite, % skillset%cSection%s%A_Index%hotkey, %profileFile%, %profileSection%, skill_%A_Index%
            }
        }
        GuiControlGet, skillset%cSection%profilekeybindingdropdown
        GuiControlGet, skillset%cSection%profilekeybindinghkbox
        IniWrite, % skillset%cSection%profilekeybindingdropdown, %profileFile%, %profileSection%, profilehkmethod
        IniWrite, % skillset%cSection%profilekeybindinghkbox, %profileFile%, %profileSection%, profilehkkey
        GuiControlGet, skillset%cSection%movingdropdown
        GuiControlGet, skillset%cSection%movingupdown
        IniWrite, % skillset%cSection%movingdropdown, %profileFile%, %profileSection%, movingmethod
        IniWrite, % skillset%cSection%movingupdown, %profileFile%, %profileSection%, movinginterval
        GuiControlGet, skillset%cSection%potiondropdown
        GuiControlGet, skillset%cSection%potionupdown
        IniWrite, % skillset%cSection%potiondropdown, %profileFile%, %profileSection%, potionmethod
        IniWrite, % skillset%cSection%potionupdown, %profileFile%, %profileSection%, potioninterval
        GuiControlGet, skillset%cSection%profilestartmodedropdown
        IniWrite, % skillset%cSection%profilestartmodedropdown, %profileFile%, %profileSection%, lazymode
        GuiControlGet, skillset%cSection%clickpauseckbox
        IniWrite, % skillset%cSection%clickpauseckbox, %profileFile%, %profileSection%, enablequickpause
        GuiControlGet, skillset%cSection%clickpausedropdown1
        IniWrite, % skillset%cSection%clickpausedropdown1, %profileFile%, %profileSection%, quickpausemethod1
        GuiControlGet, skillset%cSection%clickpausedropdown2
        IniWrite, % skillset%cSection%clickpausedropdown2, %profileFile%, %profileSection%, quickpausemethod2
        GuiControlGet, skillset%cSection%clickpausedropdown3
        IniWrite, % skillset%cSection%clickpausedropdown3, %profileFile%, %profileSection%, quickpausemethod3
        GuiControlGet, skillset%cSection%clickpauseupdown
        IniWrite, % skillset%cSection%clickpauseupdown, %profileFile%, %profileSection%, quickpausedelay
        GuiControlGet, skillset%cSection%useskillqueueckbox
        IniWrite, % skillset%cSection%useskillqueueckbox, %profileFile%, %profileSection%, useskillqueue
        GuiControlGet, skillset%cSection%useskillqueueedit
        IniWrite, % skillset%cSection%useskillqueueedit, %profileFile%, %profileSection%, useskillqueueinterval
        GuiControlGet, skillset%cSection%autostartmarcockbox
        IniWrite, % skillset%cSection%autostartmarcockbox, %profileFile%, %profileSection%, autostartmarco
    }
    Return
}

CreateDefaultProfileFile(profileFile){
    createOrTruncateFile(profileFile)
    Loop, 6
    {
        IniWrite, 1, %profileFile%, Profile, action_%A_Index%
        IniWrite, 300, %profileFile%, Profile, interval_%A_Index%
        IniWrite, 10, %profileFile%, Profile, delay_%A_Index%
        IniWrite, 1, %profileFile%, Profile, random_%A_Index%
        IniWrite, 1, %profileFile%, Profile, priority_%A_Index%
        IniWrite, 1, %profileFile%, Profile, repeat_%A_Index%
        IniWrite, 30, %profileFile%, Profile, repeatinterval_%A_Index%
        IniWrite, LButton, %profileFile%, Profile, triggerbutton_%A_Index%
        if (A_Index<5)
            IniWrite, %A_Index%, %profileFile%, Profile, skill_%A_Index%
    }
    IniWrite, 1, %profileFile%, Profile, profilehkmethod
    IniWrite, 1, %profileFile%, Profile, movingmethod
    IniWrite, 100, %profileFile%, Profile, movinginterval
    IniWrite, 1, %profileFile%, Profile, potionmethod
    IniWrite, 500, %profileFile%, Profile, potioninterval
    IniWrite, 1, %profileFile%, Profile, lazymode
    IniWrite, 0, %profileFile%, Profile, enablequickpause
    IniWrite, 1, %profileFile%, Profile, quickpausemethod1
    IniWrite, 1, %profileFile%, Profile, quickpausemethod2
    IniWrite, 1, %profileFile%, Profile, quickpausemethod3
    IniWrite, 1500, %profileFile%, Profile, quickpausedelay
    IniWrite, 0, %profileFile%, Profile, useskillqueue
    IniWrite, 200, %profileFile%, Profile, useskillqueueinterval
    IniWrite, 0, %profileFile%, Profile, autostartmarco
}

IsValidProfileName(profileName){
    if (profileName="" or RegExMatch(profileName, "[<>:|?*\\/]") or InStr(profileName, Chr(34)))
        Return False
    if RegExMatch(profileName, "[ .]$")
        Return False
    Return !RegExMatch(profileName, "i)^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$")
}

/*
计算当前分辨率下技能buff条最左边像素的坐标
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
    buttonID：int，按钮的ID，最左为1，最右（鼠标右键）为6
    percent： float，从左计算，取样点在Buff条上位置的百分比
返回：
    [x坐标，y坐标]
*/
getSkillButtonBuffPos(D3W, D3H, buttonID, percent){
    static x:=[1288, 1377, 1465, 1554, 1647, 1734]
    static w:=63
    y:=1328*D3H/1440
    Return [Round(D3W/2-(3440/2-x[buttonID]-percent*w)*D3H/1440), Round(y)]
}

/*
将16进制的颜色标签转化为RGB array。 FFFFFF -> [255, 255, 255]
当游戏gamma不为1时，会尝试进行gamma修正。
参数：
    vthiscolor：16进制的RGB颜色标签，PixelGetColor直出
返回：
    [R，G，B]
*/
splitRGB(vthiscolor){
    local
    Global gameGamma
    vblue:=(vthiscolor & 0xFF)
    vgreen:=((vthiscolor & 0xFF00) >> 8)
    vred:=((vthiscolor & 0xFF0000) >> 16)
    if (Abs(gameGamma-1)>=0.01)
    {
        vblue:=((vblue / 255) ** (1.75*gameGamma-0.75)) * 255
        vgreen:=((vgreen / 255) ** (1.9*gameGamma-0.9)) * 255
        vred:=((vred / 255) ** (1.9*gameGamma-0.9)) * 255
    }
    Return [vred, vgreen, vblue]
}

/*
负责发送技能按键
参数：
    currentProfile：int，当前激活的配置编号
    nskill: int, 技能按钮编号 1-6
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
    forceStandingKey：强制站立按键
    useSkillQueue：Bool，是否使用技能列表
返回：
    无
*/
skillKey(currentProfile, nskill, D3W, D3H, forceStandingKey, useSkillQueue){
    local
    Global vPausing, vRunning, skillQueue, buffpercent, gameX, gameY, syncTimer, syncDelay
    global combats
    GuiControlGet, skillset%currentProfile%s%nskill%hotkey
    GuiControlGet, skillset%currentProfile%s%nskill%delayupdown
    GuiControlGet, skillset%currentProfile%s%nskill%randomckbox
    GuiControlGet, skillset%currentProfile%s%nskill%updown
    Loop, 6
    {
        GuiControlGet, skillset%currentProfile%s%A_Index%dropdown
        ; 循环检查其他按键的策略选择
        if (A_Index = nskill){
            Continue
        }
        ; 如果有其他按键策略为保持buff，且优先级更高
        if (skillset%currentProfile%s%A_Index%dropdown = 4 and combats[currentProfile][A_Index]["priority"]>combats[currentProfile][nskill]["priority"])
        {
            ; 检查其buff是否激活
            magicXY:=getSkillButtonBuffPos(D3W, D3H, A_Index, buffpercent)
            crgb:=getPixelRGB(magicXY)
            ; 如果已激活，直接返回
            if (crgb[2]>=95) {
                Return
            }
        }
    }
    k:=skillset%currentProfile%s%nskill%hotkey
    switch skillset%currentProfile%s%nskill%dropdown
    {
        ; 连点、左键触发
        case 3,5:
            if !(vPausing) and vRunning
            {
                if (abs(skillset%currentProfile%s%nskill%delayupdown)>20)
                {
                    if (skillset%currentProfile%s%nskill%randomckbox)
                    {
                        Random, delay, 10, abs(skillset%currentProfile%s%nskill%delayupdown)
                    }
                    Else
                    {
                        delay:=abs(skillset%currentProfile%s%nskill%delayupdown)
                    }
                    syncDelay[nskill]:=delay
                    if (skillset%currentProfile%s%nskill%delayupdown<0)
                    {
                        syncDelay[nskill]:=skillset%currentProfile%s%nskill%updown - delay
                    }
                    syncTimer[nskill]:=A_TickCount
                    while (A_TickCount - syncTimer[nskill] <= syncDelay[nskill])
                    {
                        sleep 10
                    }
                }
                ; 重复连点
                Loop,% combats[currentProfile][nskill]["repeat"]
                {
                    if useSkillQueue
                    {
                        ; 当技能列表大于1000时什么都不做，防止占用过多内存
                        if (skillQueue.Count() < 1000){
                            ; 按键加入技能列表头部
                            ; [k, 3] k是具体按键，3代表因为连点加入
                            skillQueue.InsertAt(1, [k, 3])
                        }
                    }
                    Else
                    {
                        Send {Blind}{%k%}
                    }
                    if (combats[currentProfile][nskill]["repeat"] > 1){
                        sleep, % combats[currentProfile][nskill]["repeatinterval"]
                    }

                }
            }
        ; 保持buff
        case 4:
            if !(vPausing) and vRunning
            {
                ; 获得对应按键buff条最左侧坐标
                magicXY:=getSkillButtonBuffPos(D3W, D3H, nskill, buffpercent)
                crgb:=getPixelRGB(magicXY)
                ; 具体判断是否需要补buff
                if (crgb[2]<95)
                {
                    switch nskill
                    {
                        case 5:
                            ; 判断按键是否是左键
                            if useSkillQueue
                            {
                                if (skillQueue.Count() < 1000){
                                    ; 4代表因为补buff加入
                                    skillQueue.Push([k, 4])
                                }
                            }
                            Else
                            {
                                ; 判断是否需要强制站立再点击左键
                                if GetKeyState(forceStandingKey)
                                {
                                    Send {Blind}{%k%}
                                }
                                Else
                                {
                                    Send {Blind}{%forceStandingKey% down}{%k% down}
                                    Send {Blind}{%k% up}{%forceStandingKey% up}
                                }
                            }
                        Default:
                            if useSkillQueue
                            {
                                if (skillQueue.Count() < 1000){
                                    skillQueue.Push([k, 4])
                                }
                            }
                            Else
                            {
                                Send {Blind}{%k%}
                            }
                    }
                }
            }
    }
    Return
}

/*
清空配置文件，并写入默认的文件头
参数：
    FileName：配置文件名
返回：
    无
*/
createOrTruncateFile(FileName){
    if (FileName = "")
    {
        return
    }
    file:=FileOpen(FileName, "w", "UTF-16")
    if !IsObject(file)
    {
        MsgBox 无法创建或写入文件："%FileName%"
        return
    }
    file.Write("; ===============================================`r`n")
    file.Write("; D3KeyHelper 配置文件，由应用设置界面自动维护。`r`n")
    file.Write("; 全局设置与各 Profile 已分开存储。`r`n")
    file.Write("; ===============================================`r`n")
    file.Close()
}

/*
负责开启助手宏
参数：
    无
返回：
    无
*/
UtilityHelper(){
    local
    Global helperRunning, helperBreak, helperDelay, mouseDelay, vRunning, helperAnimationDelay, helperMouseSpeed, gameX, gameY
    if helperRunning{
        ; 防止过快连按
        ; 宏在执行中再按可以打断
        helperBreak:=True
        helperRunning:=False
        Sleep, 200
        Return
    }
    ; 如果战斗宏开启或者无法获取游戏分辨率，则返回
    if (vRunning or !getGameResulution(D3W, D3H)){
        Return
    }
    gameXY:=getGameXYonScreen(0,0)
    gameX:=gameXY[1]
    gameY:=gameXY[2]
    helperRunning:=True
    helperBreak:=False
    GuiControlGet, extraGambleHelperCKbox
    GuiControlGet, extraLootHelperCkbox
    GuiControlGet, extraSalvageHelperCkbox
    GuiControlGet, extraReforgeHelperCkbox
    GuiControlGet, extraUpgradeHelperCkbox
    GuiControlGet, extraConvertHelperCkbox
    GuiControlGet, extraAbandonHelperCkbox
    GuiControlGet, extraSalvageHelperDropdown
    GuiControlGet, helperAnimationSpeedDropdown
    MouseGetPos, xpos, ypos ; 当前鼠标位置，用于宏结束后返回
    ; 载入预设动画速度
    switch helperAnimationSpeedDropdown
    {
        case 1:
            mouseDelay:=0
            helperDelay:=50
        case 2:
            mouseDelay:=1
            helperDelay:=100
        case 3:
            mouseDelay:=2
            helperDelay:=150
        case 4:
            mouseDelay:=3
            helperDelay:=200
        Default:
            mouseDelay:=helperMouseSpeed
            helperDelay:=helperAnimationDelay
    }
    SetDefaultMouseSpeed, mouseDelay
    ; 鼠标位置。1：位于背包栏。2：位于储物栏（银行）。-1：其他
    mousePosition:=-1
    if (xpos>D3W-(3440-2740)*D3H/1440 and ypos>730*D3H/1440 and ypos<1150*D3H/1440)
    {
        mousePosition:=1
    }
    else if (xpos>65*D3H/1440 and xpos<640*D3H/1440 and ypos>275*D3H/1440 and ypos<1150*D3H/1440)
    {
        mousePosition:=2
    }
    ; 当鼠标在左侧
    if (xpos<680*D3H/1440)
    {
        if (extraGambleHelperCKbox and isGambleOpen(D3W, D3H))
        {
            ; 赌博助手
            SetTimer, gambleHelper, -1
            Return
        }
    }

    ; 分解助手逻辑
    if (extraSalvageHelperCkbox)
    {
        ; 判断分解页面是否打开
        r:=isSalvagePageOpen(D3W, D3H)
        switch r[1]
        {
            ; 铁匠页面打开且分解页面打开
            case 2:
                if(extraSalvageHelperDropdown=1)    ;选择了快速分解
                {
                    ; 当鼠标在背包栏内
                    if(mousePosition = 1)
                    {
                        ; 执行快速分解
                        quickSalvageHelper(D3W, D3H, helperDelay)
                        helperRunning:=False
                    }
                }
                Else    ;选择其他分解选项
                {
                    salvageIconXY:=getSalvageIconXY(D3W, D3H, "center")
                    ; 批量按钮之间直接跳转，避免移动动画扫过已禁用的灰色按钮。
                    SetDefaultMouseSpeed, 0
                    MouseMove, salvageIconXY[1][1], salvageIconXY[1][2]
                    ; 判断拆解按钮是否已经按下
                    if (r[2][3]<10 and r[2][1]+r[2][2]>400)
                    {
                        if helperBreak
                        {
                            helperRunning:=False
                            Return
                        }
                        ; 分解按钮已经按下，先右键取消
                        Click, Right
                        Sleep, % Min(helperDelay, 20)
                        ; 取消后按钮状态可能改变，重新获取三种品质按钮的颜色。
                        p:=getSalvageIconXY(D3W, D3H, "edge")
                        r[3]:=getPixelRGB(p[2])
                        r[4]:=getPixelRGB(p[3])
                        r[5]:=getPixelRGB(p[4])
                    }
                    ; 灰色按钮为禁用态，只点击带有对应品质高亮色的按钮。
                    buttonEnabled:=[Min(r[3][1], r[3][2], r[3][3])>100, r[4][3]-r[4][1]>20 and r[4][3]-r[4][2]>10, r[5][1]-r[5][3]>20 and r[5][2]-r[5][3]>10]
                    _wait:=-1
                    for i, buttonIndex in [2, 3, 4]
                    {
                        if !buttonEnabled[i]
                            Continue
                        if helperBreak
                        {
                            helperRunning:=False
                            Return
                        }
                        MouseMove, salvageIconXY[buttonIndex][1], salvageIconXY[buttonIndex][2]
                        if quickSalvageHelper(D3W, D3H, helperDelay)
                        {
                            ; 启动逐格分解前等待批量分解动画完成
                            _wait:=-50
                        }
                    }
                    ; 点击分解按钮
                    MouseMove, salvageIconXY[1][1], salvageIconXY[1][2]
                    Sleep, % Min(helperDelay, 20)
                    Click
                    if helperBreak
                    {
                        helperRunning:=False
                        Return
                    }
                    Sleep, % Min(helperDelay, 20)
                    ; 执行一键分解
                    SetDefaultMouseSpeed, mouseDelay
                    fn:=Func("oneButtonSalvageHelper").Bind(D3W, D3H, xpos, ypos)
                    SetTimer, %fn%, %_wait%
                }
                Return
            case 1:
                ; 铁匠页面打开但是不在分解页面
                helperRunning:=False
                Return
            Default:
                ; 铁匠页面未打卡 
        }
    }
    ; 卡奈魔盒助手
    if (extraReforgeHelperCkbox or extraUpgradeHelperCkbox or extraConvertHelperCkbox)
    {
        switch isKanaiCubeOpen(D3W, D3H)
        {
            case 1:
                helperRunning:=False
                Return
            case 2:
            ; 一键重铸
                if (extraReforgeHelperCkbox and mousePosition=1)
                {
                    fn:=Func("oneButtonReforgeHelper").Bind(D3W, D3H, xpos, ypos)
                    SetTimer, %fn%, -1
                    Return
                }
            case 3:
            ; 一键升级
                if extraUpgradeHelperCkbox
                {
                    fn:=Func("oneButtonUpgradeConvertHelper").Bind(D3W, D3H, xpos, ypos)
                    SetTimer, %fn%, -1
                    Return
                }
            case 4:
            ; 一键转化
                if extraConvertHelperCkbox
                {
                    fn:=Func("oneButtonUpgradeConvertHelper").Bind(D3W, D3H, xpos, ypos)
                    SetTimer, %fn%, -1
                    Return
                }
            Default:
                ; 卡奈魔盒未打开
        }
    }
    ; 丢装备
    if (extraAbandonHelperCkbox and mousePosition>0 and isInventoryOpen(D3W, D3H))
    {
        fn:=Func("oneButtonAbandonHelper").Bind(D3W, D3H, xpos, ypos, mousePosition)
        SetTimer, %fn%, -1
        Return
    }
    ; 一键拾取
    if (extraLootHelperCkbox)
    {
        fn:=Func("lootHelper").Bind(D3W, D3H, helperDelay)
        SetTimer, %fn%, -1
        Return
    }
}

/*
负责一键重铸
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
    xpos：之前鼠标x坐标
    ypos：之前鼠标y坐标
返回：
    无
*/
oneButtonReforgeHelper(D3W, D3H, xpos, ypos){
    local
    Global helperRunning, helperBreak, helperDelay, mouseDelay, maxreforge
    GuiControlGet, extraReforgeHelperDropdown
    SetDefaultMouseSpeed, mouseDelay
    kanai:=getKanaiCubeButtonPos(D3W, D3H)
    box_1_1:=getInventorySpaceXY(D3W, D3H, 1, "kanai")
    box_1_2:=getInventorySpaceXY(D3W, D3H, 2, "kanai")
    Loop, %maxreforge% {
        q:=0
        ; 执行重铸
        Click, Right
        Sleep, helperDelay//4
        MouseMove, kanai[2][1], kanai[2][2]
        Click
        Sleep, helperDelay//4
        MouseMove, kanai[1][1], kanai[1][2]
        Click
        Sleep, helperDelay//4
        MouseMove, kanai[3][1], kanai[3][2]
        Click
        Sleep, helperDelay//4
        MouseMove, kanai[4][1], kanai[4][2]
        Click
        ; 判断重铸后的装备品质
        if (extraReforgeHelperDropdown > 1 and not helperBreak)
        {
            ;右键把装备再次放入魔盒
            MouseMove, xpos, ypos
            Click, Right
            ;鼠标移动到魔盒第一个格子位置，然后等待动画完毕
            MouseMove, box_1_1[1], box_1_1[2]
            Sleep, helperDelay//2
            ;条件重铸，需要判断重铸后的装备品质
            c_t:=[-255,-255,-255]
            StartTime1:=A_TickCount
            while (A_TickCount-StartTime1<=helperDelay)
            {
                ; 获取三个位于边框上的点颜色
                c:=getPixelsRGB(box_1_2[3]+1, box_1_2[2], 3, 1, "Max", False)
                if (c_t[1]=c[1] and c_t[2]=c[2] and c_t[3]=c[3]){
                    ; 当取色点颜色停止变化，动画显示完毕
                    Break
                }
                c_t:=c
                Sleep, 20
            }
            if ((c[1]>=70 or c[3]<=20) and Max(Abs(c[1]-c[2]), Abs(c[1]-c[3]), Abs(c[3]-c[2]))>20 and (c[1]+c[2]+c[3]<460)) {
                ; 装备是太古或者远古
                q:=(c[2]<35) ? 5:3
            } else if (c[3]>100 and c[3]>c[2] and c[2]>c[1]) {
                ; 装备是神圣装备
                q:=4
            } else {
                ; 装备是普通传奇
                q:=2
            }
            ; 鼠标回到原位置
            MouseMove, xpos, ypos
            if (q > extraReforgeHelperDropdown)
            {
                ;品质符合结束条件，退出
                Break
            }
        }
        Else
        {
            ;重铸一次，直接退出
            Break
        }
    }
    ; 鼠标回到原位置
    MouseMove, xpos, ypos
    helperRunning:=False
    Return
}

/*
负责一键升级稀有或转化材料
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
    xpos：之前鼠标x坐标
    ypos：之前鼠标y坐标
返回：
    无
*/
oneButtonUpgradeConvertHelper(D3W, D3H, xpos, ypos)
{
    local
    Global helperBreak, helperRunning, helperDelay, helperBagZone, mouseDelay
    helperBagZone:=make1DArray(60, -1)
    k:=getKanaiCubeButtonPos(D3W, D3H)
    ; 开启一单独线程查找空格子
    fn1:=Func("scanInventorySpaceGDIP").Bind(D3W, D3H)
    SetTimer, %fn1%, -1

    SetDefaultMouseSpeed, mouseDelay
    i:=1 ; 当前格子ID
    w:=0
    while (i<=60)
    {
        ; 防卡死
        w++
        if (helperBreak or w>200) {
            Break
        }
        ; 当前格子情况
        switch helperBagZone[i]
        {
            case -1:
                ; 还未探开，继续等待
                Sleep, 20
            case 10:
                ; 格子有装备
                pLargeItem:=False
                ; 获取当前格子坐标和下方格子坐标
                m:=getInventorySpaceXY(D3W, D3H, i, "bag")
                m2:=getInventorySpaceXY(D3W, D3H, i+10, "bag")
                ; 右键装备送进卡奈魔盒
                MouseMove, m[1], m[2]
                Click, Right
                ; 如果格子不在最后一行，并且下方有装备或者下方未探开
                if (i<=50 and (helperBagZone[i+10]=-1 or helperBagZone[i+10]=10))
                {
                    ; 当前装备可能是占用2个格子的大型装备，提前取出下方格子的中心像素
                    pLargeItem:=True
                    cd_before:=getPixelRGB(m2)
                }
                Sleep, helperDelay
                ; 点击添加材料按钮
                MouseMove, k[2][1], k[2][2]
                Click
                Sleep, helperDelay+50
                ; 点击转化按钮
                MouseMove, k[1][1], k[1][2]
                Click
                Sleep, helperDelay+50
                ; 清空魔盒
                MouseMove, k[4][1], k[4][2]
                Click
                Sleep, helperDelay+50
                MouseMove, k[3][1], k[3][2]
                Click
                Sleep, helperDelay+50
                if (pLargeItem)
                {
                    ; 当前装备可能是大型装备，检查下方格子中心像素有没有一起变色
                    cd_after:=getPixelRGB(m2)
                    if !isArraysEqual(cd_before, cd_after, 3)
                    {
                        ; 如果变色，即当前装备是大型装备，标记下方格子未非装备格
                        helperBagZone[i+10]:=5
                    }
                }
                i++
            Default:
                ; 跳过无装备，或者非装备格
                i++
        }
    }
    helperRunning:=False
    ; 鼠标回到原位置
    MouseMove, xpos, ypos
    Return
}

/*
负责一键赌博（连按右键）
参数：
    无
返回：
    无
*/
gambleHelper(){
    local
    Global helperDelay, helperBreak, helperRunning
    GuiControlGet, extraGambleHelperEdit
    Loop, %extraGambleHelperEdit%
    {
        if helperBreak{
            Break
        }
        Click, Right
        Sleep, helperDelay//4
    }
    helperRunning:=False
    Return
}

/*
负责一键拾取（连按左键）
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
    helperDelay：按键延迟
返回：
    无
*/
lootHelper(D3W, D3H, helperDelay){
    local
    Global helperBreak, helperRunning
    MouseGetPos, xpos, ypos
    ; 如果鼠标在人物周围，连点左键
    if (Abs(xpos - D3W/2)<600*1440/D3H and Abs(ypos - D3H/2)<500*1440/D3H)
    {
        GuiControlGet, extraLootHelperEdit
        Loop, %extraLootHelperEdit%
        {
            if helperBreak{
                Break
            }
            Click
            Sleep, helperDelay//2
        }
    }
    Else    ; 否则就点一次左键
    {
        Click
    }
    helperRunning:=False
    Return
}

/*
负责快速分解（左键+回车）
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
    helperDelay：按键延迟
返回：
    bool，是否检测到确认框并发送了回车
*/
quickSalvageHelper(D3W, D3H, helperDelay){
    Click
    StartTime:=A_TickCount
    confirmationTimeout:=helperDelay
    while (A_TickCount-StartTime<=confirmationTimeout)
    {
        if isDialogBoXOnScreen(D3W, D3H)
        {
            Send {Enter}
            Return True
        }
        Sleep, 20
    }
    Return False
}

/*
负责一键分解
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
    xpos：之前鼠标x坐标
    ypos：之前鼠标y坐标
返回：
    无
*/
oneButtonSalvageHelper(D3W, D3H, xpos, ypos){
    local
    static _spaceSizeInnerH:=63
    static _spaceSizeInnerW:=64
    Global helperBreak, helperRunning, helperDelay, helperBagZone, mouseDelay, cInventorySpace
    helperBagZone:=make1DArray(60, -1)
    ; 开启一单独线程查找空格子
    fn1:=Func("scanInventorySpaceGDIP").Bind(D3W, D3H)
    SetTimer, %fn1%, -1

    q:=0    ; 当前格子装备品质，2：普通传奇，3：远古传奇，4：神圣或无形装备，5：太古传奇
    i:=1    ; 当前格子ID
    w:=0
    SetDefaultMouseSpeed, mouseDelay
    GuiControlGet, extraSalvageHelperDropdown
    while (i<=60)
    {
        ; 防卡死
        w++
        if (helperBreak or w>200) {
            Break
        }
        ; 当前格子情况
        switch helperBagZone[i]
        {
            case -1:
                ; 当前格子还未探开
                Sleep, 20
            case 10:
                ; 当前格子有装备
                m:=getInventorySpaceXY(D3W, D3H, i, "bag")
                MouseMove, m[1], m[2]
                ; 智能分解判断
                if (extraSalvageHelperDropdown > 2)
                {
                    c_t:=[-255,-255,-255]
                    StartTime1:=A_TickCount
                    while (A_TickCount-StartTime1<=helperDelay)
                    {
                        ; 获取三个位于边框上的点颜色
                        c:=getPixelsRGB(Round(m[3]-1-10*D3H/1440), m[2], 3, 1, "Max", False)
                        if (c_t[1]=c[1] and c_t[2]=c[2] and c_t[3]=c[3]){
                            ; 当取色点颜色停止变化，动画显示完毕
                            Break
                        }
                        c_t:=c
                        Sleep, 20
                    }
                    if ((c[1]>=70 or c[3]<=20) and Max(Abs(c[1]-c[2]), Abs(c[1]-c[3]), Abs(c[3]-c[2]))>20 and (c[1]+c[2]+c[3]<410)) {
                        ; 装备是太古或者远古
                        q:=(c[2]<35) ? 5:3
                    } else if (c[3]>100 and c[3]>c[2] and c[2]>c[1]) {
                        ; 装备是神圣装备
                        q:=4
                    } else if (c[1]<50 and c[2]>c[3] and c[3]>c[1]) {
                        ; 装备是无形武器
                        q:=4
                    } else {
                        ; 装备是普通传奇
                        q:=2
                    }
                }
                ; 智能模式在跳过装备前必须识别双格物品，防止误点下半格。
                ; 普通一键分解在物品消失后直接检查上下格，省去悬停动画等待。
                if (extraSalvageHelperDropdown>2 and i<=50 and (helperBagZone[i+10]=10 or helperBagZone[i+10]=-1))
                {
                    ; 如果不是最后一行，且下方格子有装备，判断下方格子边缘的颜色是否改变
                    md:=getInventorySpaceXY(D3W, D3H, i+10, "bag")
                    c_b:=cInventorySpace[i+10]
                    c_t:=[-255,-255,-255]
                    StartTime1:=A_TickCount
                    while (A_TickCount-StartTime1<=helperDelay)
                    {
                        c_a:=getPixelRGB([Round(md[3]+_spaceSizeInnerW*0.08*D3H/1440), Round(md[4]+_spaceSizeInnerH*0.7*D3H/1440)])
                        if (c_t[1]=c_a[1] and c_t[2]=c_a[2] and c_t[3]=c_a[3]){
                            ; 当取色点颜色停止变化，动画显示完毕
                            Break
                        }
                        c_t:=c_a
                    }
                    if !(c_b[1]=c_a[1] and c_b[2]=c_a[2] and c_b[3]=c_a[3]){
                        ; 若改变，则当前格子装备为占用2个格子的大型装备，标记下方格子为非装备格子
                        helperBagZone[i+10]:=5
                    }
                }
                if (q>=extraSalvageHelperDropdown) {
                    ; 如果品质达标，跳过当前格子
                    i++
                    Continue
                }
                ; 开始分解
                Click
                StartTime1:=A_TickCount
                confirmed:=False
                ; 循环检测是否弹出确认对话框
                while (A_TickCount-StartTime1<=helperDelay)
                {
                    if isDialogBoXOnScreen(D3W, D3H)
                    {
                        Sleep, 10
                        Send {Enter}
                        confirmed:=True
                        Break
                    }
                }
                ; 有确认框的传奇需要等待确认生效；白蓝黄若未被批量按钮处理，
                ; 点击后会直接消失，也由同一段空格检测收尾。
                StartTime2:=A_TickCount
                salvageTimeout:=confirmed ? 2*helperDelay:helperDelay
                while (A_TickCount-StartTime2<=salvageTimeout)
                {
                    if isInventorySpaceEmpty(D3W, D3H, i, "", "bag")
                    {
                        if (i<=50 and (helperBagZone[i+10]=10 or helperBagZone[i+10]=-1) and isInventorySpaceEmpty(D3W, D3H, i+10, "", "bag"))
                        {
                            ; 双格装备分解后上下格会同时变空，跳过下半格。
                            helperBagZone[i+10]:=5
                        }
                        Break
                    }
                }
                i++
            Default:
            ; 当前格子是安全格或空格子
                i++
        }
    }
    helperRunning:=False
    ; 右键取消分解状态
    Click, Right
    ; 鼠标回到原位置
    MouseMove, xpos, ypos
    Return
}

/*
负责一键丢装备
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
    xpos：之前鼠标x坐标
    ypos：之前鼠标y坐标
    mousePosition：鼠标位置标记。1：背包栏，2：银行。
*/
oneButtonAbandonHelper(D3W, D3H, xpos, ypos, mousePosition){
    local
    Global helperBreak, helperRunning, helperDelay, helperBagZone, mouseDelay, forceStandingKey
    helperBagZone:=make1DArray(60, -1)
    ; 开启一单独线程查找空格子
    fn1:=Func("scanInventorySpaceGDIP").Bind(D3W, D3H)
    SetTimer, %fn1%, -1
    SetDefaultMouseSpeed, mouseDelay
    stashOpen:=-1
    while (i<=60)
    {
        ; 防卡死
        w++
        if (helperBreak or w>200) {
            Break
        }
        ; 当前格子情况
        switch helperBagZone[i]
        {
            case -1:
                ; 当前格子还未探开
                Sleep, 20
            case 10,20:
                ; 当前格子有装备或堆叽物品
                m:=getInventorySpaceXY(D3W, D3H, i, "bag")
                MouseMove, m[1], m[2]
                if (stashOpen=-1)
                {
                    Sleep, helperDelay//2
                    stashOpen:=isStashOpen(D3W, D3H)
                    if (stashOpen=0 and mousePosition!=1)
                    {
                        ; 如果银行未打开且鼠标不在背包栏内，则退出
                        Break
                    }
                }
                if (mousePosition=1)
                {
                    ; 开始丢弃
                    Click
                    Sleep, helperDelay//2
                    MouseMove, D3W//2, D3H//2
                    if GetKeyState(forceStandingKey)
                    {
                        Click
                    }
                    Else
                    {
                        Send {%forceStandingKey% down}
                        Click
                        Send {%forceStandingKey% up}
                    }
                }
                Else
                {
                    ; 存银行
                    Click, Right
                    Sleep, helperDelay//2
                }
                ; 循环检测下方格子的装备有没有消失
                if (i<=50 and (helperBagZone[i+10]=10 or helperBagZone[i+10]=-1))
                {
                    StartTime2:=A_TickCount
                    while (A_TickCount-StartTime2<=helperDelay)
                    {
                        if isInventorySpaceEmpty(D3W, D3H, i+10, "", "bag")
                        {
                            helperBagZone[i+10]:=5
                            Break
                        }
                    }
                }
                i++
            Default:
            ; 当前格子是安全格或空格子
                i++
        }
    }
    helperRunning:=False
    ; 鼠标回到原位置
    MouseMove, xpos, ypos
    Return
}

/*
负责自动喝药
参数：
    action: int，自动喝药策略
*/
potionHelper(action){
    local
    Global vPausing, potionKey, gameX, gameY, lastpotion, D3W, D3H
    static _x := 1822
    static _y := 1340
    static _w := 66
    if !vPausing
    {
        switch action
        {
            case 2:
                Send {%potionKey%}
            case 3:
                ; 卡CD喝药
                ; 对药水图标区域截图，并且和上次对比
                currentpotion:=getPixelsRGB(Round(D3W/2-(3440/2-1822)*D3H/1440), Round(_y*D3H/1440), Round(_w*D3H/1440), Round(_w*D3H/1440), "", True, gameX, gameY)
                ; 如果两次截图相同则药水已冷却，按下喝药按键
                if (lastpotion and isArraysEqual(lastpotion, currentpotion[1], 0)) {
                    Send {%potionKey%}
                }
                lastpotion:=currentpotion[1]
        }
    }
    Return
}

/*
扫描所有背包格子。未扫描-1，安全格0，没东西1，有装备10，有堆叠数量的物品20
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
返回：
    无
*/
scanInventorySpaceGDIP(D3W, D3H){
    local
    static _spaceSizeInnerW:=64
    static _spaceSizeInnerH:=63
    scale:=D3H/1440
    firstSpace:=getInventorySpaceXY(D3W, D3H, 1, "bag")
    lastSpace:=getInventorySpaceXY(D3W, D3H, 60, "bag")
    captureLeft:=firstSpace[3]
    captureTop:=firstSpace[4]
    captureWidth:=lastSpace[3]+Round(_spaceSizeInnerW*scale)-captureLeft
    captureHeight:=lastSpace[4]+Round(_spaceSizeInnerH*scale)-captureTop
    ; 只抓取背包区域，避免每次扫描复制整个游戏画面
    sxy:=getGameXYonScreen(0, 0)
    pInventoryBitmap:=Gdip_BitmapFromScreen(Format("{}|{}|{}|{}", sxy[1]+captureLeft, sxy[2]+captureTop, captureWidth, captureHeight))
    Gdip_LockBits(pInventoryBitmap, 0, 0, Gdip_GetImageWidth(pInventoryBitmap), Gdip_GetImageHeight(pInventoryBitmap), Stride, Scan0, BitmapData)
    static _e:=[[0.65625,0.71429], [0.375,0.36508], [0.725,0.251]]
    Global safezone, helperBagZone, cInventorySpace
    cInventorySpace:={}
    Loop, 60
    {
        m:=getInventorySpaceXY(D3W, D3H, A_Index, "bag")
        localPosition:=[m[1]-captureLeft, m[2]-captureTop, m[3]-captureLeft, m[4]-captureTop]
        ; 保存当前格子左下角的颜色信息
        cInventorySpace[A_Index]:=splitRGB(Gdip_GetLockBitPixel(Scan0, Round(localPosition[3]+_spaceSizeInnerW*0.08*scale), Round(localPosition[4]+_spaceSizeInnerH*0.7*scale), Stride))
        if safezone.HasKey(A_Index)
        {
            helperBagZone[A_Index]:=0
        }
        Else
        {
            if (helperBagZone[A_Index]!=-1){
                continue
            }
            r:=1
            for i, p in _e
            {
                xy:=[Round(localPosition[3]+_spaceSizeInnerW*_e[i][1]*scale), Round(localPosition[4]+_spaceSizeInnerH*_e[i][2]*scale)]
                c:=splitRGB(Gdip_GetLockBitPixel(Scan0, xy[1], xy[2], Stride))
                if !(c[1]<22 and c[2]<20 and c[3]<15 and c[1]>c[3] and c[2]>c[3])
                {
                    r:=10
                    Break
                }
            }
            if (r=10 and hasInventoryStackCount(Scan0, Stride, localPosition, D3H))
            {
                r:=20
            }
            helperBagZone[A_Index]:=r
        }
    }
    Gdip_UnlockBits(pInventoryBitmap, BitmapData)
    Gdip_DisposeImage(pInventoryBitmap)
    Return
}

/*
判断背包格子右下角是否显示堆叠数量。材料、宝石和大部分消耗品会显示数量，
装备右下角的品质星标带有明显色差，不满足中性高亮条件。
*/
hasInventoryStackCount(Scan0, Stride, position, D3H){
    local
    scale:=D3H/1440
    startX:=Round(position[3]+52*scale)
    endX:=Round(position[3]+62*scale)
    startY:=Round(position[4]+38*scale)
    endY:=Round(position[4]+53*scale)
    requiredPixels:=Max(2, Round(6*scale*scale))
    matchedPixels:=0

    Loop, % endX-startX+1
    {
        x:=startX+A_Index-1
        Loop, % endY-startY+1
        {
            y:=startY+A_Index-1
            c:=splitRGB(Gdip_GetLockBitPixel(Scan0, x, y, Stride))
            maxChannel:=Max(c[1], c[2], c[3])
            minChannel:=Min(c[1], c[2], c[3])
            if (minChannel>=120 and maxChannel-minChannel<=45)
            {
                matchedPixels++
                if (matchedPixels>=requiredPixels)
                {
                    Return True
                }
            }
        }
    }
    Return False
}

/*
负责快速暂停
参数：
    pausetime: int, 暂停的时间
    pauseAction：int，暂停的方式
返回：
    无
*/
clickPauseMarco(pausetime, pauseAction){
    local
    Global vRunning, forceStandingKey, keysOnHold, quickPauseHK
    if vRunning
    {
        Gosub, StopMarco
        if (pausetime>0)
        {
            ; 自动恢复
            SetTimer, RunMarco, off
            SetTimer, RunMarco, -%pausetime%
            ; 连点左键
            if (pauseAction=2)
            {
                startTime:=A_TickCount
                while (A_TickCount-startTime<pausetime)
                {
                    if GetKeyState(forceStandingKey)
                    {
                        Send {%forceStandingKey% up}
                        Click
                        Send {%forceStandingKey% down}
                    }
                    Else
                    {
                        Click
                    }
                    Sleep, 50
                }
            }
        }
        Else
        {
            ; 最多点1000次防卡死
            Loop, 1000
            {
                if (pauseAction=2)
                {
                    if GetKeyState(forceStandingKey)
                    {
                        Send {%forceStandingKey% up}
                        Click
                        Send {%forceStandingKey% down}
                    }
                    Else
                    {
                        Click
                    }
                }
                Sleep, 50
                if !GetKeyState(quickPauseHK, "P")
                {
                    Break
                }
            }
            SetTimer, RunMarco, -1
        }
    }
    Return
}

/*
设置宏启动模式的相关控件动画
参数：
    无
返回：
    无
*/
SetStartMode(){
    local
    Global currentProfile
    GuiControlGet, skillset%currentProfile%profilestartmodedropdown
    switch skillset%currentProfile%profilestartmodedropdown
    {
        case 2:
            GuiControl, , skillset%currentProfile%clickpauseckbox, 0
            GuiControl, Disable, skillset%currentProfile%clickpauseckbox
            GuiControl, Enable, skillset%currentProfile%useskillqueueckbox
            GuiControl, Enable, skillset%currentProfile%movingdropdown
            GuiControl, Enable, skillset%currentProfile%potiondropdown
        case 3:
            GuiControl, , skillset%currentProfile%useskillqueueckbox, 0
            GuiControl, Choose, skillset%currentProfile%movingdropdown, 1
            GuiControl, Choose, skillset%currentProfile%potiondropdown, 1
            GuiControl, , skillset%currentProfile%clickpauseckbox, 0
            GuiControl, Disable, skillset%currentProfile%useskillqueueckbox
            GuiControl, Disable, skillset%currentProfile%movingdropdown
            GuiControl, Disable, skillset%currentProfile%potiondropdown
            GuiControl, Disable, skillset%currentProfile%clickpauseckbox
            WinSet, Redraw,, A
        Default:
            GuiControl, Enable, skillset%currentProfile%useskillqueueckbox
            GuiControl, Enable, skillset%currentProfile%movingdropdown
            GuiControl, Enable, skillset%currentProfile%clickpauseckbox
    }
    Gosub, SetQuickPause
    Gosub, SetMovingHelper
    Return
}

/*
设置按键队列警告和提示消息
参数：
    无
返回：
    无
*/
SetSkillQueueWarning(){
    local
    Global currentProfile
    GuiControlGet, skillset%currentProfile%useskillqueueckbox
    if skillset%currentProfile%useskillqueueckbox
    {
        GuiControlGet, skillset%currentProfile%useskillqueueupdown
        _out:=1000/skillset%currentProfile%useskillqueueupdown
        _in:=0
        Loop, 6
        {
            GuiControlGet, skillset%currentProfile%s%A_Index%dropdown
            if (skillset%currentProfile%s%A_Index%dropdown==3)
            {
                GuiControlGet, skillset%currentProfile%s%A_Index%updown
                _in+=1000/skillset%currentProfile%s%A_Index%updown
            }
        }
        if (_in>_out)
        {
            GuiControl, Show, skillset%currentProfile%skillqueuewarningtext
            _s:=Format("当前按键配置每秒向队列中填入{:.2f}个“连点”技能，但却只取出{:.2f}个", _in, _out)
            GuiControlGet, _hwnd, Hwnd, skillset%currentProfile%skillqueuewarningtext
            AddToolTip(_hwnd, _s "`n你应当把buff类技能设置为“保持buff”而不是“连点”`n或者你需要增加”连点“的执行间隔，再或者减少按键队列的发送间隔", 30000, True)
        }
        Else
        {
            GuiControl, Hide, skillset%currentProfile%skillqueuewarningtext
        }
    }
    Else
    {
        GuiControl, Hide, skillset%currentProfile%skillqueuewarningtext
    }
    Return
}

/*
设置自定义强制站立按键相关的控件动画
参数：
    无
返回：
    无
*/
SetCustomStanding(){
    GuiControlGet, extraCustomStanding
    if extraCustomStanding
    {
        GuiControl, Enable, extraCustomStandingHK
        GuiControlGet, extraCustomStandingHK
        if !extraCustomStandingHK
        {
            GuiControl,, extraCustomStandingHK, LShift
        }
    }
    Else
    {
        GuiControl, Disable, extraCustomStandingHK
    }
    Return
}

/*
设置自定义强制移动按键相关的控件动画
参数：
    无
返回：
    无
*/
SetCustomMoving(){
    GuiControlGet, extraCustomMoving
    if extraCustomMoving
    {
        GuiControl, Enable, extraCustomMovingHK
        GuiControlGet, extraCustomMovingHK
        if !extraCustomMovingHK
        {
            GuiControl,, extraCustomMovingHK, e
        }
    }
    Else
    {
        GuiControl, Disable, extraCustomMovingHK
    }
    Return
}

/*
设置自定义药水按键相关的控件动画
参数：
    无
返回：
    无
*/
SetCustomPotion(){
    GuiControlGet, extraCustomPotion
    if extraCustomPotion
    {
        GuiControl, Enable, extraCustomPotionHK
        GuiControlGet, extraCustomPotionHK
        if !extraCustomPotionHK
        {
            GuiControl,, extraCustomPotionHK, q
        }
    }
    Else
    {
        GuiControl, Disable, extraCustomPotionHK
    }
    Return
}

/*
设置赌博助手相关的控件动画
参数：
    无
返回：
    无
*/
SetGambleHelper(){
    GuiControlGet, extraGambleHelperCKbox
    If extraGambleHelperCKbox
    {
        GuiControl, Enable, extraGambleHelperText
        GuiControl, Enable, extraGambleHelperEdit
    }
    Else
    {
        GuiControl, Disable, extraGambleHelperText
        GuiControl, Disable, extraGambleHelperEdit
    }
    Return
}

/*
设置拾取助手相关的控件动画
参数：
    无
返回：
    无
*/
SetLootHelper(){
    GuiControlGet, extraLootHelperCkbox
    If extraLootHelperCkbox
    {
        GuiControl, Enable, extraLootHelperText
        GuiControl, Enable, extraLootHelperEdit
    }
    Else
    {
        GuiControl, Disable, extraLootHelperText
        GuiControl, Disable, extraLootHelperEdit
    }
    Return
}


/*
设置重铸助手相关的控件动画
参数：
    无
返回：
    无
*/
SetReforgeHelper(){
    GuiControlGet, extraReforgeHelperCkbox
    If extraReforgeHelperCkbox
    {
        GuiControl, Enable, extraReforgeHelperDropdown
    }
    Else
    {
        GuiControl, Disable, extraReforgeHelperDropdown
    }
    Return
}


/*
设置分解助手相关的控件动画
参数：
    无
返回：
    无
*/
SetSalvageHelper(){
    local
    Global safezone
    Gui, Submit, NoHide
    GuiControlGet, extraSalvageHelperCkbox
    GuiControlGet, extraSalvageHelperHK
    GuiControlGet, extraSalvageHelperDropdown
    GuiControlGet, extraUpgradeHelperCkbox
    GuiControlGet, extraConvertHelperCkbox
    GuiControlGet, extraAbandonHelperCkbox
    If extraSalvageHelperCkbox or extraUpgradeHelperCkbox or extraConvertHelperCkbox or extraAbandonHelperCkbox
    {
        ; 如果启用了任意一键宏，检查安全区域设置
        hasSafeZone:=False
        Loop, 60
        {
            if safezone.HasKey(A_Index)
            {
                hasSafeZone:=True
                Break
            }
        }
        if hasSafeZone
        {
            GuiControl, +c348017, helperSafeZoneText
            GuiControl,, helperSafeZoneText, 安全格已设置
        }
        Else
        {
            GuiControl, +cFF0000, helperSafeZoneText
            GuiControl,, helperSafeZoneText, 安全格未设置
        }

        GuiControl, Enable, extraSalvageHelperDropdown
        switch extraSalvageHelperDropdown
        {
            case 1:
                if extraUpgradeHelperCkbox or extraConvertHelperCkbox or extraAbandonHelperCkbox
                {
                    GuiControl, show, helperSafeZoneText
                }
                Else
                {
                    GuiControl, hide, helperSafeZoneText
                }
            case 2,3,4,5:
                GuiControl, show, helperSafeZoneText
        }
    }
    Else
    {
        if not extraSalvageHelperCkbox
        {
            GuiControl, Disable, extraSalvageHelperDropdown
        }
        GuiControl, Hide, helperSafeZoneText
    }
    Return
}


/*
设置技能队列相关的控件动画
参数：
    无
返回：
    无
*/
SetSkillQueue(){
    local
    Global tabslen
    Loop, %tabslen%
    {
        GuiControlGet, skillset%A_Index%useskillqueueckbox
        if skillset%A_Index%useskillqueueckbox
        {
            GuiControl, Enable, skillset%A_Index%useskillqueueedit
        }
        Else
        {
            GuiControl, Disable, skillset%A_Index%useskillqueueedit
        }
    }
    SetSkillQueueWarning()
    Return
}

/*
设置发送技能队列按键
参数：
    inv：int，技能队列延迟
返回：
    无
*/
spamSkillQueue(inv){
    local
    Global skillQueue, forceStandingKey, keysOnHold
    while (skillQueue.Count() > 0)
    {
        ; 取出排在第一的按键
        _k:=skillQueue.RemoveAt(1)
        k:=_k[1]
        ; 如果是连点，按键前后停止一段时间，并且放开所有按住不放的按键
        if (_k[2]=3){
            for key, value in keysOnHold{
                if GetKeyState(key){
                    Send {%key% up}
                }
            }
            Sleep, inv//4
        }

        if (!GetKeyState(forceStandingKey) and (_k[2]=3 or k="LButton")){
            Send {Blind}{%forceStandingKey% down}{%k% down}
            if (_k[2]=3){
                Sleep, inv//4
            }
            Send {Blind}{%k% up}{%forceStandingKey% up}
        }
        Else{
            Send {%k%}
        }

        if (_k[2]=3){
            Sleep, inv//4
            ; 恢复之前所有应该被按下的按键
            for key, value in keysOnHold{
                if !GetKeyState(key){
                    Send {%key% down}
                }
            }
            Break
        }
    }
    Return
}

/*
判断屏幕上是否有对话框
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
返回：
    bool
*/
isDialogBoXOnScreen(D3W, D3H){
    ; 2点取色判断
    point1:=[D3W/2-(3440/2-1655)*D3H/1440, 500*D3H/1440]
    point2:=[D3W/2+(3440/2-1800)*D3H/1440, 500*D3H/1440]
    c1:=getPixelRGB(point1)
    c2:=getPixelRGB(point2)
    if (c1[1]>c1[2] and c1[2]>c1[3] and c1[3]<5 and c1[2]<15 and c1[1]>25 and c2[1]>c2[2] and c2[2]>c2[3] and c2[3]<5 and c2[2]<15 and c2[1]>25)
    {
        Return True
    }
    Else
    {
        Return False
    }
}

/*
获取背包格子的坐标
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
    ID：int，格子的编号
    zone: string, 基于背包区域或者卡纳魔盒
返回：
    [格子中心x，格子中心y，格子左上角x，格子左上角y]
*/
getInventorySpaceXY(D3W, D3H, ID, zone){
    static _spaceSizeInnerW:=64
    static _spaceSizeInnerH:=63
    static _spaceSizeW:=67
    static _spaceSizeH:=66
    static _spaceBagX:=[2753,2820,2887,2954,3021,3089,3156,3223,3290,3357]
    static _spaceBagY:=[747,813,880,946,1013,1079]
    static _spaceKanaiX:=[242, 318, 394]
    static _spaceKanaiY:=[503, 579, 655]

    switch zone
    {
        case "bag":
            targetColumn:=(Mod(ID,10)=0)?10:Mod(ID,10)
            targetRow:=Floor((ID-1)/10)+1
            Return [Round(D3W-((3440-_spaceBagX[targetColumn]-_spaceSizeInnerW/2)*D3H/1440)), Round((_spaceBagY[targetRow]+_spaceSizeInnerH/2)*D3H/1440)
            , Round(D3W-((3440-_spaceBagX[targetColumn])*D3H/1440)), Round((_spaceBagY[targetRow])*D3H/1440)]
        case "kanai":
            targetColumn:=(Mod(ID,3)=0)?3:Mod(ID,3)
            targetRow:=Floor((ID-1)/3)+1
            Return [Round((_spaceKanaiX[targetColumn]+_spaceSizeInnerW/2)*D3H/1440), Round((_spaceKanaiY[targetRow]+_spaceSizeInnerH/2)*D3H/1440)
            , Round(_spaceKanaiX[targetColumn]*D3H/1440), Round((_spaceKanaiY[targetRow])*D3H/1440)]
    }
}

/*
判断铁匠/分解页面是否开启
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
返回：
    [0]：如果没有开启
    [1]: 如果铁匠页面开启但拆解页面没开启
    [2, 大拆解按钮边缘坐标rgb, 白色解按钮边缘坐标rgb, 蓝色解按钮边缘坐标rgb, 黄色解按钮边缘坐标rgb]：如果铁匠开启且同时在拆解页面
*/
isSalvagePageOpen(D3W, D3H){
    c1:=getPixelRGB([Round(339*D3H/1440),Round(80*D3H/1440)])
    c2:=getPixelRGB([Round(351*D3H/1440),Round(107*D3H/1440)])
    c3:=getPixelRGB([Round(388*D3H/1440),Round(86*D3H/1440)])
    c4:=getPixelRGB([Round(673*D3H/1440),Round(1040*D3H/1440)])
    p:=getSalvageIconXY(D3W, D3H, "edge")
    cLeg:=getPixelRGB(p[1])
    cWhite:=getPixelRGB(p[2])
    cBlue:=getPixelRGB(p[3])
    cRare:=getPixelRGB(p[4])
    headerVisible:=(c1[3]>c1[2] and c1[2]>c1[1] and c1[3]>170 and c1[3]-c1[1]>80 and c3[3]>c3[2] and c3[2]>c3[1] and c3[3]>110 and c2[1]+c2[2]>350)
    blacksmithFrameVisible:=(c4[1]>50 and c4[2]<15 and c4[3]<15)
    salvageButtonsVisible:=(cBlue[3]>cBlue[2] and cBlue[2]>cBlue[1] and cRare[3]<20 and cRare[1]>cRare[2] and cRare[2]>cRare[3])
    if (blacksmithFrameVisible and salvageButtonsVisible)
        Return [2, cLeg, cWhite, cBlue, cRare]
    if (blacksmithFrameVisible and headerVisible)
        Return [1]
    Return [0]
}

/*
判断卡奈魔盒页面是否开启
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
返回：
    0：卡奈魔盒没有开启
    1：卡奈魔盒开启但页面未知
    2：卡奈魔盒开启，且开启了重铸界面
    3：卡奈魔盒开启，且开启了升级界面
    4：卡奈魔盒开启，且开启了材料转化界面
*/
isKanaiCubeOpen(D3W, D3H){
    c1:=getPixelRGB([Round(353*D3H/1440),Round(85*D3H/1440)])
    c2:=getPixelRGB([Round(278*D3H/1440),Round(147*D3H/1440)])
    c3:=getPixelRGB([Round(330*D3H/1440),Round(140*D3H/1440)])

    if (c1[1]<50 and c1[2]<40 and c1[3]<35 and c2[1]>100 and c2[2]<30 and c2[3]<30 and abs(c3[3]-c3[2])<=8 and c3[1]<=55 and c3[1]<c3[2] and c3[1]<c3[3]){
        cc1:=getPixelRGB([Round(788*D3H/1440),Round(428*D3H/1440)])
        cc2:=getPixelRGB([Round(810*D3H/1440),Round(429*D3H/1440)])
        if (cc1[3]>230 and cc2[3]>230 and cc1[3]>cc1[2] and cc2[3]>cc2[2] and cc1[2]>cc1[1] and cc2[2]>cc2[1])
        {
            Return 2
        }
        else
        {
            ; 检测是否是非英文客户端，设置Y轴位置偏移
            WinGetTitle, gameWindowTitle, ahk_class D3 Main Window Class
            upgradeYOffset:=(gameWindowTitle="Diablo III")? 0:-22
            cc1:=getPixelRGB([Round(799*D3H/1440),Round((406+upgradeYOffset)*D3H/1440)])
            cc2:=getPixelRGB([Round(795*D3H/1440),Round((592+upgradeYOffset)*D3H/1440)])
            if (cc1[1]+cc1[2]+cc1[3]>550 and cc1[1]>cc1[3] and cc2[1]+cc2[2]>400 and cc2[1]>cc2[3])
            {
                Return 3
            }

            convertYOffset:=(gameWindowTitle="Diablo III")? 0:-43
            cc3:=getPixelRGB([Round(799*D3H/1440),Round((365+convertYOffset)*D3H/1440)])
            if (cc3[1]+cc3[2]+cc3[3]>600 and cc3[1]>cc3[2] and cc3[2]>cc3[3] and cc3[3]>110 and cc3[3]<200)
            {
                Return 4
            }
        }
        Return 1
    }
    Else {
        Return 0
    }
}

/*
获得拆解页面4个按钮的坐标
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
    c: string，“center”-中心坐标，“edge”-边缘颜色带内坐标
返回：
    [大拆解按钮坐标xy，白色解按钮坐标xy，蓝色解按钮坐标xy，黄色解按钮坐标xy]
*/
getSalvageIconXY(D3W, D3H, c){
    switch c
    {
        case "center":
            centerLeg:=[Round(221*D3H/1440),Round(388*D3H/1440)]
            centerWhite:=[Round(335*D3H/1440),Round(388*D3H/1440)]
            centerBlue:=[Round(424*D3H/1440),Round(388*D3H/1440)]
            centerRare:=[Round(514*D3H/1440),Round(388*D3H/1440)]
            Return [centerLeg, centerWhite, centerBlue, centerRare]
        case "edge":
            edgeColorLeg:=[Round(203*D3H/1440),Round(337*D3H/1440)]
            edgeColorWhite:=[Round(335*D3H/1440),Round(371*D3H/1440)]
            edgeColorBlue:=[Round(424*D3H/1440),Round(371*D3H/1440)]
            edgeColorRare:=[Round(514*D3H/1440),Round(371*D3H/1440)]
            Return [edgeColorLeg, edgeColorWhite, edgeColorBlue, edgeColorRare]
    }
}

/*
判断赌博页面是否开启
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
返回：
    Bool
*/
isGambleOpen(D3W, D3H){
    c1:=getPixelRGB([Round(320*D3H/1440),Round(96*D3H/1440)])
    c2:=getPixelRGB([Round(351*D3H/1440),Round(100*D3H/1440)])
    c4:=getPixelRGB([Round(194*D3H/1440),Round(67*D3H/1440)])
    c5:=getPixelRGB([Round(147*D3H/1440),Round(94*D3H/1440)])
    if (c1[3]>c1[1] and c1[1]>c1[2] and c1[3]>130 and c2[1]+c2[2]>330 and c4[1]+c4[2]+c4[3]+c5[1]+c5[2]+c5[3]<10){
        Return True
    }
    Else{
        Return False
    }
}

/*
判断物品栏页面是否开启
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
返回：
    Bool
*/
isInventoryOpen(D3W, D3H){
    c1:=getPixelRGB([Round(D3W - (3440-3086)*D3H/1440),Round(108*D3H/1440)])
    c2:=getPixelRGB([Round(D3W - (3440-3010)*D3H/1440),Round(147*D3H/1440)])
    c3:=getPixelRGB([Round(D3W - (3440-3425)*D3H/1440),Round(142*D3H/1440)])
    c4:=getPixelRGB([Round(D3W - (3440-3117)*D3H/1440),Round(84*D3H/1440)])
    if (c1[1]+c1[2]>240 and c2[1]>115 and c2[2]<30 and c2[3]<30 and abs(c3[1]-c3[2])<=10 and c3[3]<40 and c4[3]>c4[2]+60 and c4[2]>c4[1]){
        Return True
    }
    Else
    {
        Return False
    }
}

/*
判断储物箱页面是否开启
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
返回：
    Bool
*/
isStashOpen(D3W, D3H){
    c1:=getPixelRGB([Round(282*D3H/1440),Round(147*D3H/1440)])
    c2:=getPixelRGB([Round(382*D3H/1440),Round(77*D3H/1440)])
    c3:=getPixelRGB([Round(299*D3H/1440),Round(82*D3H/1440)])
    if (c1[1]>100 and c1[1]>c1[2]+80 and abs(c1[2]-c1[3])<10 and c2[2]>c2[3] and c2[3]>c2[1] and c2[2]-c2[1]>80 and c3[1]>c3[2] and c3[2]>c3[3] and c3[3]<40){
        Return 1
    }
    Else
    {
        Return 0
    }
}

/*
判断格子是否为空
参数：
    D3W：int，窗口区域的宽度
    D3H：int，窗口区域的高度
    ID：int，格子编号
    ckpoints：object，要检查的位置的xy百分比list
    zone：string，基于背包区域或者卡奈魔盒
返回：
    Bool
*/
isInventorySpaceEmpty(D3W, D3H, ID, ckpoints, zone){
    static _spaceSizeInnerW:=64
    static _spaceSizeInnerH:=63
    Global gameX, gameY
    m:=getInventorySpaceXY(D3W, D3H, ID, zone)
    if (ckpoints="")
    {
        c:=getPixelsRGB(Round(m[3]+0.2*_spaceSizeInnerW), Round(m[4]+0.2*_spaceSizeInnerH), Round(0.6*_spaceSizeInnerW), Round(0.6*_spaceSizeInnerH), "Max", True, gameX, gameY)
        if (c[1]>50 or c[2]>50 or c[3]>50)
        {
            Return False
        }
    }
    Else
    {
        for i, p in ckpoints
        {
            xy:=[Round(m[3]+_spaceSizeInnerW*ckpoints[i][1]*D3H/1440), Round(m[4]+_spaceSizeInnerH*ckpoints[i][2]*D3H/1440)]
            c:=getPixelRGB(xy)
            if !(c[1]<22 and c[2]<20 and c[3]<15 and c[1]>c[3] and c[2]>c[3])
            {
                Return False
            }
        }
    }
    Return True
}

/*
把游戏内画面坐标转化为屏幕坐标
参数：
    GameX：X坐标
    GameY：Y坐标
返回：
    如果成功，返回对应的屏幕坐标
*/
getGameXYonScreen(GameX, GameY){
    VarSetCapacity(POINT, 8)
    NumPut(GameX, POINT, 0, "Int")
    NumPut(GameY, POINT, 4, "Int")
    DllCall("ClientToScreen", "ptr", WinExist("ahk_class D3 Main Window Class"), "ptr", &POINT)
    Return [NumGet(POINT, 0, "Int"), NumGet(POINT, 4, "Int")]
}

/*
获取游戏的当前分辨率
参数：
    ByRef D3W：分辨率宽
    ByRef D3H：分辨率高
返回：
    获取分辨率是否成功
*/
getGameResulution(ByRef D3W, ByRef D3H){
    local
    Global gameResolution, d3only
    if (gameResolution="Auto")
    {
        VarSetCapacity(rect, 16)
        DllCall("GetClientRect", "ptr", WinExist("ahk_class D3 Main Window Class"), "ptr", &rect)
        D3W:=NumGet(rect, 8, "Int")
        D3H:=NumGet(rect, 12, "Int")
        if (D3W*D3H=0 and d3only){
            MsgBox, % Format("无法获取到你的游戏分辨率，错误代码：0x{:X}，请尝试切换至窗口模式运行游戏。", A_LastError)
            Return False
        }
    }
    Else
    {
        _r:=StrSplit(gameResolution, "x", A_Space)
        D3W:=_r[1]
        D3H:=_r[2]
    }
    Return True
}

/*
获取卡奈和放入材料按钮位置
参数：
    D3W：分辨率宽
    D3H：分辨率高
返回：
    [转化按钮xy，放入材料按钮xy，上一页xy，下一页xy]
*/
getKanaiCubeButtonPos(D3W, D3H){
    point1:=[Round(320*D3H/1440),Round(1105*D3H/1440)]
    point2:=[Round(955*D3H/1440),Round(1115*D3H/1440)]
    point3:=[Round(777*D3H/1440),Round(1117*D3H/1440)]
    point4:=[Round(1135*D3H/1440),Round(1117*D3H/1440)]
    Return [point1, point2, point3, point4]
}

/*
获取指定像素点的RGB值
参数：
    point：点坐标
返回：
    [R，G，B]
*/
getPixelRGB(point){
    PixelGetColor, cpixel, point[1], point[2], rgb
    Return splitRGB(cpixel)
}


/*
获取多个像素点聚合后的RGB值
参数：
    pointX, pointY：起始点坐标
    w：宽度
    h：高度
    agg_func：用于聚合的函数名字
    gdip：是否用GDI+库获取像素颜色
    gameX，gameY：游戏窗口0，0点对应的屏幕坐标
返回：
    [R，G，B]
*/
getPixelsRGB(pointX, pointY, w, h, agg_func="", gdip=False, gameX=0, gameY=0){
    cpixelR:=[]
    cpixelG:=[]
    cpixelB:=[]
    if gdip
    {
        pBitmap:=Gdip_BitmapFromScreen(Format("{}|{}|{}|{}", pointX+gameX, pointY+gameY, w, h))
        Gdip_LockBits(pBitmap, 0, 0, Gdip_GetImageWidth(pBitmap), Gdip_GetImageHeight(pBitmap), Stride, Scan0, BitmapData)
        Loop, %w%
        {
            _x:=A_Index-1
            Loop, %h%
            {
                _y:=A_Index-1
                t:=splitRGB(Gdip_GetLockBitPixel(Scan0, _x, _y, Stride))
                cpixelR.Push(t[1])
                cpixelG.Push(t[2])
                cpixelB.Push(t[3])
            }
        }
        Gdip_UnlockBits(pBitmap, BitmapData)
        Gdip_DisposeImage(pBitmap)
    }
    Else
    {
        Loop, %w%
        {
            _x:=A_Index-1
            Loop, %h%
            {
                _y:=A_Index-1
                t:=getPixelRGB([_x+pointX, _y+pointY])
                cpixelR.Push(t[1])
                cpixelG.Push(t[2])
                cpixelB.Push(t[3])
            }
        }
    }
    if not agg_func {
        Return [cpixelR, cpixelG, cpixelB]
    }
    Else {
        Return [Func(agg_func).Call(cpixelR*), Func(agg_func).Call(cpixelG*), Func(agg_func).Call(cpixelB*)]
    }
}

/*
转化Object的所有key为字符串
参数：
    sep：分隔符
    dict：输入的字典
返回：
    String
*/
keyJoin(sep, dict){
    for key,value in dict
        str .= key . sep
    return SubStr(str, 1, -StrLen(sep))
}

/*
检查数组中是否有指定数值
参数：
    haystack：要检查的数组
    needle：要检查的数值
返回：
    0：找不到
    index：找到
*/
HasVal(haystack, needle) {
    for index, value in haystack
        if (value = needle)
            return index
    if !(IsObject(haystack))
        throw Exception("Bad haystack!", -1, haystack)
    return 0
}

/*
快速创建一个一维数组
参数：
    len：数组大小
    fill：填入数值，默认为0
返回：
    一维数组
*/
make1DArray(len, fill=0){
    outArray:=[]
    Loop, %len%
    {
        outArray.Push(fill)
    }
    Return outArray
}

/*
检查两个数组是否相等
参数：
    arrayA, arrayB：要检查的两个数组
    _t：允许的误差范围，默认为0
返回：
    一维数组
*/
isArraysEqual(arrayA, arrayB, _t=0){
    if (arrayA.Length()!=arrayB.Length())
    {
        Return False
    }
    _l:=arrayA.Length()
    Loop, %_l%
    {
        if (abs(arrayA[A_Index]-arrayb[A_Index])>_t)
        {
            Return False
        }
    }
    Return True
}

/*
一个空方程，用于绑定Text控件的gLabel从而使tooltip可以工作
参数：
    无
返回：
    无
*/
dummyFunction(){
    Return
}

/*
为picture控件填充颜色
参数：
    HWNDs：控件的句柄
    HexColor：要填充的颜色
返回：
    无
*/
FillPixel(HWNDs, HexColor) {
    hBitmap := DllCall("CreateBitmap", "Int", 1, "Int", 1, "UInt", 1, "UInt", 32, "PtrP", HexColor, "Ptr")
    hBM := DllCall("CopyImage", "Ptr", hBitmap, "UInt", 0, "Int", 0, "Int", 0, "UInt", 0x2000|0x8|0x4, "Ptr")
    if IsObject(HWNDs)
    {
        for i, HWND in HWNDs
        {
            SendMessage, 0x172,, hBM,, ahk_id %HWND%
        }
    }
    Else
    {
        SendMessage, 0x172,, hBM,, ahk_id %HWNDs%
    }
    DllCall("DeleteObject", "Ptr", hBitmap)
    Return
}

/*
从B64字符串创建位图或图标
参数：
    B64：图片字符串
    IsIcon：是否创建图标而不是位图，默认为否
返回：
    位图或者图标的句柄
*/
GdipCreateFromBase64(B64, IsIcon := 0){
    VarSetCapacity(B64Len, 0)
    DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", 0, "UInt", 0x01, "Ptr", 0, "UIntP", B64Len, "Ptr", 0, "Ptr", 0)
    VarSetCapacity(B64Dec, B64Len, 0) ; pbBinary size
    DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", 0, "UInt", 0x01, "Ptr", &B64Dec, "UIntP", B64Len, "Ptr", 0, "Ptr", 0)
    pStream := DllCall("Shlwapi.dll\SHCreateMemStream", "Ptr", &B64Dec, "UInt", B64Len, "UPtr")
    VarSetCapacity(pBitmap, 0)
    DllCall("Gdiplus.dll\GdipCreateBitmapFromStreamICM", "Ptr", pStream, "PtrP", pBitmap)
    VarSetCapacity(hBitmap, 0)
    DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", "UInt", pBitmap, "UInt*", hBitmap, "Int", 0x00FFFFFF)

    If (IsIcon) {
        DllCall("Gdiplus.dll\GdipCreateHICONFromBitmap", "Ptr", pBitmap, "PtrP", hIcon, "UInt", 0)
    }

    ObjRelease(pStream)
    return (IsIcon ? hIcon : hBitmap)
}

/*
为控件添加tooltip
修改自：https://gist.github.com/andreberg/55d003569f0564cd8695
参数：
    con：控件的hwnd
    text：tooltip字符串
    duration: tooltip的持续时间
    Modify：为1则修改一个已创建的tooltip
返回：
    无
*/
AddToolTip(con, text, duration=30000, Modify=0){
    Static TThwnd, GuiHwnd
    PtrSize := (A_PtrSize ? A_PtrSize : 4)
    WM_USER := 0x400
    TTM_ADDTOOL := (A_IsUnicode ? WM_USER+50 : WM_USER+4)
    TTM_UPDATETIPTEXT := (A_IsUnicode ? WM_USER+57 : WM_USER+12)
    TTM_SETMAXTIPWIDTH := WM_USER+24
    TTM_SETDELAYTIME := WM_USER+3
    TTF_IDISHWND := 1
    TTF_CENTERTIP := 2
    TTF_RTLREADING := 4
    TTF_SUBCLASS := 16
    TTF_TRACK := 0x0020
    TTF_ABSOLUTE := 0x0080
    TTF_TRANSPARENT := 0x0100
    TTF_PARSELINKS := 0x1000
    TTF_AUTOPOP := 2
    If (!TThwnd) {
        Gui, +LastFound
        GuiHwnd := WinExist()
        TThwnd := DllCall("CreateWindowEx"
                    ,"UInt",0
                    ,"Str","tooltips_class32"
                    ,"UInt",0
                    ,"UInt",2147483648
                    ,"UInt",-2147483648
                    ,"UInt",-2147483648
                    ,"UInt",-2147483648
                    ,"UInt",-2147483648
                    ,"UInt",GuiHwnd
                    ,"UInt",0
                    ,"UInt",0
                    ,"UInt",0)
    }
    cbSize := 6*4+6*PtrSize
    uFlags := TTF_IDISHWND|TTF_SUBCLASS|TTF_PARSELINKS
    VarSetCapacity(TInfo, cbSize, 0)
    NumPut(cbSize, TInfo)
    NumPut(uFlags, TInfo, 4)
    NumPut(GuiHwnd, TInfo, 8)
    NumPut(con, TInfo, 8+PtrSize)
    NumPut(&text, TInfo, 6*4+3*PtrSize)
    NumPut(0,TInfo, 6*4+6*PtrSize)
    DetectHiddenWindows, On
    If (!Modify) {
        SendMessage, %TTM_ADDTOOL%,, &TInfo,, ahk_id %TThwnd%
        SendMessage, %TTM_SETMAXTIPWIDTH%,, A_ScreenWidth,, ahk_id %TThwnd%
        SendMessage, %TTM_SETDELAYTIME%, TTF_AUTOPOP, duration,, ahk_id %TThwnd%
    }
    SendMessage, %TTM_UPDATETIPTEXT%,, &TInfo,, ahk_id %TThwnd%
    Return
}

/* ObjectSort() by bichlepa
* 
* Description:
*    Reads content of an object and returns a sorted array
* 
* Parameters:
*    obj:              Object which will be sorted
*    keyName:          [optional] 
*                      Omit it if you want to sort a array of strings, numbers etc.
*                      If you have an array of objects, specify here the key by which contents the object will be sorted.
*    callBackFunction: [optional] Use it if you want to have custom sort rules.
*                      The function will be called once for each value. It must return a number or string.
*    reverse:          [optional] Pass true if the result array should be reversed
*/
objectSort(obj, keyName="", callbackFunc="", reverse=false)
{
    temp := Object()
    sorted := Object() ;Return value
    
    for oneKey, oneValue in obj
    {
        ;Get the value by which it will be sorted
        if keyname
            value := oneValue[keyName]
        else
            value := oneValue
        
        ;If there is a callback function, call it. The value is the key of the temporary list.
        if (callbackFunc)
            tempKey := %callbackFunc%(value)
        else
            tempKey := value
        
        ;Insert the value in the temporary object.
        ;It may happen that some values are equal therefore we put the values in an array.
        if not isObject(temp[tempKey])
            temp[tempKey] := []
        temp[tempKey].push(oneValue)
    }
    
    ;Now loop throuth the temporary list. AutoHotkey sorts them for us.
    for oneTempKey, oneValueList in temp
    {
        for oneValueIndex, oneValue in oneValueList
        {
            ;And add the values to the result list
            if (reverse)
                sorted.insertAt(1,oneValue)
            else
                sorted.push(oneValue)
        }
    }
    
    return sorted
}

/*
windows钩子callback函数，监控当前窗口，处理标题栏颜色
修改自：https://www.autohotkey.com/boards/viewtopic.php?t=32532
参数：
    windows callback
返回：
    无
*/
Watchdog(wParam, lParam){
    Global
    If (wParam = 32772 or wParam = 4)     ; HSHELL_WINDOWCREATED 1, HSHELL_WINDOWACTIVATED 4, HSHELL_RUDEAPPACTIVATED 32772
    {
        helperBreak:=True
        if (lParam=0)
        {
            ; 当前窗口激活
            vFront:=True
            FillPixel(TitlebarID, 0x34495e)
            FillPixel([TitlebarLineID, BorderTopID, BorderBottomID, BorderLeftID, BorderRightID], 0x000000)
            Gui, Font, s11 +cFFFFFF Normal
            GuiControl, Font, TitleBarText
            GuiControl,, TitleBarText, % TITLE
            GuiControl,, % UIRightButtonID, % "HBITMAP:*" hBMPButtonClose_Normal
            GuiControl,, % UILeftButtonID, % "HBITMAP:*" hBMPButtonLeft_Normal
            if (hHookMouse){
                DllCall("UnhookWindowsHookEx", "Uint", hHookMouse)
            }
            hHookMouse:=DllCall("SetWindowsHookEx", "int", 14, "Ptr", RegisterCallback("MouseMove", "Fast"), "Ptr", DllCall("GetModuleHandle", "Ptr", 0 ,"Ptr"), "Uint", 0, "Ptr")
        }
        Else
        {
            ; 当前窗口没有激活
            if (hHookMouse){
                DllCall("UnhookWindowsHookEx", "Uint", hHookMouse)
                hHookMouse:=0
            }
            if (vFront)
            {
                FillPixel([TitlebarID, TitlebarLineID], 0x607e9d)
                FillPixel([BorderTopID, BorderBottomID, BorderLeftID, BorderRightID], 0x607e9d)
                GuiControl, +cEEEEEE, TitleBarText
                GuiControl,, TitleBarText, % TITLE
                vFront:=False
            }
            WinGetClass, AClass, ahk_id %lParam%
            ; 检查当前窗口是否是暗黑三
            if (vRunning and d3only and AClass != "D3 Main Window Class")
            {
                Gosub, StopMarco
            }
        }
    }
    Return
}

/*
鼠标钩子callback
参数：
    https://docs.microsoft.com/en-us/previous-versions/windows/desktop/legacy/ms644986(v=vs.85)
返回：
    https://docs.microsoft.com/en-us/previous-versions/windows/desktop/legacy/ms644986(v=vs.85)
*/
MouseMove(nCode, wParam, lParam)
{
    Global
    If (nCode=0)
    {
        MouseGetPos, , , , currentControlUnderMouse, 2
        switch wParam
        {
            case 0x200:
                ; 鼠标移动事件
                switch currentControlUnderMouse
                {
                    case UIRightButtonID:
                        if (RightButtonState!=1)
                        {
                            GuiControl,, % UIRightButtonID, % "HBITMAP:*" hBMPButtonClose_Hover
                            RightButtonState:=1
                        }
                        if (LeftButtonState!=0)
                        {
                            GuiControl,, % UILeftButtonID, % "HBITMAP:*" hBMPButtonLeft_Normal
                            LeftButtonState:=0
                        }
                    case UILeftButtonID:
                        if (LeftButtonState!=1)
                        {
                            GuiControl,, % UILeftButtonID, % "HBITMAP:*" hBMPButtonLeft_Hover
                            LeftButtonState:=1
                        }
                        if (RightButtonState!=0)
                        {
                            GuiControl,, % UIRightButtonID, % "HBITMAP:*" hBMPButtonClose_Normal
                            RightButtonState:=0
                        }
                    Default:
                        if (RightButtonState!=0)
                        {
                            GuiControl,, % UIRightButtonID, % "HBITMAP:*" hBMPButtonClose_Normal
                            RightButtonState:=0
                        }
                        if (LeftButtonState!=0)
                        {
                            GuiControl,, % UILeftButtonID, % "HBITMAP:*" hBMPButtonLeft_Normal
                            LeftButtonState:=0
                        }
                        if (currentControlUnderMouse=TitleBarID or currentControlUnderMouse=TitleBarTextID)
                        {
                            ; 如果鼠标位于标题栏
                            PostMessage, 0xA1, 2,,, A ; 发送拖拽事件
                        }
                }
            case 0x201,0x204:
                ; 左键，右键按下
                if (currentControlUnderMouse=UIRightButtonID)
                {
                    GuiControl,, % UIRightButtonID, % "HBITMAP:*" hBMPButtonClose_Pressed
                    RightButtonState:=2
                }
                if (currentControlUnderMouse=UILeftButtonID)
                {
                    GuiControl,, % UILeftButtonID, % "HBITMAP:*" hBMPButtonLeft_Pressed
                    LeftButtonState:=2
                }
            case 0x202,0x205:
                ; 左键，右键弹起
                switch currentControlUnderMouse
                {
                    case UIRightButtonID:
                        if (wParam=0x202)
                        {
                            GuiClose()
                        }
                        Else
                        {
                            ; 必须使用SetTimer函数另起一“线程”退出程序，直接在Hook Callback函数内退出会引起钩子链断裂，鼠标失去响应。
                            SetTimer, GuiExit, -1
                        }
                    case UILeftButtonID:
                        showMainWindow(isCompact? MainWindowW:CompactWindowW, MainWindowH)
                        isCompact:=!isCompact
                        hBMPButtonLeft_Normal := isCompact? hBMPButtonExpand_Normal:hBMPButtonBack_Normal
                        hBMPButtonLeft_Hover := isCompact? hBMPButtonExpand_Hover:hBMPButtonBack_Hover
                        hBMPButtonLeft_Pressed := isCompact? hBMPButtonExpand_Pressed:hBMPButtonBack_Pressed
                        if (LeftButtonState!=1)
                        {
                            GuiControl,, % UILeftButtonID, % "HBITMAP:*" hBMPButtonLeft_Hover
                            LeftButtonState:=1
                        }
                    Default:
                        if (RightButtonState!=0)
                        {
                            GuiControl,, % UIRightButtonID, % "HBITMAP:*" hBMPButtonClose_Normal
                            RightButtonState:=0
                        }
                        if (LeftButtonState!=0)
                        {
                            GuiControl,, % UILeftButtonID, % "HBITMAP:*" hBMPButtonLeft_Normal
                            LeftButtonState:=0
                        }
                }
        }
    }
    Return DllCall("CallNextHookEx", "Ptr", 0, "int", nCode, "Uint", wParam, "Ptr", lParam)
}

/*
以指定大小显示主窗口
参数：
    windowSizeW：主窗口宽
    windowSizeH：主窗口高
    _redraw：是否重绘整个窗体
返回：
    无
*/
showMainWindow(windowSizeW, windowSizeH){
    global
    Gui Show, w%windowSizeW% h%windowSizeH%
    GuiControl, Move, TitleBar, % "w" windowSizeW-2
    GuiControl, Move, UIRightButton, % "x" windowSizeW-30-1
    GuiControl, Move, TitleBarText, % "x" (windowSizeW-TitleBarSizeW)/2
    GuiControl, Move, BorderTop, % "w" windowSizeW
    GuiControl, Move, BorderBottom, % "y" windowSizeH-1 " w" windowSizeW
    GuiControl, Move, BorderLeft, % "h" windowSizeH-2
    GuiControl, Move, BorderRight, % "x" windowSizeW-1 " h" windowSizeH-2
    WinSet, Redraw,, A
    Return
}
; =====================================Subroutines===================================
ShowAbout:
    ShowAboutWindow()
Return

CloseAbout:
4GuiClose:
4GuiEscape:
    Gui, 4:Destroy
Return

ShowAppSettings:
    ShowAppSettingsWindow()
Return

SaveNow:
    Gui, 1:Submit, NoHide
    SaveCfgFile(SETTINGS_FILE, profileFiles, currentProfile, safezone, CONFIG_SCHEMA_VERSION)
    GuiControl, 1:, SaveButton, 已保存
    SetTimer, ResetSaveButton, -1200
Return

ResetSaveButton:
    GuiControl, 1:, SaveButton, 保存
Return

SaveAppSettings:
    if ApplyAppSettings()
    {
        GuiControl, 2:, SettingsFeedback, 设置已应用并保存
        GuiControl, 1:, SaveButton, 已保存
        SetTimer, ResetSaveButton, -1200
    }
Return

OpenProfileDirectory:
    FileCreateDir, %PROFILE_DIRECTORY%
    Run, %PROFILE_DIRECTORY%
Return

AddProfile:
    Gui, 2:+OwnDialogs
    defaultNewProfileName:="配置" (tabslen+1)
    InputBox, newProfileName, 新增 Profile, 请输入新 Profile 名称：,,,,,,,, %defaultNewProfileName%
    if ErrorLevel
        Return
    newProfileName:=Trim(newProfileName)
    if !IsValidProfileName(newProfileName)
    {
        MsgBox, 48, 名称无效, Profile 名称包含Windows文件名不允许使用的字符。
        Return
    }
    newProfileFile:=newProfileName ".ini"
    if FileExist(PROFILE_DIRECTORY "\" newProfileFile)
    {
        MsgBox, 48, 名称重复, 已存在同名 Profile。
        Return
    }
    Gui, 1:Submit, NoHide
    SaveCfgFile(SETTINGS_FILE, profileFiles, currentProfile, safezone, CONFIG_SCHEMA_VERSION)
    CreateDefaultProfileFile(PROFILE_DIRECTORY "\" newProfileFile)
    IniWrite, %newProfileFile%, %SETTINGS_FILE%, General, activatedprofile
    Reload
Return

RenameProfile:
    Gui, 2:Submit, NoHide
    profileIndex:=settingsProfileSelection
    oldProfileName:=tabsarray[profileIndex]
    Gui, 2:+OwnDialogs
    InputBox, newProfileName, 重命名 Profile, 请输入新的 Profile 名称：,,,,,,,, %oldProfileName%
    if ErrorLevel
        Return
    newProfileName:=Trim(newProfileName)
    if !IsValidProfileName(newProfileName)
    {
        MsgBox, 48, 名称无效, Profile 名称包含Windows文件名不允许使用的字符。
        Return
    }
    oldProfileFile:=profileFiles[profileIndex]
    newProfileFile:=newProfileName ".ini"
    if (newProfileFile=oldProfileFile)
        Return
    if FileExist(PROFILE_DIRECTORY "\" newProfileFile)
    {
        MsgBox, 48, 名称重复, 已存在同名 Profile。
        Return
    }
    Gui, 1:Submit, NoHide
    SaveCfgFile(SETTINGS_FILE, profileFiles, currentProfile, safezone, CONFIG_SCHEMA_VERSION)
    FileMove, % PROFILE_DIRECTORY "\" oldProfileFile, % PROFILE_DIRECTORY "\" newProfileFile
    if ErrorLevel
    {
        MsgBox, 16, 重命名失败, 无法重命名Profile文件。
        Return
    }
    activatedProfileFile:=(currentProfile=profileIndex) ? newProfileFile : profileFiles[currentProfile]
    IniWrite, %activatedProfileFile%, %SETTINGS_FILE%, General, activatedprofile
    Reload
Return

DeleteProfile:
    Gui, 2:Submit, NoHide
    if (tabslen<=1)
    {
        MsgBox, 48, 无法删除, 至少需要保留一个 Profile。
        Return
    }
    profileIndex:=settingsProfileSelection
    profileName:=tabsarray[profileIndex]
    Gui, 2:+OwnDialogs
    MsgBox, 49, 删除 Profile, % "确定删除“" profileName "”吗？此操作会删除对应的独立配置文件。"
    IfMsgBox, Cancel
        Return
    Gui, 1:Submit, NoHide
    SaveCfgFile(SETTINGS_FILE, profileFiles, currentProfile, safezone, CONFIG_SCHEMA_VERSION)
    FileDelete, % PROFILE_DIRECTORY "\" profileFiles[profileIndex]
    if ErrorLevel
    {
        MsgBox, 16, 删除失败, 无法删除Profile文件。
        Return
    }
    profileFiles.RemoveAt(profileIndex)
    if (currentProfile=profileIndex)
        currentProfile:=Min(profileIndex, profileFiles.Count())
    Else if (currentProfile>profileIndex)
        currentProfile-=1
    IniWrite, % profileFiles[currentProfile], %SETTINGS_FILE%, General, activatedprofile
    Reload
Return

ShowSkillAdvanced:
    Gui, 2:Submit, NoHide
    ShowSkillAdvancedWindow(settingsProfileSelection)
Return

SaveSkillAdvanced:
    Gui, 3:Submit, NoHide
    Loop, 6
    {
        triggerButton:=Trim(skillAdvanced%A_Index%Trigger)
        if (triggerButton="")
            triggerButton:="LButton"
        combats[advancedProfileIndex][A_Index]["priority"]:=skillAdvanced%A_Index%Priority
        combats[advancedProfileIndex][A_Index]["repeat"]:=skillAdvanced%A_Index%Repeat
        combats[advancedProfileIndex][A_Index]["repeatinterval"]:=skillAdvanced%A_Index%RepeatInterval
        combats[advancedProfileIndex][A_Index]["triggerbutton"]:=triggerButton
    }
    Gui, 1:Submit, NoHide
    SaveCfgFile(SETTINGS_FILE, profileFiles, currentProfile, safezone, CONFIG_SCHEMA_VERSION)
    Gui, 3:Destroy
    GuiControl, 2:, SettingsFeedback, 高级技能设置已保存
Return

CloseSkillAdvanced:
3GuiClose:
3GuiEscape:
    Gui, 3:Destroy
Return

CloseAppSettings:
2GuiClose:
2GuiEscape:
    Gui, 2:Destroy
Return

spamSkillKeyA1:
spamSkillKeyA2:
spamSkillKeyA3:
spamSkillKeyA4:
spamSkillKeyA5:
spamSkillKeyA6:
spamSkillKey1:
spamSkillKey2:
spamSkillKey3:
spamSkillKey4:
spamSkillKey5:
spamSkillKey6:
    if !vPausing
    {
        nkey:=SubStr(A_ThisLabel, 0, 1)
        skillKey(currentProfile, nkey, D3W, D3H, forceStandingKey, skillset%currentProfile%useskillqueueckbox)
    }
Return

; 将currentProfile值关联到当前激活的tab
SetTabFocus:
    Gui, Submit, NoHide
    GuiControl, , StatuesSkillsetText, % tabsarray[ActiveTab]
    currentProfile:=ActiveTab
    SetStartMode()
Return

; 设置快速暂停相关的快捷键和控件动画
SetQuickPause:
    Gui, Submit, NoHide
    GuiControlGet, skillset%currentProfile%clickpauseckbox
    GuiControlGet, skillset%currentProfile%clickpausedropdown2
    GuiControlGet, skillset%currentProfile%clickpausedropdown1
    mousePauseKeyArray:=["LButton", "RButton", "MButton", "XButton1", "XButton2"]
    currentQuickPauseHK:=mousePauseKeyArray[skillset%currentProfile%clickpausedropdown2]
    if skillset%currentProfile%clickpauseckbox
    {
        GuiControl, Enable, skillset%currentProfile%clickpausedropdown1
        GuiControl, Enable, skillset%currentProfile%clickpausedropdown2
        GuiControl, Enable, skillset%currentProfile%clickpausedropdown3
        GuiControl, Enable, skillset%currentProfile%clickpausetext1
        if (skillset%currentProfile%clickpausedropdown1!=3)
        {
            GuiControl, Enable, skillset%currentProfile%clickpauseedit
            GuiControl, Enable, skillset%currentProfile%clickpausetext2
        }
        Else
        {
            GuiControl, Disable, skillset%currentProfile%clickpauseedit
            GuiControl, Disable, skillset%currentProfile%clickpausetext2
        }
        Try {
            Hotkey, ~*%quickPauseHK%, quickPause, off
        } 
        Hotkey, ~*%currentQuickPauseHK%, quickPause, on
        quickPauseHK:=currentQuickPauseHK
    }
    Else
    {
        GuiControl, Disable, skillset%currentProfile%clickpausedropdown1
        GuiControl, Disable, skillset%currentProfile%clickpausedropdown2
        GuiControl, Disable, skillset%currentProfile%clickpausedropdown3
        GuiControl, Disable, skillset%currentProfile%clickpausetext1
        GuiControl, Disable, skillset%currentProfile%clickpauseedit
        GuiControl, Disable, skillset%currentProfile%clickpausetext2
        Hotkey, ~*%currentQuickPauseHK%, quickPause, off
        quickPauseHK:=""
    }
Return

; 设置助手宏相关的控件动画
SetHelperKeybinding:
    Gui, Submit, NoHide
    mouseKeyArray:=["", "MButton", "WheelUp", "WheelDown", "XButton1", "XButton2", ""]
    GuiControlGet, HelperKeybindingdropdown
    GuiControlGet, HelperKeybindingHK
    Try
    {
        Hotkey, ~*%utilityHelperHK%, UtilityHelper, off
    }
    switch HelperKeybindingdropdown
    {
        case 1:
            GuiControl, Disable, HelperKeybindingHK
            newUtilityHelperHK:=""
        case 2,3,4,5,6:
            GuiControl, Disable, HelperKeybindingHK
            newUtilityHelperHK:=mouseKeyArray[HelperKeybindingdropdown]
        case 7:
            GuiControl, Enable, HelperKeybindingHK
            newUtilityHelperHK:=HelperKeybindingHK
    }
    Try
    {
        Hotkey, ~*%utilityHelperHK%, UtilityHelper, off
        Hotkey, ~*%newUtilityHelperHK%, UtilityHelper, on
        utilityHelperHK:=newUtilityHelperHK
    }
Return

; 设置配置的快速切换功能，以及相关控件动画
SetProfileKeybinding:
    Gui, Submit, NoHide
    mouseKeyArray:=["", "MButton", "WheelUp", "WheelDown", "XButton1", "XButton2", ""]
    Loop, %tabslen%
    {
        currentPage:=A_Index
        for key, value in profileKeybinding.Clone()
        {
            if (value = currentPage)
            {
                Hotkey, ~*%key%, SwitchProfile, Off
                profileKeybinding.Delete(key)
            }
        }
        switch skillset%currentPage%profilekeybindingdropdown
        {
            case 1:
                GuiControl, Disable, skillset%currentPage%profilekeybindinghkbox
                GuiControl, Disable, skillset%currentPage%autostartmarcockbox
            case 2,3,4,5,6:
                GuiControl, Disable, skillset%currentPage%profilekeybindinghkbox
                GuiControl, Enable, skillset%currentPage%autostartmarcockbox
                ckey:=mouseKeyArray[skillset%currentPage%profilekeybindingdropdown]
                Hotkey, ~*%ckey%, SwitchProfile, on
                profileKeybinding[ckey]:=currentPage
            case 7:
                GuiControl, Enable, skillset%currentPage%profilekeybindinghkbox
                GuiControl, Enable, skillset%currentPage%autostartmarcockbox
                ckey:=skillset%currentPage%profilekeybindinghkbox
                if (ckey!="")
                {
                    Hotkey, ~*%ckey%, SwitchProfile, on
                    profileKeybinding[ckey]:=currentPage
                } 
        }
    }
Return

; 处理配置快速切换逻辑
SwitchProfile:
    ;移除快捷键的modifier 
    currentHK:=RegExReplace(A_ThisHotkey, "[~*]")
    if (currentProfile!=profileKeybinding[currentHK])
    {
        wasRunning:=vRunning
        wasPausing:=vPausing
        currentProfile:=profileKeybinding[currentHK]
        GuiControl , Choose, ActiveTab, % tabsarray[currentProfile]
        Gosub, SetTabFocus
        Gosub, StopMarco
        GuiControlGet, extraSoundonProfileSwitch
        if extraSoundonProfileSwitch
        {
            SoundBeep, 750, 250
        }
        if (wasRunning and !wasPausing and skillset%currentProfile%autostartmarcockbox and skillset%currentProfile%profilestartmodedropdown=1)
        {
            Gosub, RunMarco
        }
    }
Return

; 设置开启战斗宏快捷键和相关控件动画
SetStartRun:
    Gui, Submit, NoHide
    startRunMouseKeyArray:=["RButton", "MButton", "WheelUp", "WheelDown", "XButton1", "XButton2", ""]
    if (StartRunDropdown = 7)
    {
        GuiControl, Enable, StartRunHKinput
        newstartRunHK:=StartRunHKinput
        Loop, %tabslen%
        {
            GuiControl, Enable, skillset%A_Index%s6dropdown
        }
    }
    Else
    {
        if (StartRunDropdown = 1)
        {
            Loop, %tabslen%
            {
                GuiControl, choose, skillset%A_Index%s6dropdown, 1
                GuiControl, Disable, skillset%A_Index%s6dropdown
                GuiControl, Disable, skillset%A_Index%s6edit
                GuiControl, Disable, skillset%A_Index%s6delayedit
            }
        }
        Else
        {
            Loop, %tabslen%
            {
                GuiControl, Enable, skillset%A_Index%s6dropdown
            }
        }
        GuiControl, Disable, StartRunHKinput
        newstartRunHK:=startRunMouseKeyArray[StartRunDropdown]
    }
    Try
    {
        Hotkey, ~*%startRunHK%, MainMacro, off
        Hotkey, ~*%newstartRunHK%, MainMacro, on
        startRunHK:=newstartRunHK
    }
Return

; 设置强制移动. 自动喝药相关控件动画
SetMovingHelper:
    Gui, Submit, NoHide
    Loop, %tabslen%
    {
        if (skillset%currentProfile%movingdropdown = 4)
        {
            GuiControl, Enable, skillset%A_Index%movingtext
            GuiControl, Enable, skillset%A_Index%movingedit
        }
        Else
        { 
            GuiControl, Disable, skillset%A_Index%movingtext
            GuiControl, Disable, skillset%A_Index%movingedit
        }
        if (skillset%currentProfile%potiondropdown > 1)
        {
            GuiControl, Enable, skillset%A_Index%potiontext
            GuiControl, Enable, skillset%A_Index%potionedit
        }
        Else
        { 
            GuiControl, Disable, skillset%A_Index%potiontext
            GuiControl, Disable, skillset%A_Index%potionedit
        }
    }
Return

; 设置按键宏策略控件动画
SetSkillsetDropdown:
    Gui, Submit, NoHide
    Loop, %tabslen%
    {
        npage:=A_Index
        Loop, 6
        {
            switch skillset%npage%s%A_Index%dropdown
            {
                case 1,2:
                    GuiControl, Disable, skillset%npage%s%A_Index%edit
                    GuiControl, Disable, skillset%npage%s%A_Index%delayedit
                    GuiControl, Disable, skillset%npage%s%A_Index%randomckbox
                case 3:
                    GuiControl, Enable, skillset%npage%s%A_Index%edit
                    GuiControl, Enable, skillset%npage%s%A_Index%delayedit
                    GuiControl, Enable, skillset%npage%s%A_Index%randomckbox
                case 4:
                    GuiControl, Enable, skillset%npage%s%A_Index%edit
                    GuiControl, Disable, skillset%npage%s%A_Index%delayedit
                    GuiControl, Disable, skillset%npage%s%A_Index%randomckbox
                case 5:
                    GuiControl, Disable, skillset%npage%s%A_Index%edit
                    GuiControl, Enable, skillset%npage%s%A_Index%delayedit
                    GuiControl, Enable, skillset%npage%s%A_Index%randomckbox
            }
        }
    }
    SetSkillQueueWarning()
Return

; 处理战斗宏的执行逻辑
MainMacro:
    GuiControlGet, skillset%currentProfile%profilestartmodedropdown
    switch skillset%currentProfile%profilestartmodedropdown
    {
        ; 懒人模式
        case 1:
            if !vRunning
            {
                Gosub, RunMarco
            }
            Else
            {
                Gosub, StopMarco
            } 
        case 2:
        ; 仅按下时
            Gosub, RunMarco
            KeyWait, %startRunHK%
            Gosub, StopMarco
        case 3:
        ; 仅按一次
            Loop, 6
            {
                GuiControlGet, skillset%currentProfile%s%A_Index%dropdown
                GuiControlGet, skillset%currentProfile%s%A_Index%hotkey
                Switch skillset%currentProfile%s%A_Index%dropdown
                {
                    Case 2:
                        k:=skillset%currentProfile%s%A_Index%hotkey
                        Send {%k%}
                }
            }
    }
Return

; 开启战斗宏
RunMarco:
    Gui, Submit, NoHide
    GuiControlGet, extraCustomStanding
    GuiControlGet, extraCustomStandingHK
    forceStandingKey:=extraCustomStanding? extraCustomStandingHK:"LShift"
    GuiControlGet, extraCustomMoving
    GuiControlGet, extraCustomMovingHK
    forceMovingKey:=extraCustomMoving? extraCustomMovingHK:"e"
    potionKey:=extraCustomPotion? extraCustomPotionHK:"q"
    skillQueue:=[]
    syncTimer:={}
    syncDelay:={}
    if (!getGameResulution(D3W, D3H) and d3only)
    {
        Return
    }
    gameXY:=getGameXYonScreen(0,0)
    gameX:=gameXY[1]
    gameY:=gameXY[2]
    keyDelay:=[]
    Loop, 6
    {
        GuiControlGet, skillset%currentProfile%s%A_Index%dropdown
        GuiControlGet, skillset%currentProfile%s%A_Index%delayupdown
        GuiControlGet, skillset%currentProfile%s%A_Index%updown
        keyDelay.Push({"key":A_Index, "delay":(skillset%currentProfile%s%A_Index%dropdown=3)?mod(skillset%currentProfile%s%A_Index%updown + skillset%currentProfile%s%A_Index%delayupdown, skillset%currentProfile%s%A_Index%updown):0})
    }
    ; 按照延迟排序技能按键
    keyDelay:=ObjectSort(keyDelay, "delay", ,True)
    ; 处理技能按键
    vRunning:=True
    for _, v in keyDelay
    {
        currentIndex:=v["key"]
        GuiControlGet, skillset%currentProfile%s%currentIndex%hotkey
        Switch skillset%currentProfile%s%currentIndex%dropdown
        {
            Case 2:
                k:=skillset%currentProfile%s%currentIndex%hotkey
                Send {%k% Down}
                keysOnHold[k]:=1
            Case 3, 4:
                if runOnStart{
                    SetTimer, spamSkillKeyA%currentIndex%, -1
                }
                GuiControlGet, skillset%currentProfile%s%currentIndex%updown
                SetTimer, spamSkillKey%currentIndex%, % skillset%currentProfile%s%currentIndex%updown
            case 5:
                k:=combats[currentProfile][currentIndex]["triggerbutton"]
                HotKey, ~*%k%, spamSkillKey%currentIndex%, on
            Default:
                SetTimer, spamSkillKey%currentIndex%, off
        }
        if (currentIndex <=4)
        {
            GuiControl, Disable, skillset%currentProfile%s%currentIndex%hotkey
        }
    }
    ; 处理位移按键
    GuiControlGet, skillset%currentProfile%movingdropdown
    Switch skillset%currentProfile%movingdropdown
    {
        case 2:
            Send {%extraCustomStandingHK% Down}
            keysOnHold[extraCustomStandingHK]:=1
        case 3:
            Send {%extraCustomMovingHK% Down}
            keysOnHold[extraCustomMovingHK]:=1
        case 4:
            if runOnStart{
                Send {%extraCustomMovingHK%}
            }
            GuiControlGet, skillset%currentProfile%movingedit
            SetTimer, forceMoving, % skillset%currentProfile%movingedit

    }
    ; 处理自动喝药
    GuiControlGet, skillset%currentProfile%potiondropdown
    if (skillset%currentProfile%potiondropdown > 1)
    {
        if IsObject(pofunc){
            SetTimer, %pofunc%, off
        }
        GuiControlGet, skillset%currentProfile%potionedit
        pofunc:=Func("potionHelper").Bind(skillset%currentProfile%potiondropdown)
        SetTimer, %pofunc%, % skillset%currentProfile%potionupdown
    }
    ; 处理按键队列
    if skillset%currentProfile%useskillqueueckbox{
        GuiControlGet, skillset%currentProfile%useskillqueueupdown
        sqfunc:=Func("spamSkillQueue").Bind(skillset%currentProfile%useskillqueueupdown)
        if runOnStart{
            SetTimer, %sqfunc%, -1
        }
        SetTimer, %sqfunc%, % skillset%currentProfile%useskillqueueupdown
    } 
    vPausing:=False
Return

; 停止战斗宏
StopMarco:
    if IsObject(sqfunc){
        SetTimer, %sqfunc%, off
    }
    if IsObject(pofunc){
        SetTimer, %pofunc%, off
    }
    skillQueue:=[]
    Loop, 6
    {
        SetTimer, spamSkillKey%A_Index%, off
        k:=combats[currentProfile][A_Index]["triggerbutton"]
        HotKey, ~*%k%, spamSkillKey%A_Index%, off
        if (A_Index <=4)
        {
            si:=A_Index
            Loop, %tabslen%
            {
                GuiControl, Enable, skillset%A_Index%s%si%hotkey
            }
        }
    }
    SetTimer, forceMoving, off
    for key, value in keysOnHold{
        if GetKeyState(key){
            Send {%key% up}
        }
    }
    keysOnHold:={}
    vRunning:=False
    vPausing:=False
Return

; 处理快速暂停按键
quickPause:
    GuiControlGet, skillset%currentProfile%clickpausedropdown1
    GuiControlGet, skillset%currentProfile%clickpausedropdown3
    GuiControlGet, skillset%currentProfile%clickpauseupdown
    switch skillset%currentProfile%clickpausedropdown1
    {
        case 1:
            ; 双击
            If (A_PriorHotkey=A_ThisHotkey and A_TimeSincePriorHotkey < DblClickTime)
            {
                clickPauseMarco(skillset%currentProfile%clickpauseupdown, skillset%currentProfile%clickpausedropdown3)
            }
        case 2:
            clickPauseMarco(skillset%currentProfile%clickpauseupdown, skillset%currentProfile%clickpausedropdown3)
        case 3:
            clickPauseMarco(-1, skillset%currentProfile%clickpausedropdown3)
    }
Return

; 发送强制移动按键
forceMoving:
    if !vPausing
    {
        Send {%forceMovingKey%}
    }
Return
; ========================================= Hotkeys =======================================
~*Enter::
~*T::
~*M::
    if extraSmartPause
    {
        Gosub, StopMarco
    }
Return

~*Tab::
    if extraSmartPause
    {
        vPausing:=!vPausing
        if vPausing
        {
            for key, value in keysOnHold{
                if GetKeyState(key){
                    Send {%key% up}
                }
            }
        }
        Else
        {
            for key, value in keysOnHold{
                if !GetKeyState(key){
                    Send {%key% down}
                }
            }
        }
    }
Return

; 重映射小键盘按键，防止按住shift时无效的问题
NumpadIns::Numpad0
NumpadEnd::Numpad1
NumpadDown::Numpad2
NumpadPgDn::Numpad3
NumpadLeft::Numpad4
NumpadClear::Numpad5
NumpadRight::Numpad6
NumpadHome::Numpad7
NumpadUp::Numpad8
NumpadPgUp::Numpad9
NumpadDel::NumpadDot
; ===================================== System Functions ==================================
GuiClose(){
    Global
    Gui, Submit
    SaveCfgFile(SETTINGS_FILE, profileFiles, currentProfile, safezone, CONFIG_SCHEMA_VERSION)
    vFront:=False
    Return
}

GuiShowMainWindow(){
    Global
    Gui, Show,, %TIELE%
    Return
}


GuiExit(){
    Global
    Gui, Submit
    SaveCfgFile(SETTINGS_FILE, profileFiles, currentProfile, safezone, CONFIG_SCHEMA_VERSION)
    ExitApp
}


; =================================GDIP库文件===============================
; https://github.com/mmikeww/AHKv2-Gdip
; 为了保持单一文件所以把需要的函数搬了过来
; =========================================================================
Gdip_BitmapFromScreen(Screen:=0, Raster:="")
{
    hhdc := 0
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    if (Screen = 0)
    {
        _x := DllCall( "GetSystemMetrics", "Int", 76 )
        _y := DllCall( "GetSystemMetrics", "Int", 77 )
        _w := DllCall( "GetSystemMetrics", "Int", 78 )
        _h := DllCall( "GetSystemMetrics", "Int", 79 )
    }
    else if (SubStr(Screen, 1, 5) = "hwnd:")
    {
        Screen := SubStr(Screen, 6)
        if !WinExist("ahk_id " Screen)
            return -2
        WinGetRect(Screen,,, _w, _h)
        _x := _y := 0
        hhdc := GetDCEx(Screen, 3)
    }
    else if IsInteger(Screen)
    {
        M := GetMonitorInfo(Screen)
        _x := M.Left, _y := M.Top, _w := M.Right-M.Left, _h := M.Bottom-M.Top
    }
    else
    {
        S := StrSplit(Screen, "|")
        _x := S[1], _y := S[2], _w := S[3], _h := S[4]
    }

    if (_x = "") || (_y = "") || (_w = "") || (_h = "")
        return -1

    chdc := CreateCompatibleDC(), hbm := CreateDIBSection(_w, _h, chdc), obm := SelectObject(chdc, hbm), hhdc := hhdc ? hhdc : GetDC()
    BitBlt(chdc, 0, 0, _w, _h, hhdc, _x, _y, Raster)
    ReleaseDC(hhdc)

    pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
    SelectObject(chdc, obm), DeleteObject(hbm), DeleteDC(hhdc), DeleteDC(chdc)
    return pBitmap
}

Gdip_LockBits(pBitmap, x, y, w, h, ByRef Stride, ByRef Scan0, ByRef BitmapData, LockMode := 3, PixelFormat := 0x26200a)
{
    Ptr := A_PtrSize ? "UPtr" : "UInt"

    CreateRect(_Rect, x, y, w, h)
    VarSetCapacity(BitmapData, 16+2*(A_PtrSize ? A_PtrSize : 4), 0)
    _E := DllCall("Gdiplus\GdipBitmapLockBits", Ptr, pBitmap, Ptr, &_Rect, "uint", LockMode, "int", PixelFormat, Ptr, &BitmapData)
    Stride := NumGet(BitmapData, 8, "Int")
    Scan0 := NumGet(BitmapData, 16, Ptr)
    return _E
}

Gdip_GetLockBitPixel(Scan0, x, y, Stride)
{
    return NumGet(Scan0+0, (x*4)+(y*Stride), "UInt")
}

Gdip_UnlockBits(pBitmap, ByRef BitmapData)
{
    Ptr := A_PtrSize ? "UPtr" : "UInt"

    return DllCall("Gdiplus\GdipBitmapUnlockBits", Ptr, pBitmap, Ptr, &BitmapData)
}

Gdip_DisposeImage(pBitmap)
{
    return DllCall("gdiplus\GdipDisposeImage", A_PtrSize ? "UPtr" : "UInt", pBitmap)
}

Gdip_GetImageWidth(pBitmap)
{
    Width := 0
    DllCall("gdiplus\GdipGetImageWidth", A_PtrSize ? "UPtr" : "UInt", pBitmap, "uint*", Width)
    return Width
}

Gdip_GetImageHeight(pBitmap)
{
    Height := 0
    DllCall("gdiplus\GdipGetImageHeight", A_PtrSize ? "UPtr" : "UInt", pBitmap, "uint*", Height)
    return Height
}

CreateCompatibleDC(hdc:=0)
{
    return DllCall("CreateCompatibleDC", A_PtrSize ? "UPtr" : "UInt", hdc)
}

CreateDIBSection(w, h, hdc:="", bpp:=32, ByRef ppvBits:=0)
{
    Ptr := A_PtrSize ? "UPtr" : "UInt"

    hdc2 := hdc ? hdc : GetDC()
    VarSetCapacity(bi, 40, 0)

    NumPut(w, bi, 4, "uint")
    , NumPut(h, bi, 8, "uint")
    , NumPut(40, bi, 0, "uint")
    , NumPut(1, bi, 12, "ushort")
    , NumPut(0, bi, 16, "uInt")
    , NumPut(bpp, bi, 14, "ushort")

    hbm := DllCall("CreateDIBSection"
                    , Ptr, hdc2
                    , Ptr, &bi
                    , "uint", 0
                    , A_PtrSize ? "UPtr*" : "uint*", ppvBits
                    , Ptr, 0
                    , "uint", 0, Ptr)

    if !hdc
        ReleaseDC(hdc2)
    return hbm
}

SelectObject(hdc, hgdiobj)
{
    Ptr := A_PtrSize ? "UPtr" : "UInt"

    return DllCall("SelectObject", Ptr, hdc, Ptr, hgdiobj)
}

GetDC(hwnd:=0)
{
    return DllCall("GetDC", A_PtrSize ? "UPtr" : "UInt", hwnd)
}

BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, Raster:="")
{
    Ptr := A_PtrSize ? "UPtr" : "UInt"

    return DllCall("gdi32\BitBlt"
                    , Ptr, dDC
                    , "int", dx
                    , "int", dy
                    , "int", dw
                    , "int", dh
                    , Ptr, sDC
                    , "int", sx
                    , "int", sy
                    , "uint", Raster ? Raster : 0x00CC0020)
}

ReleaseDC(hdc, hwnd:=0)
{
    Ptr := A_PtrSize ? "UPtr" : "UInt"

    return DllCall("ReleaseDC", Ptr, hwnd, Ptr, hdc)
}

Gdip_CreateBitmapFromHBITMAP(hBitmap, Palette:=0)
{
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    pBitmap := 0

    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", Ptr, hBitmap, Ptr, Palette, A_PtrSize ? "UPtr*" : "uint*", pBitmap)
    return pBitmap
}

DeleteObject(hObject)
{
    return DllCall("DeleteObject", A_PtrSize ? "UPtr" : "UInt", hObject)
}

DeleteDC(hdc)
{
    return DllCall("DeleteDC", A_PtrSize ? "UPtr" : "UInt", hdc)
}

WinGetRect( hwnd, ByRef x:="", ByRef y:="", ByRef w:="", ByRef h:="" ) {
    Ptr := A_PtrSize ? "UPtr" : "UInt"
    CreateRect(winRect, 0, 0, 0, 0) ;is 16 on both 32 and 64
    ;VarSetCapacity( winRect, 16, 0 )	; Alternative of above two lines
    DllCall( "GetWindowRect", Ptr, hwnd, Ptr, &winRect )
    x := NumGet(winRect,  0, "UInt")
    y := NumGet(winRect,  4, "UInt")
    w := NumGet(winRect,  8, "UInt") - x
    h := NumGet(winRect, 12, "UInt") - y
}

GetDCEx(hwnd, flags:=0, hrgnClip:=0)
{
    Ptr := A_PtrSize ? "UPtr" : "UInt"

    return DllCall("GetDCEx", Ptr, hwnd, Ptr, hrgnClip, "int", flags)
}

IsInteger(Var) {
    Static Integer := "Integer"
    If Var Is Integer
        Return True
    Return False
}

GetMonitorInfo(MonitorNum)
{
    Monitors := MDMF_Enum()
    for k,v in Monitors
        if (v.Num = MonitorNum)
            return v
}

CreateRect(ByRef Rect, x, y, w, h)
{
    VarSetCapacity(Rect, 16)
    NumPut(x, Rect, 0, "uint"), NumPut(y, Rect, 4, "uint"), NumPut(w, Rect, 8, "uint"), NumPut(h, Rect, 12, "uint")
}

MDMF_Enum(HMON := "") {
    Static CallbackFunc := Func(A_AhkVersion < "2" ? "RegisterCallback" : "CallbackCreate")
    Static EnumProc := CallbackFunc.Call("MDMF_EnumProc")
    Static Obj := (A_AhkVersion < "2") ? "Object" : "Map"
    Static Monitors := {}
    If (HMON = "") ; new enumeration
    {
        Monitors := %Obj%("TotalCount", 0)
        If !DllCall("User32.dll\EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", EnumProc, "Ptr", &Monitors, "Int")
            Return False
    }
    Return (HMON = "") ? Monitors : Monitors.HasKey(HMON) ? Monitors[HMON] : False
}
