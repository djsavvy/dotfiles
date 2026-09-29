#Requires AutoHotkey v2.0
#Warn
#WinActivateForce
SendMode "Input"
SetWorkingDir A_ScriptDir

; Uncomment for debugging
; KeyHistory

; For this to work consistently, we need to set the following registry key to 0:
; `HKEY_CURRENT_USER\Control Panel\Desktop ... REG_DWORD ... ForegroundLockTimeout`
; (The default value is 200000 (0x30D40)).
; For more details, see https://github.com/microsoft/terminal/issues/8954
#Enter:: Run "wt"
#+Enter:: Run 'wt -w 0 -p "PowerShell Core with Developer Command Prompt"'

; Win+Backspace / Win+Shift+Backspace reserved for browser shortcuts (chrome/firefox).
; Win+Escape locks the screen (same as Win+L).
#Esc::#l

CapsLock::Esc

; Map Ctrl+Shift+W to Ctrl+W
^+w::^w

; Apple Magic Keyboard-specific bindings

; Set Win+Tab to Alt+Tab for muscle memory compatibility
; Lwin & Tab::AltTab

; Remap media keys
RAlt & F1:: {
    UserLocal := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders", "Local AppData")
    Run UserLocal . "\Programs\twinkle-tray\Twinkle Tray.exe --All --Offset=-5 --Overlay"
}
RAlt & F2:: {
    UserLocal := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders", "Local AppData")
    Run UserLocal . "\Programs\twinkle-tray\Twinkle Tray.exe --All --Offset=+5 --Overlay"
}

RAlt & F7::Send "{Media_Prev}"
RAlt & F8::Send "{Media_Play_Pause}"
RAlt & F9::Send "{Media_Next}"
RAlt & F10::Send "{Volume_Mute}"
RAlt & F11::Send "{Volume_Down}"
RAlt & F12::Send "{Volume_Up}"
F13::Send "{PrintScreen}"

F14::Send "{Media_Prev}"
F18::Send "{Media_Play_Pause}"
F22::Send "{Media_Next}"

; https://simshaun.medium.com/inserting-en-dash-and-em-dash-on-windows-in-any-application-using-autohotkey-1fd010f4f7eb
; Shift+Alt+Minus or Shift+Win+Minus = Em dash
+!-::Send "—"
+#-::Send "—"

#HotIf WinActive("ahk_exe WindowsTerminal.exe")
+Enter::Send "\{Enter}"
#HotIf

XButton1::Send "^#{Left}"    ; Back button = Previous desktop
XButton2::Send "^#{Right}"   ; Forward button = Next desktop
