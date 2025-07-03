@echo off
:: dgc - stable Windows bootstrap for Claude Code + contextkit
:: Keeps the entrypoint minimal and delegates launcher logic to PowerShell.

setlocal

set "DG=%USERPROFILE%.contextkit"
set "LOCAL_PS1=%DG%\ckc.ps1"
set "LOCAL_CMD=%DG%\ckc.cmd"
set "PENDING_CMD=%DG%\ckc.cmd.new"
set "BOOTSTRAP_PS1=%TEMP%\contextkit_ckc_bootstrap.ps1"
set "REMOTE_PS1=https://raw.githubusercontent.com/Ruchitha1608/Context-Code/main/bin/ckc.ps1"
set "REMOTE_PS1_R2=/ckc.ps1"
set "REMOTE_GR_CMD=https://raw.githubusercontent.com/Ruchitha1608/Context-Code/main/bin/contextkit.cmd"
set "REMOTE_GR_PS1=https://raw.githubusercontent.com/Ruchitha1608/Context-Code/main/bin/contextkit.ps1"
set "REMOTE_GR_CMD_R2=/contextkit.cmd"
set "REMOTE_GR_PS1_R2=/contextkit.ps1"
set "INSTALL_METHOD=direct"
set "REPAIR_CMD=irm https://raw.githubusercontent.com/Ruchitha1608/Context-Code/main/install.ps1 ^| iex"

if not exist "%DG%" mkdir "%DG%" >nul 2>&1

if exist "%PENDING_CMD%" (
  move /y "%PENDING_CMD%" "%LOCAL_CMD%" >nul 2>&1
)

if defined SCOOP (
  if exist "%SCOOP%\shims\ckc.cmd" (
    set "INSTALL_METHOD=scoop"
    set "REPAIR_CMD=scoop update contextkit"
  )
) else (
  if exist "%USERPROFILE%\scoop\shims\ckc.cmd" (
    set "INSTALL_METHOD=scoop"
    set "REPAIR_CMD=scoop update contextkit"
  )
)

:: Download fresh PS1 from R2 (trusted, no CDN cache) to bootstrap and local.
:: dl  = atomic download, R2-trusted (no parse check needed).
:: dls = atomic download + UTF8 ScriptBlock::Create validation (for GitHub fallback).
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$gh='%REMOTE_PS1%';$r2='%REMOTE_PS1_R2%';$loc='%LOCAL_PS1%';$bs='%BOOTSTRAP_PS1%';" ^
  "function dl($u,$o){$t=$o+'.tmp';try{Invoke-WebRequest $u -OutFile $t -UseBasicParsing -TimeoutSec 15;if((Test-Path $t)-and(Get-Item $t).Length-gt 1024){Move-Item $t $o -Force;return $true}}catch{};Remove-Item $t -Force -EA SilentlyContinue;return $false};" ^
  "function dls($u,$o){$t=$o+'.tmp';try{Invoke-WebRequest $u -OutFile $t -UseBasicParsing -TimeoutSec 15;if((Test-Path $t)-and(Get-Item $t).Length-gt 1024){try{[void][System.Management.Automation.ScriptBlock]::Create((Get-Content $t -Raw -Encoding UTF8));Move-Item $t $o -Force;return $true}catch{}}}catch{};Remove-Item $t -Force -EA SilentlyContinue;return $false};" ^
  "if(-not(dl $r2 $bs)){dls $gh $bs|Out-Null};if(-not(dl $r2 $loc)){dls $gh $loc|Out-Null};" ^
  "dl '%REMOTE_GR_CMD_R2%' '%DG%\contextkit.cmd'|Out-Null;if(-not(Test-Path '%DG%\contextkit.cmd')){dl '%REMOTE_GR_CMD%' '%DG%\contextkit.cmd'|Out-Null};" ^
  "dl '%REMOTE_GR_PS1_R2%' '%DG%\contextkit.ps1'|Out-Null;if(-not(Test-Path '%DG%\contextkit.ps1')){dl '%REMOTE_GR_PS1%' '%DG%\contextkit.ps1'|Out-Null}" ^
  >nul 2>&1

:: Run bootstrap if it exists and is valid PS1 (R2 could return HTML on error).
if exist "%BOOTSTRAP_PS1%" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "try{[void][System.Management.Automation.ScriptBlock]::Create((Get-Content '%BOOTSTRAP_PS1%' -Raw -Encoding UTF8));exit 0}catch{exit 1}" >nul 2>&1
  if not errorlevel 1 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%BOOTSTRAP_PS1%" %*
    set "EXIT_CODE=%ERRORLEVEL%"
    del "%BOOTSTRAP_PS1%" >nul 2>&1
    exit /b %EXIT_CODE%
  )
  del "%BOOTSTRAP_PS1%" >nul 2>&1
)

:: Self-heal: validate local PS1 before running. If corrupted, delete and re-download from R2.
if exist "%LOCAL_PS1%" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "try{[void][System.Management.Automation.ScriptBlock]::Create((Get-Content '%LOCAL_PS1%' -Raw -Encoding UTF8));exit 0}catch{exit 1}" >nul 2>&1
  if errorlevel 1 (
    del "%LOCAL_PS1%" >nul 2>&1
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try{$t='%LOCAL_PS1%'+'.tmp';Invoke-WebRequest '%REMOTE_PS1_R2%' -OutFile $t -UseBasicParsing -TimeoutSec 20;if((Test-Path $t)-and(Get-Item $t).Length-gt 1024){Move-Item $t '%LOCAL_PS1%' -Force}}catch{try{$t='%LOCAL_PS1%'+'.tmp';Invoke-WebRequest '%REMOTE_PS1%' -OutFile $t -UseBasicParsing -TimeoutSec 20;if((Test-Path $t)-and(Get-Item $t).Length-gt 1024){Move-Item $t '%LOCAL_PS1%' -Force}}catch{}}" >nul 2>&1
  )
)

if exist "%LOCAL_PS1%" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%LOCAL_PS1%" %*
  exit /b %ERRORLEVEL%
)

echo [ckc] Error: bootstrap unavailable and local launcher missing.
if /i "%INSTALL_METHOD%"=="scoop" (
  echo [ckc] Scoop is installed, but the local launcher payload is missing.
)
echo [ckc] Run this once to repair the installation:
echo [ckc]   %REPAIR_CMD%
exit /b 1
