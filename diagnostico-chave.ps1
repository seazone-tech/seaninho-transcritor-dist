# Diagnostico: por que o Seaninho Pro pediu a chave de novo depois de reiniciar?
#
# So LE arquivos e o registro; nao muda nada e NUNCA mostra a chave (so diz se ela existe e o tamanho).
# Rodar no PowerShell do PC de quem perdeu a chave, com o Seaninho aberto ou fechado (nao precisa de administrador):
#   irm https://raw.githubusercontent.com/seazone-tech/seaninho-transcritor-dist/main/diagnostico-chave.ps1 | iex
# O resultado aparece na tela e fica em %TEMP%\seaninho-diagnostico-chave.txt (pode mandar esse arquivo).
# Sem acentos de proposito: o PowerShell 5.1 le .ps1 sem BOM como ANSI. Tudo dentro de & { } para o irm | iex
# nao deixar variaveis nem o ErrorActionPreference na sessao de quem rodou.

& {
    $ErrorActionPreference = "SilentlyContinue"
    $data = Join-Path $env:APPDATA "SeaninhoPro"
    $envFile = Join-Path $data ".env"
    $log = Join-Path $data "seaninho.log"
    $out = Join-Path $env:TEMP "seaninho-diagnostico-chave.txt"
    $lines = New-Object System.Collections.Generic.List[string]
    function Say($text) { $lines.Add($text); Write-Host $text }
    function Fmt($t) { if ($t) { $t.ToString("dd/MM HH:mm:ss") } else { "-" } }

    Say "== Seaninho Pro: diagnostico da chave ($(Get-Date -Format 'dd/MM/yyyy HH:mm')) =="
    Say "PC: $env:COMPUTERNAME   usuario: $env:USERNAME"
    Say "APPDATA: $env:APPDATA"
    if ($env:APPDATA -notlike "$env:USERPROFILE\AppData\Roaming*") { Say "  ATENCAO: o APPDATA nao esta no perfil local (pasta redirecionada ou perfil temporario)." }

    Say ""
    Say "-- Windows: ultimas ligadas/desligadas"
    Get-WinEvent -FilterHashtable @{LogName = 'System'; Id = 6005, 6006, 6008, 1074} -MaxEvents 8 |
        ForEach-Object { Say ("  {0}  {1}" -f (Fmt $_.TimeCreated), @{6005 = "ligou"; 6006 = "desligou"; 6008 = "desligou SEM AVISO (queda de energia/travou)"; 1074 = "pedido de desligar/reiniciar"}[$_.Id]) }

    Say ""
    Say "-- Programa"
    $exe = Join-Path $env:LOCALAPPDATA "Programs\SeaninhoPro\SeaninhoPro.exe"
    if (Test-Path $exe) { $f = Get-Item $exe; Say "  $exe  ($([math]::Round($f.Length / 1MB)) MB, de $(Fmt $f.LastWriteTime))" } else { Say "  Nao achei $exe" }
    $run = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    foreach ($n in "SeaninhoPro", "SeaninhoTranscritor") { if ($run.$n) { Say "  Abre com o Windows: $n = $($run.$n)" } }
    if (Test-Path (Join-Path $env:LOCALAPPDATA "Programs\SeaninhoTranscritor\SeaninhoTranscritor.exe")) { Say "  O Seaninho basico (Transcritor) tambem esta instalado." }
    $procs = Get-Process SeaninhoPro, SeaninhoTranscritor
    foreach ($p in $procs) { Say "  Aberto agora: $($p.ProcessName) (desde $(Fmt $p.StartTime))" }

    Say ""
    Say "-- Pasta de dados: $data"
    if (-not (Test-Path $data)) {
        Say "  A PASTA NAO EXISTE."
    } else {
        Get-ChildItem $data -Force | Sort-Object LastWriteTime |
            ForEach-Object { Say ("  {0,-26} {1,10}  criado {2}  mudou {3}" -f $_.Name, $(if ($_.PSIsContainer) { "<pasta>" } else { $_.Length }), (Fmt $_.CreationTime), (Fmt $_.LastWriteTime)) }
    }

    Say ""
    Say "-- .env (sem mostrar a chave)"
    if (-not (Test-Path $envFile)) {
        Say "  O .env NAO EXISTE."
    } else {
        $f = Get-Item $envFile -Force
        $bytes = [System.IO.File]::ReadAllBytes($envFile)
        $enc = if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { "UTF-16 (o Seaninho nao le!)" }
               elseif ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB) { "UTF-8 com BOM" } else { "UTF-8/ANSI" }
        Say "  $($f.Length) bytes, $enc, criado $(Fmt $f.CreationTime), mudou $(Fmt $f.LastWriteTime)"
        $text = [System.Text.Encoding]::UTF8.GetString($bytes)
        $vars = @{}
        foreach ($l in ($text -split "`r?`n")) {
            if ($l -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)$') { $vars[$Matches[1]] = $Matches[2].Trim().Trim('"').Trim("'") }
        }
        Say "  $($vars.Count) configuracoes"
        Say "  PROVIDER = $(if ($vars.ContainsKey('PROVIDER')) { "'$($vars['PROVIDER'])'" } else { 'FALTA (sem ela o Seaninho pede a chave)' })"
        foreach ($k in "SEAZONE_API_KEY", "OPENAI_API_KEY", "GROQ_API_KEY") {
            if ($vars.ContainsKey($k)) {
                $v = $vars[$k]
                Say "  $k = $(if ($v) { "preenchida ($($v.Length) caracteres)" } else { 'VAZIA' })"
            }
        }
        Say "  USER_NAME = $(if ($vars['USER_NAME']) { 'preenchido' } else { 'vazio' })"
        if (-not $text.EndsWith("`n")) { Say "  ATENCAO: o .env nao termina em nova linha (pode ter sido cortado no meio da gravacao)." }
    }
    foreach ($extra in ".env.tmp", "intro.json") {
        $p = Join-Path $data $extra
        if (Test-Path $p) { Say "  $extra existe (mudou $(Fmt (Get-Item $p -Force).LastWriteTime))$(if ($extra -eq 'intro.json') { ': ' + (Get-Content $p -Raw) })" }
    }
    $bak = Join-Path $env:LOCALAPPDATA "SeaninhoPro\chave.bin"
    Say "  Copia da chave (versao com a correcao): $(if (Test-Path $bak) { 'existe' } else { 'nao existe' })"

    Say ""
    Say "-- seaninho.log: aberturas, gravacoes do .env e a chave (ultimos 3 dias)"
    if (-not (Test-Path $log)) {
        Say "  Nao existe seaninho.log."
    } else {
        $all = Get-Content $log -Encoding UTF8
        Say "  Primeira linha do log: $(($all | Select-Object -First 1).Substring(0, 19)) (se for de hoje, a pasta foi recriada)"
        $since = (Get-Date).AddDays(-3).ToString("yyyy-MM-dd")
        $pat = "Abrindo o Seaninho|Configura..es recarregadas|Introdu..o|chave|Migra..o do b.sico|Atualiza..o|Abertura sem chave|Erro fatal"
        $all | Where-Object { $_ -ge $since -and $_ -match $pat -and $_ -notmatch "HTTP Request" } | Select-Object -Last 60 |
            ForEach-Object { Say "  $($_.Substring(0, [math]::Min(150, $_.Length)))" }
        Say "  (Configuracoes recarregadas = o .env foi gravado nesse instante; varias no mesmo segundo = gravacoes ao mesmo tempo)"
    }

    $lines | Set-Content $out -Encoding UTF8
    Write-Host ""
    Write-Host "Salvo em $out"
}
