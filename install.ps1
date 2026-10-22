# Instala (ou atualiza) o Seaninho da Seazone para o usuário atual, sem precisar de administrador.
#   irm https://raw.githubusercontent.com/seazone-tech/seaninho-transcritor-dist/main/install.ps1 | iex
#
# Pergunta qual versão instalar:
#   Básico  (Seaninho Transcritor): ditado por voz. Segura Ctrl+Alt, fala, solta, o texto aparece.
#   Pro     (Seaninho Pro): o ditado e mais um assistente de voz: agenda, e-mails, Drive, Slack, lembretes,
#           saúde, cópias, responder conversas e os dados da Seazone (Taskdex, Nekt...).
#
# Sem perguntas (para o Claude ou a TI):
#   $env:SEANINHO_VERSAO = "pro" | "basico"   escolhe a versão
#   $env:SEANINHO_PRO_REPLACE = "sim" | "nao" se o básico já estiver instalado, troca pelo Pro ou mantém os dois
#   $env:SEANINHO_PRO_NO_START = "1"          não abre o app no fim (o Claude configura antes)
#   $env:SEANINHO_PRO_EXE = "C:\...\SeaninhoPro.exe"  instala um .exe local em vez de baixar
# Passo a passo para o Claude instalar tudo (chave, Google, Nekt): INSTALAR_COM_CLAUDE.md, neste repositório.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$repo   = "seazone-tech/seaninho-transcritor-dist"
$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$menu   = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"

$basicDir  = Join-Path $env:LOCALAPPDATA "Programs\SeaninhoTranscritor"
$basicExe  = Join-Path $basicDir "SeaninhoTranscritor.exe"
$basicData = Join-Path $env:APPDATA "SeaninhoTranscritor"
$basicLnk  = Join-Path $menu "Seaninho Transcritor.lnk"

$proDir  = Join-Path $env:LOCALAPPDATA "Programs\SeaninhoPro"
$proExe  = Join-Path $proDir "SeaninhoPro.exe"
$proData = Join-Path $env:APPDATA "SeaninhoPro"

Add-Type -AssemblyName System.Windows.Forms

function New-Shortcut($name, $target, $workDir, $description) {
    $shell = New-Object -ComObject WScript.Shell
    $s = $shell.CreateShortcut((Join-Path $menu "$name.lnk"))
    $s.TargetPath = $target
    $s.WorkingDirectory = $workDir
    $s.Description = $description
    $s.Save()
}

function Get-ProUrl {
    # O Pro sai em releases "pro-v*" que não são a "latest" (a latest continua sendo o básico):
    # pega a release mais nova que tem o SeaninhoPro.exe.
    $releases = Invoke-RestMethod "https://api.github.com/repos/$repo/releases?per_page=30" -UseBasicParsing
    foreach ($r in $releases) {
        $asset = $r.assets | Where-Object { $_.name -eq "SeaninhoPro.exe" } | Select-Object -First 1
        if ($asset) { return $asset.browser_download_url }
    }
    throw "Nao achei o SeaninhoPro.exe nas releases de $repo."
}

