[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

Set-PSReadLineOption -BellStyle None -EditMode Emacs
Set-PSReadLineKeyHandler -Chord ctrl+w -Function BackwardDeleteWord

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -PredictionSource None

Set-PSReadLineKeyHandler -Key Tab -Function Complete

Get-Content "C:\Users\sraghuvanshi\src\EXPLOR\app\.env" | ForEach-Object {
  $name, $value = $_.Split('=')
  if ($name -and $value -and ($name -match '^AZURE_.*$' -or $name -match '^OPENAI_.*$' -or $name -match '^SNOWFLAKE_.*$' -or $name -match '^ANTHROPIC_.*$')) {
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

function y { if (-not ($args.Count -eq 0)) { yarn $args } else { yarn } }
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

function aigcm {
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
  $apiKey = $env:AZURE_OPENAI_KEY_EUS_EXPLOR

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
New-Alias which get-command

Import-Module posh-git

Remove-Alias -Name gcb -Force
Invoke-Expression (&starship init powershell)

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58
