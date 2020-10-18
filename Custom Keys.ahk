#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Uncomment for debugging
; KeyHistory

#Enter::
    Run, wt
return

#Backspace::
    Run, C:\Program Files\Firefox Nightly\firefox.exe
return

#+Backspace::
    Run, C:\Program Files\Firefox Nightly\firefox.exe --private-window
return

#Esc::#l

; Apple Magic Keyboard-specific bindings

; Set Win+Tab to Alt+Tab for muscle memory compatibility
Lwin & Tab::AltTab

; Remap media keys
RAlt & F7::SendInput {Media_Prev}
RAlt & F8::SendInput {Media_Play_Pause}
RAlt & F9::SendInput {Media_Next}
RAlt & F10::SendInput {Volume_Mute}
RAlt & F11::SendInput {Volume_Down}
RAlt & F12::SendInput {Volume_Up}
F13::SendInput {PrintScreen}
