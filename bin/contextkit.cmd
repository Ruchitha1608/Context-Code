@echo off
:: contextkit — Windows bootstrap for ContextKit with AI tool selection
:: Usage:
::   contextkit [path] --claude    Claude Code  (same as ckc)
::   contextkit [path] --codex     OpenAI Codex (same as ck)
::   contextkit [path] --cursor    Cursor IDE
::   contextkit [path] --gemini    Google Gemini CLI
::   contextkit [path] --opencode  OpenCode
::   contextkit [path] --copilot   GitHub Copilot (VS Code)
::
:: Default tool: --claude.  Default path: current directory.

setlocal EnableDelayedExpansion

set "DG=%USERPROFILE%.contextkit"
set "LOCAL_PS1=%DG%\contextkit.ps1"
set "BOOTSTRAP_PS1=%TEMP%\contextkit_bootstrap.ps1"
set "REMOTE_PS1=https://raw.githubusercontent.com/Ruchitha1608/Context-Code/main/bin/contextkit.ps1"
set "REMOTE_PS1_R2=/contextkit.ps1"
set "REMOTE_DGC_PS1=https://raw.githubusercontent.com/Ruchitha1608/Context-Code/main/bin/ckc.ps1"
set "REMOTE_DGC_PS1_R2=/ckc.ps1"
set "REMOTE_DG_PS1=https://raw.githubusercontent.com/Ruchitha1608/Context-Code/main/bin/ck.ps1"
set "REMOTE_DG_PS1_R2=/ck.ps1"
set "REMOTE_DGC_CMD_R2=/ckc.cmd"
set "REMOTE_DG_CMD_R2=/ck.cmd"
set "INSTALL_METHOD=direct"
set "REPAIR_CMD=irm https://raw.githubusercontent.com/Ruchitha1608/Context-Code/main/install.ps1 ^| iex"

if not exist "%DG%" mkdir "%DG%" >nul 2>&1

if defined SCOOP (
  if exist "%SCOOP%\shims\contextkit.cmd" (
    set "INSTALL_METHOD=scoop"
    set "REPAIR_CMD=scoop update contextkit"
  )
) else (
  if exist "%USERPROFILE%\scoop\shims\contextkit.cmd" (
    set "INSTALL_METHOD=scoop"
    set "REPAIR_CMD=scoop update contextkit"
  )
)

:: Bootstrap: R2-first atomic download (dl), GitHub fallback with UTF8 parse check (dls).
:: R2 is a direct object store — no CDN cache — so no ScriptBlock parse check needed.
:: GitHub raw CDN can serve stale UTF-8 content that PS5.1 misreads as Windows-1252,
:: so dls uses -Encoding UTF8 before accepting the file.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$gh='%REMOTE_PS1%';$r2='%REMOTE_PS1_R2%';$loc='%LOCAL_PS1%';$bs='%BOOTSTRAP_PS1%';" ^
  "function dl($u,$o){$t=$o+'.tmp';try{Invoke-WebRequest $u -OutFile $t -UseBasicParsing -TimeoutSec 15;if((Test-Path $t)-and(Get-Item $t).Length-gt 1024){Move-Item $t $o -Force;return $true}}catch{};Remove-Item $t -Force -EA SilentlyContinue;return $false};" ^
  "function dls($u,$o){$t=$o+'.tmp';try{Invoke-WebRequest $u -OutFile $t -UseBasicParsing -TimeoutSec 15;if((Test-Path $t)-and(Get-Item $t).Length-gt 1024){try{[void][System.Management.Automation.ScriptBlock]::Create((Get-Content $t -Raw -Encoding UTF8));Move-Item $t $o -Force;return $true}catch{}}}catch{};Remove-Item $t -Force -EA SilentlyContinue;return $false};" ^
  "if(-not(dl $r2 $bs)){dls $gh $bs|Out-Null};if(-not(dl $r2 $loc)){dls $gh $loc|Out-Null};" ^
  "dl '%REMOTE_DGC_PS1_R2%' '%DG%\ckc.ps1'|Out-Null;if(-not(Test-Path '%DG%\ckc.ps1')){dls '%REMOTE_DGC_PS1%' '%DG%\ckc.ps1'|Out-Null};" ^
  "dl '%REMOTE_DG_PS1_R2%' '%DG%\ck.ps1'|Out-Null;if(-not(Test-Path '%DG%\ck.ps1')){dls '%REMOTE_DG_PS1%' '%DG%\ck.ps1'|Out-Null};" ^
  "dl '%REMOTE_DGC_CMD_R2%' '%DG%\ckc.cmd'|Out-Null;dl '%REMOTE_DG_CMD_R2%' '%DG%\ck.cmd'|Out-Null" ^
  >nul 2>&1

if exist "%BOOTSTRAP_PS1%" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%BOOTSTRAP_PS1%" %*
  set "EXIT_CODE=%ERRORLEVEL%"
  del "%BOOTSTRAP_PS1%" >nul 2>&1
  exit /b %EXIT_CODE%
)

if exist "%LOCAL_PS1%" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%LOCAL_PS1%" %*
  exit /b %ERRORLEVEL%
)

echo [contextkit] Error: bootstrap unavailable and local launcher missing.
if /i "%INSTALL_METHOD%"=="scoop" (
  echo [contextkit] Scoop is installed, but the local launcher payload is missing.
)
echo [contextkit] Run this once to repair the installation:
echo [contextkit]   %REPAIR_CMD%
exit /b 1
