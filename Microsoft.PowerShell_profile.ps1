[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

Set-PSReadLineOption -BellStyle None -EditMode Emacs
Set-PSReadLineKeyHandler -Chord ctrl+w -Function BackwardDeleteWord

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

Set-PSReadLineKeyHandler -Key Tab -Function Complete

function vim { 
  if ((Test-Path Env:\TERM_PROGRAM) -and ("vscode" -eq (Get-Item -Path Env:\TERM_PROGRAM).Value)) {
    if (-not ($args.Count -eq 0)) {
      code $args
    }
  }
  else {
    nvim $args 
  }
}
function vi { vim $args }

function :e { vim $args }
function :E { vim $args }
function :q { exit }
function :Q { exit }
function exi { exit }

# Git aliases
function g { git $args }
function gi { git $args }
function gpul { git pull $args }
function gpull { git pull $args }
function gpush { git push $args }
function gpf { git push --force $args }
function gpuo { git push -u origin "$(git branch --show-current)" }
function gc { git checkout $args }
function gcb { git checkout -b $args }
function gcp { git cherry-pick $args }
function gr { git rebase $args }
function gri { git rebase -i $args }
function gd { git diff $args }
function gds { git diff --staged $args }
function ga { git add $args }
function gap { git add -p $args }
function ga. { git add . $args }
Remove-Alias -Name gcm -Force
function gcm { git commit -m $args }
function gstat { git status $args }
function gca { git commit --amend $args }
function gs { git stash $args }
function gssp { git stash show -p $args }
function gsd { git stash drop $args }
function gsp { git show -p $args }
function gf { git fetch $args }
function gpush { git push $args }

function cd.. { cd .. }
function .. { cd .. }
function ... { cd ../.. }
function .... { cd ../../..}

function ll { Get-ChildItem -Force $args }


Import-Module posh-git

$ENV:STARSHIP_CONFIG = "$HOME\.starship"
$ENV:RIPGREP_CONFIG_PATH = "\\wsl$\Arch\home\savvy\dotfiles\.config\.ripgreprc"
Invoke-Expression (&starship init powershell)
