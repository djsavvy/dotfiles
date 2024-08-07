[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

Set-PSReadLineOption -BellStyle None -EditMode Emacs
Set-PSReadLineKeyHandler -Chord ctrl+w -Function BackwardDeleteWord

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -PredictionSource None

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

function upgrade { explorer https://explor.faralloncapital.com/upgrade }
function upgrad { explorer https://explor.faralloncapital.com/upgrade }
function upgra { explorer https://explor.faralloncapital.com/upgrade }
function upgr { upgrade } 
function upg { upgrade } 
function up { upgrade}

function y { yarn $args } 
function yd { yarn dev } 
function yts { yarn ts $args }

function e { cd ~/src/explor/app }

# Git aliases
function g { git $args }
function it { git $args }
function gi { git $args }
function gpul { git pull $args }
function gpull { git pull $args }
function gpush { git push $args }
function gpf { git push --force $args }
function gpuo { git push -u origin "$(git branch --show-current)" }

Remove-Alias -Name gp -Force
function gp { 
  trap { "Error found. $_" }

  git update-index --refresh;
  git diff-index --quiet HEAD --;
  $need_to_stash = -not ( $? )

  if ( $need_to_stash ) {
    git stash;
  }  
  git pull;
  git push $args;
  if ( $need_to_stash ) {
    git stash pop;
  }
}

Remove-Alias -Name gc -Force
function gc { 
  trap { "Error found. $_" }

  git update-index --refresh;
  git diff-index --quiet HEAD --;
  $need_to_stash = -not ( $? )

  if ( $need_to_stash ) {
    git stash;
  }  
  git checkout $args 
  if ( $need_to_stash ) {
    git stash pop;
  }
}

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
function gcam { git commit --amend $args }
function gs { git stash $args }
function gssp { git stash show -p $args }
function gsd { git stash drop $args }
function gsp { git show -p $args }
function gf { git fetch $args }
function gpush { git push $args }

function ghrv { gh repo view -w }

function cd.. { cd .. }
function .. { cd .. }
function ... { cd ../.. }
function .... { cd ../../.. }

# function ll { Get-ChildItem -Force $args }
function ll { eza $args } 

Set-Alias -Name "less" -Value "${env:ProgramFiles}\Git\usr\bin\less.exe"
New-Alias which get-command

Import-Module posh-git

$ENV:STARSHIP_CONFIG = "$HOME\.starship"
$ENV:RIPGREP_CONFIG_PATH = "C:\Users\sraghuvanshi\src\dotfiles\.config\.ripgreprc"
$env:NODE_EXTRA_CA_CERTS = 'C:\Users\sraghuvanshi\src\EXPLOR\notes\SSL_SETUP\fcm-root-ca.cer'

Remove-Alias -Name gcb -Force
Invoke-Expression (&starship init powershell)

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58
