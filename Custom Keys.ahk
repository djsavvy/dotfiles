#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Enter::
    Run, wt
return

#Backspace::
    Run, C:\Program Files\Firefox Nightly\firefox.exe
return

#+Backspace::
    Run, C:\Program Files\Firefox Nightly\firefox.exe --private-window
return

; Set Win+Tab to Alt+Tab for muscle memory compatibility with the apple magic keyboard
Lwin & Tab::AltTab

#Esc::#l
