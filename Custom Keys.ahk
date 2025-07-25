#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#WinActivateForce
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Uncomment for debugging
; KeyHistory

; For this to work consistently, we need to set the following registry key to 0:
; `HKEY_CURRENT_USER\Control Panel\Desktop ... REG_DWORD ... ForegroundLockTimeout`
; (The default value is 200000 (0x30D40)).
; For more details, see https://github.com/microsoft/terminal/issues/8954
#Enter::
    Run, wt
; Sleep, 300
; WinActivate, ahk_class CASCADIA_HOSTING_WINDOW_CLASS
return
#+Enter::
    Run, wt -w 0 -p "PowerShell Core with Developer Command Prompt"
; Sleep, 300
; WinActivate, ahk_class CASCADIA_HOSTING_WINDOW_CLASS
return

#Backspace::
; Run, chrome.exe
; Run, MicrosoftEdge.exe
; Run, C:\Program Files\Firefox Developer Edition\firefox.exe
return

#+Backspace::
; Run, chrome.exe --incognito
; Run, MicrosoftEdge.exe --private
; Run, C:\Program Files\Firefox Developer Edition\firefox.exe -private-window
return

#Esc::#l

CapsLock::Esc

; Map Ctrl+Shift+W to Ctrl+W
^+w::^w

; Apple Magic Keyboard-specific bindings

; Set Win+Tab to Alt+Tab for muscle memory compatibility
Lwin & Tab::AltTab

; Remap media keys
RAlt & F1::
    RegRead, UserLocal, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders, Local AppData
    Run % "" . UserLocal . "\Programs\twinkle-tray\Twinkle Tray.exe --All --Offset=-5 --Overlay"
return

RAlt & F2::
    RegRead, UserLocal, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders, Local AppData
    Run % "" . UserLocal . "\Programs\twinkle-tray\Twinkle Tray.exe --All --Offset=+5 --Overlay"
return

RAlt & F7::SendInput {Media_Prev}
RAlt & F8::SendInput {Media_Play_Pause}
RAlt & F9::SendInput {Media_Next}
RAlt & F10::SendInput {Volume_Mute}
RAlt & F11::SendInput {Volume_Down}
RAlt & F12::SendInput {Volume_Up}
F13::SendInput {PrintScreen}

F14::SendInput {Media_Prev}
F18::SendInput {Media_Play_Pause}
F22::SendInput {Media_Next}

; https://simshaun.medium.com/inserting-en-dash-and-em-dash-on-windows-in-any-application-using-autohotkey-1fd010f4f7eb
; Shift+Alt+Minus = Em dash
+!-::
    Send {—}
return
+#-::
    Send {—}
return

#IfWinActive ahk_exe WindowsTerminal.exe
    +Enter::
        Send \{Enter}
    return
#IfWinActive

XButton1::Send, ^#{Left}    ; Back button = Previous desktop
XButton2::Send, ^#{Right}   ; Forward button = Next desktop