# ---- 0. Qual versão? ---------------------------------------------------------------
$choice = "$env:SEANINHO_VERSAO".Trim().ToLower()
if ($choice -notin @("pro", "basico", "básico")) {
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "Qual Seaninho você quer instalar?`n`n" +
        "SIM = Seaninho Pro`n" +
        "   Ditado por voz + assistente: agenda, e-mails, Drive, Slack, lembretes, saúde,`n" +
        "   histórico de cópias, responder conversas e dados da Seazone (Taskdex, Nekt).`n`n" +
        "NÃO = Seaninho Transcritor (básico)`n" +
        "   Só o ditado: segura Ctrl+Alt, fala, solta e o texto aparece.",
        "Instalar Seaninho",
        [System.Windows.Forms.MessageBoxButtons]::YesNoCancel,
        [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($answer -eq [System.Windows.Forms.DialogResult]::Cancel) { Write-Host "Instalacao cancelada."; return }
    $choice = if ($answer -eq [System.Windows.Forms.DialogResult]::Yes) { "pro" } else { "basico" }
}

# ---- Básico ------------------------------------------------------------------------
if ($choice -ne "pro") {
    Write-Host "Baixando a ultima versao do Seaninho Transcritor..."
    Get-Process SeaninhoTranscritor -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 500
    New-Item -ItemType Directory -Force $basicDir | Out-Null
    Invoke-WebRequest "https://github.com/$repo/releases/latest/download/SeaninhoTranscritor.exe" -OutFile $basicExe -UseBasicParsing
    Unblock-File $basicExe  # evita o aviso de "arquivo baixado da internet"
    New-Shortcut "Seaninho Transcritor" $basicExe $basicDir "Seaninho Transcritor - ditado por voz da Seazone"
    Set-ItemProperty $runKey -Name "SeaninhoTranscritor" -Value "`"$basicExe`""
    if (-not $env:SEANINHO_PRO_NO_START) { Start-Process $basicExe }
    Write-Host ""
    Write-Host "Seaninho Transcritor instalado em $basicDir"
    Write-Host "Na primeira abertura ele pede sua chave de IA da Seazone (ai-portal.seazone.com.br > Keys)."
    return
}

# ---- Pro: 1. o básico já está instalado? -----------------------------------------------
function Test-Basic {
    (Test-Path $basicExe) -or
    ($null -ne (Get-ItemProperty $runKey -ErrorAction SilentlyContinue).SeaninhoTranscritor) -or
    ($null -ne (Get-Process SeaninhoTranscritor -ErrorAction SilentlyContinue))
}

function Move-BasicData {
    # Só traz o que o Pro ainda não tem: nunca sobrescreve uma configuração do Pro.
    if (-not (Test-Path $basicData)) { return }
    New-Item -ItemType Directory -Force $proData | Out-Null
    foreach ($f in ".env", "dicionario.json", "atalhos.json", "historico.jsonl") {
        $from = Join-Path $basicData $f
        $to = Join-Path $proData $f
        if ((Test-Path $from) -and -not (Test-Path $to)) { Copy-Item $from $to }
    }
}

function Remove-Basic {
    Get-Process SeaninhoTranscritor -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 700
    Remove-ItemProperty $runKey -Name "SeaninhoTranscritor" -ErrorAction SilentlyContinue
    Remove-Item $basicLnk -Force -ErrorAction SilentlyContinue
    Remove-Item $basicDir -Recurse -Force -ErrorAction SilentlyContinue
}

$replaced = $false
if (Test-Basic) {
    $silent = $env:SEANINHO_PRO_REPLACE
    if ($silent) {
        $replaced = $silent -match "^(s|sim|y|yes|1)$"
    } else {
        $answer = [System.Windows.Forms.MessageBox]::Show(
            "Encontramos o Seaninho Transcritor (versão básica) neste computador.`n`n" +
            "Vamos substituir pelo Seaninho Pro?`n`n" +
            "• Sua chave de IA, nome, dicionário, atalhos de texto e histórico vêm junto.`n" +
            "• O básico é desinstalado e só o Pro abre com o Windows.`n`n" +
            "Se escolher Não, os dois ficam instalados. Os dois usam Ctrl+Alt, então ditariam em dobro se estiverem abertos juntos.",
            "Instalar Seaninho Pro",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question)
        $replaced = $answer -eq [System.Windows.Forms.DialogResult]::Yes
    }
    Move-BasicData  # em qualquer caso, aproveita a chave e o dicionário: ninguém precisa digitar de novo
    if ($replaced) {
        Write-Host "Substituindo o Seaninho Transcritor pelo Pro..."
        Remove-Basic
    }
}

# ---- Pro: 2. instalar --------------------------------------------------------------------
Get-Process SeaninhoPro -ErrorAction SilentlyContinue | Stop-Process -Force
for ($i = 0; $i -lt 30 -and (Get-Process SeaninhoPro -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Milliseconds 300 }
New-Item -ItemType Directory -Force $proDir | Out-Null

$here = if ($PSScriptRoot) { $PSScriptRoot } else { "" }
$local = if ($env:SEANINHO_PRO_EXE) { $env:SEANINHO_PRO_EXE } elseif ($here) { Join-Path $here "SeaninhoPro.exe" } else { "" }
if ($local -and (Test-Path $local)) {
    Write-Host "Copiando o Seaninho Pro..."
    Copy-Item $local $proExe -Force
} else {
    Write-Host "Baixando a ultima versao do Seaninho Pro..."
    Invoke-WebRequest (Get-ProUrl) -OutFile $proExe -UseBasicParsing
}
Unblock-File $proExe

New-Shortcut "Seaninho Pro" $proExe $proDir "Seaninho Pro - ditado por voz e assistente da Seazone"
Set-ItemProperty $runKey -Name "SeaninhoPro" -Value "`"$proExe`""

if (-not $env:SEANINHO_PRO_NO_START) { Start-Process $proExe }
Write-Host ""
Write-Host "Seaninho Pro instalado em $proDir"
if ($replaced) {
    Write-Host "O Seaninho Transcritor basico foi substituido. Seus dados antigos continuam em $basicData."
}
if (Test-Path (Join-Path $proData ".env")) {
    Write-Host "Suas configuracoes vieram junto. E so segurar Ctrl+Alt, falar e soltar."
} else {
    Write-Host "Na primeira abertura ele pede sua chave de IA da Seazone (ai-portal.seazone.com.br > Keys)."
}
