# Instala (ou atualiza) o Seaninho Transcritor para o usuário atual, sem precisar de administrador.
#   irm https://raw.githubusercontent.com/seazone-tech/seaninho-transcritor-dist/main/install.ps1 | iex
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$repo = "seazone-tech/seaninho-transcritor-dist"
$dir = Join-Path $env:LOCALAPPDATA "Programs\SeaninhoTranscritor"
$exe = Join-Path $dir "SeaninhoTranscritor.exe"

Write-Host "Baixando a ultima versao do Seaninho Transcritor..."
Get-Process SeaninhoTranscritor -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500
New-Item -ItemType Directory -Force $dir | Out-Null
Invoke-WebRequest "https://github.com/$repo/releases/latest/download/SeaninhoTranscritor.exe" -OutFile $exe -UseBasicParsing
Unblock-File $exe  # evita o aviso de "arquivo baixado da internet"

# Atalho no Menu Iniciar
$lnk = Join-Path ([Environment]::GetFolderPath("Programs")) "Seaninho Transcritor.lnk"
$shell = New-Object -ComObject WScript.Shell
$s = $shell.CreateShortcut($lnk)
$s.TargetPath = $exe
$s.WorkingDirectory = $dir
$s.Description = "Seaninho Transcritor - ditado por voz da Seazone"
$s.Save()

# Iniciar com o Windows (so deste usuario)
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "SeaninhoTranscritor" -Value "`"$exe`""

Start-Process $exe
Write-Host ""
Write-Host "Seaninho Transcritor instalado em $dir"
Write-Host "Na primeira abertura ele pede sua chave de IA da Seazone (ai-portal)."
Write-Host "Depois e so segurar Ctrl+Alt, falar e soltar."
