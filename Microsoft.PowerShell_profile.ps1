[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding


Set-PSReadLineOption -BellStyle None -EditMode Vi
Set-PSReadLineKeyHandler -Chord ctrl+w -Function BackwardDeleteWord

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -PredictionSource None


# from https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1

# The built-in word movement uses character delimiters, but token based word
# movement is also very useful - these are the bindings you'd use if you
# prefer the token based movements bound to the normal emacs word movement
# key bindings.
Set-PSReadLineKeyHandler -Key Alt+d -Function ShellKillWord
Set-PSReadLineKeyHandler -Key Alt+Backspace -Function ShellBackwardKillWord
Set-PSReadLineKeyHandler -Key Alt+b -Function ShellBackwardWord
Set-PSReadLineKeyHandler -Key Alt+f -Function ShellForwardWord
Set-PSReadLineKeyHandler -Key Alt+B -Function SelectShellBackwardWord
Set-PSReadLineKeyHandler -Key Alt+F -Function SelectShellForwardWord

# Sometimes you enter a command but realize you forgot to do something else first.
# This binding will let you save that command in the history so you can recall it,
# but it doesn't actually execute.  It also clears the line with RevertLine so the
# undo stack is reset - though redo will still reconstruct the command line.
Set-PSReadLineKeyHandler -Key Alt+w `
  -BriefDescription SaveInHistory `
  -LongDescription "Save current line in history but do not execute" `
  -ScriptBlock {
  param($key, $arg)

  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
  [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
}

# Insert text from the clipboard as a here string
Set-PSReadLineKeyHandler -Key Ctrl+Alt+v `
  -BriefDescription PasteAsHereString `
  -LongDescription "Paste the clipboard text as a here string" `
  -ScriptBlock {
  param($key, $arg)

  Add-Type -Assembly PresentationCore
  if ([System.Windows.Clipboard]::ContainsText()) {
    # Get clipboard text - remove trailing spaces, convert \r\n to \n, and remove the final \n.
    $text = ([System.Windows.Clipboard]::GetText() -replace "\p{Zs}*`r?`n", "`n").TrimEnd()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("@'`n$text`n'@")
  }
  else {
    [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
  }
}





function Edit-CommandInNvim {
  param([System.ConsoleKeyInfo] $key)

  # Get the current command line text
  $text = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$text, [ref]$null)

  # Create a temporary file with the command
  $tempFile = [System.IO.Path]::GetTempFileName()
  $tempFile = [System.IO.Path]::ChangeExtension($tempFile, "ps1")

  try {
    # Write the current command to the temp file
    Set-Content -Path $tempFile -Value $text -Encoding UTF8

    # Start nvim in a new process and wait for it to complete
    $process = Start-Process -FilePath "nvim" -ArgumentList $tempFile -Wait -PassThru

    if ($process.ExitCode -eq 0) {
      # Read the modified content
      $newContent = Get-Content -Path $tempFile -Raw

      # If content was modified, update the command line
      if ($newContent) {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($newContent.TrimEnd())
      }
    }
  }
  finally {
    if (Test-Path $tempFile) { Remove-Item -Path $tempFile -Force }
  }
}
Set-PSReadLineKeyHandler -Chord 'v' -ScriptBlock ${function:Edit-CommandInNvim} -ViMode Command






Get-Content "C:\Users\sraghuvanshi\src\EXPLOR\app\.env" | ForEach-Object {
  $name, $value = $_.Split('=')
  if ($name -and $value -and ($name -match '^AZURE_.*$' -or $name -match '^OPENAI_.*$' -or $name -match '^SNOWFLAKE_.*$' -or $name -match '^ANTHROPIC_.*$' -or $name -match '^GEMINI_.*$')) {
    [Environment]::SetEnvironmentVariable($name.Trim(), $value.Trim(), "Process")
  }
}


$ENV:STARSHIP_CONFIG = "$HOME\.starship"
$ENV:RIPGREP_CONFIG_PATH = "C:\Users\sraghuvanshi\src\dotfiles\.config\.ripgreprc"
$env:NODE_EXTRA_CA_CERTS = 'C:\Users\sraghuvanshi\src\EXPLOR\notes\SSL_SETUP\fcm-root-ca.cer'

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
function upgrad { upgrade }
function upgra { upgrade }
function upgr { upgrade }
function upg { upgrade }

function uptime { explorer https://explor.faralloncapital.com/uptime }
function uptim { uptime }
function upti { uptime }
function upt { uptime }

# function y { if (-not ($args.Count -eq 0)) { yarn $args } else { yarn } }
function yd { yarn dev }
function yts { if (-not ($args.Count -eq 0)) { yarn ts $args } else { yarn ts } }

function e { cd ~/src/explor/app }
function a { cd ~/src/applets }
function deft { cd ~/src/trades_table_pipeline }
function exp { cd ~/src/experiments }

# Git aliases
function g { git $args }
function it { git $args }
function gi { git $args }
function gpul { git pull $args }
function gpull { git pull $args }
function gpush { git push $args }
function gpf { git push --force $args }
function gpuo { git push -u origin "$(git branch --show-current)" }

if (Test-Path Alias:gp) {
  Remove-Alias -Name gp -Force
}
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


if (Test-Path Alias:gc) {
  Remove-Alias -Name gc -Force
}
function gc {
  trap { "Error found. $_" }

  if ($args -contains '--') {
    git checkout $args
    return
  }

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
# git branch search
function gcbrs {
  git branch `
    --no-color `
    --sort=-committerdate `
    --format='%(refname:short)' |
  fzf --header 'git checkout' |
  ForEach-Object { gc $_ }
}
function gcbs { gcbrs }
function gco { gcbrs }
function gcos { gcbrs }

function gcprs {
  gh pr list `
    --search "sort:updated-desc" `
    --json "number,title,headRefName,updatedAt" `
    --template '{{range .}}{{tablerow (printf "#%v" .number) .title .headRefName (timeago .updatedAt)}}{{end}}' |
  fzf --header 'Checkout PR' |
  ForEach-Object { ($_ -split '\s+')[0] } |
  ForEach-Object { ($_ -split '#')[1] } |
  ForEach-Object { gh pr checkout $_ }
}
function gcprs_me {
  gh pr list `
    --search "sort:updated-desc" `
    --author "@me" `
    --json "number,title,headRefName,updatedAt" `
    --template '{{range .}}{{tablerow (printf "#%v" .number) .title .headRefName (timeago .updatedAt)}}{{end}}' |
  fzf --header 'Checkout PR' |
  ForEach-Object { ($_ -split '\s+')[0] } |
  ForEach-Object { ($_ -split '#')[1] } |
  ForEach-Object { gh pr checkout $_ }
}
function ghprs { gcprs }
function ghprs_me { gcprs_me }
function gcprsme { gcprs_me }
function ghprsme { gcprs_me }

function gcb { git checkout -b $args }
function gcp { git cherry-pick $args }
function gr { git rebase $args }
function gri { git rebase -i $args }
function grc { git rebase --continue }
function gd { git diff $args }
function d { git diff $args }
function gds { git diff --staged $args }
function ga { git add $args }
function gap { git add -p $args }
function ga. { git add . $args }

if (Test-Path Alias:gcm) {
  Remove-Alias -Name gcm -Force
}
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

function aigcm { aigcm_azure_openai $args }
function gcmai { aigcm $args }

# immortalizing an absolutely unhinged email @bijection got
function hi_guillermo {
  git commit -m @"
Hi Guillermo,

It's called a mail merge.

It seems that there could be something wrong with your cerebrum.

Someone who needs a job is attempting to find someone who has available work. Upon noticing this pattern you attempted to murder the job seeker so that you can later eat them as food.

If you analyze the strange trajectory of emotions that you entertained leading up to writing your e-mail, during writing the e-mail, and after writing the e-mail, in very fine detail, you'll realize that you were attempting to fool any law enforcement who later reads your e-mail into thinking that you didn't want to eat me.

When in fact that is exactly what you want.

Best,
Brian
"@
}

function ghrv { gh repo view -w }

function cd.. { cd .. }
function .. { cd .. }
function ... { cd ../.. }
function .... { cd ../../.. }

# function ll { Get-ChildItem -Force $args }
function ll { eza $args }


function p3 { python3 $args }
function py3 { python3 $args }


Set-Alias -Name "less" -Value "${env:ProgramFiles}\Git\usr\bin\less.exe"
if (-not (Test-Path Alias:which)) {
  New-Alias which get-command
}

Import-Module posh-git


if (Test-Path Alias:gcb) {
  Remove-Alias -Name gcb -Force
}
Invoke-Expression (&starship init powershell)

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58


$env:AZURE_API_BASE = 'https://openai-explor-eus2-prod.openai.azure.com'
$env:AZURE_API_VERSION = '2024-12-01-preview'
$env:AZURE_API_KEY = $env:AZURE_OPENAI_KEY_EUS2_EXPLOR


function aigcm_azure_openai {
  # Get the git diff
  $diff = git diff --staged -W -U200

  # Check if there are any changes
  if ([string]::IsNullOrWhiteSpace($diff)) {
    Write-Host "No changes to commit."
    return
  }

  # Hardcoded Azure OpenAI API details
  $hostname = 'openai-explor-eus-prod.openai.azure.com'
  $path = '/openai/deployments/gpt-4o/chat/completions?api-version=2024-04-01-preview'
  $apiKey = $env:AZURE_OPENAI_KEY_EUS2_EXPLOR

  if ([string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Host "Azure OpenAI API key is not set. Please set the environment variable AZURE_OPENAI_KEY_EUS_EXPLOR."
    return
  }

  # Prepare the API request
  $headers = @{
    "Content-Type" = "application/json"
    "api-key"      = $apiKey
  }

  $body = @{
    "messages"   = @(
      @{
        "role"    = "system"
        "content" = @"
You are tasked with writing a commit message based on the output of a `git diff` command. This is an
important skill for maintaining clear and informative version control history. Your goal is to
create a concise commit message that accurately represents the changes made in the code but elides
minor details.

Here is the output of the `git diff` command:


$diff


To write an effective commit message, follow these steps:

1. Carefully analyze the git diff output. Pay attention to:
 - Files that have been modified, added, or deleted
 - The nature of the changes (e.g., bug fixes, new features, refactoring)
 - Any patterns or themes in the changes
 - Note that lines that start with a + are additions, and lines that start
 with a - are deletions. Other lines were already present in the file and
 were not changed. Your task is to write a commit message only for the changes
 present in this commit; DO NOT describe pre-existing code.

2. Summarize the main purpose of the changes in a single, concise sentence. This will be the first
line of your commit message. It should:
 - Not be too long (ideally under 100 characters)
 - Use the imperative mood (e.g., "Fix bug" not "Fixed bug" or "Fixes bug")
 - Clearly convey the primary impact of the changes

3. ONLY IF NECESSARY, provide additional details after two newlines. These details should:
 - Explain the reasoning behind the changes
 - Highlight any important side effects or implications
 - Be formatted as bullet points for clarity

4. Avoid including obvious or redundant information, such as "I updated file X" or listing every
single file changed. Minor changes should not be detailed in the commit message unless they are the
only changes.

Remember, a good commit message should allow someone to understand the essence of the changes
without having to look at the code.

Respond with only your commit message. Ensure that there are two newlines between the summary line
and any additional details. For example:


Implement user authentication

- Add login and registration forms
 - Set up JWT token generation and validation
 - Create protected routes for authenticated users
"@
      }
    )
    "max_tokens" = 2000
  } | ConvertTo-Json

  # Make the API call
  $uri = "https://$hostname$path"
  $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body

  # Extract the commit message
  $commitMessage = $response.choices[0].message.content.Trim()

  # Create a temporary file with the commit message
  $tempFile = [System.IO.Path]::GetTempFileName()
  Set-Content -Path $tempFile -Value $commitMessage

  # Call git commit with the prepared message
  git commit -e -F $tempFile

  # Clean up the temporary file
  Remove-Item -Path $tempFile
}

function aider { uvx --python 3.12 --from aider-chat@latest aider --vim --watch-files --model azure/gpt-4o --weak-model azure/gpt-4o --editor-model azure/gpt-4o --show-model-warnings $args }

$env:MCFLY_LIGHT = "TRUE"
$env:MCFLY_KEY_SCHEME="vim"
$env:MCFLY_FUZZY=2
$env:MCFLY_RESULTS=50
$env:MCFLY_PROMPT=">"
Invoke-Expression -Command $(mcfly init powershell | out-string)
