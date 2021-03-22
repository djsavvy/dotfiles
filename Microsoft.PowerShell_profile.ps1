[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

Set-PSReadLineOption -BellStyle None -EditMode Emacs
Set-PSReadLineKeyHandler -Chord ctrl+w -Function BackwardDeleteWord

function neovide { neovide-0.7.0.exe --multiGrid $args }
function vim { neovide $args }
