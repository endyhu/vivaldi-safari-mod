# Adds safari-drag.js to Vivaldi's window.html so tab dragging works with safari.css.
# Vivaldi cannot load JavaScript from the CSS mods folder, so this edits its install
# folder. An update installs a fresh version folder without the edit, so run this
# again after each update, or register it to run on its own:
#
#   .\tools\install-drag.ps1              apply to every installed Vivaldi version
#   .\tools\install-drag.ps1 -Register    also re-apply at logon and every 15 minutes
#   .\tools\install-drag.ps1 -Remove      undo the edit (and -Unregister the task)
#
# Restart Vivaldi afterwards: window.html is read when a window opens.

param(
  [switch]$Remove,
  [switch]$Register,
  [switch]$Unregister,
  [string]$ApplicationDir = "$env:LOCALAPPDATA\Vivaldi\Application"
)

$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot '..\safari-drag.js' | Resolve-Path
$taskName = 'Vivaldi safari-drag patch'
# Marks the line this script added, so it can find and remove exactly that line.
$tag = '<script src="safari-drag.js"></script><!-- safari-mod -->'
$tagPattern = '(?m)^[ \t]*<script src="safari-drag\.js"></script><!-- safari-mod -->\r?\n'

if ($Unregister) {
  Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
  if (-not $Remove) { return }
}

$versions = Get-ChildItem $ApplicationDir -Directory | Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' }
foreach ($version in $versions) {
  $dir = Join-Path $version.FullName 'resources\vivaldi'
  $page = Join-Path $dir 'window.html'
  if (-not (Test-Path $page)) { continue }
  $html = [IO.File]::ReadAllText($page)
  $clean = [regex]::Replace($html, $tagPattern, '')
  if ($Remove) {
    Remove-Item (Join-Path $dir 'safari-drag.js') -ErrorAction SilentlyContinue
    $patched = $clean
  } else {
    Copy-Item $script (Join-Path $dir 'safari-drag.js') -Force
    if ($clean -notmatch '</body>') { throw "No </body> in $page; Vivaldi's window.html changed, so the edit needs revisiting." }
    $patched = $clean -replace '(?m)^([ \t]*)</body>', "`$1  $tag`n`$1</body>"
  }
  if ($patched -ne $html) { [IO.File]::WriteAllText($page, $patched, [Text.UTF8Encoding]::new($false)) }
  "$($version.Name): " + $(if ($Remove) { 'removed' } else { 'patched' })
}

if ($Register) {
  $action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument "-NoProfile -WindowStyle Hidden -File `"$PSCommandPath`""
  $triggers = @(
    New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15)
  )
  Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $triggers -Force | Out-Null
  "Registered scheduled task '$taskName'."
}
