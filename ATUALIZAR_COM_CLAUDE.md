# Atualizar o Seaninho Pro com o Claude

Este arquivo é para o **Claude** (Claude Code ou o app do Claude no computador) seguir. A pessoa só precisa colar
no Claude:

> Atualize o meu Seaninho Pro seguindo https://raw.githubusercontent.com/seazone-tech/seaninho-transcritor-dist/main/ATUALIZAR_COM_CLAUDE.md

---

## Para o Claude

O Seaninho Pro já está instalado no Windows desta pessoa. Você vai atualizá-lo para a versão mais nova publicada
(**1.6.13.1 ou maior**). Ela corrige o Seaninho **pedindo a chave de novo depois de reiniciar o computador**: a
chave fica num arquivo (`.env`) que podia ficar vazio quando duas gravações se cruzavam. A versão nova grava sem
esse risco, guarda uma cópia cifrada da chave e a põe de volta sozinha se ela sumir. Daqui em diante, o próprio
Seaninho se atualiza toda vez que abre.

Fale com a pessoa em português, em frases curtas, e diga o que está fazendo a cada passo. Nada aqui precisa de
administrador.

**Regras:**
- **Nunca abra, mostre, copie nem peça a chave** e não edite `%APPDATA%\SeaninhoPro\.env`: o Seaninho cuida dele.
- Não apague nada em `%APPDATA%\SeaninhoPro` (configurações, dicionário, histórico, anotações).
- Rode os comandos no PowerShell.

### 1. Diagnóstico (antes de atualizar)

Só lê (nunca mostra a chave) e registra por que a chave tinha sumido, para o Arthur confirmar a causa:

```powershell
irm https://raw.githubusercontent.com/seazone-tech/seaninho-transcritor-dist/main/diagnostico-chave.ps1 | iex
Copy-Item "$env:TEMP\seaninho-diagnostico-chave.txt" ([Environment]::GetFolderPath("Desktop")) -Force
```

Não precisa explicar o resultado. Diga só: "Deixei o arquivo `seaninho-diagnostico-chave.txt` na sua Área de
Trabalho. Mande para o Arthur, ele usa para confirmar a causa."

### 2. Atualizar

Se o Seaninho básico também estiver instalado, o instalador abre uma janela perguntando se troca pelo Pro. Para
não abrir a janela, confira antes:

```powershell
Test-Path "$env:LOCALAPPDATA\Programs\SeaninhoTranscritor\SeaninhoTranscritor.exe"
```

Se der `True`, pergunte à pessoa se pode remover o básico (recomendado: os dois usam `Ctrl+Alt`) e defina
`$env:SEANINHO_PRO_REPLACE = "sim"` ou `"nao"` antes do comando abaixo.

```powershell
$env:SEANINHO_VERSAO = "pro"; irm https://raw.githubusercontent.com/seazone-tech/seaninho-transcritor-dist/main/install.ps1 | iex
```

O instalador fecha o Seaninho, troca o programa e abre a versão nova. A chave, o nome e as configurações ficam como
estão. Se o Windows SmartScreen avisar, a pessoa clica em "Mais informações" › "Executar assim mesmo".

### 3. Conferir

Espere uns 20 segundos (o Seaninho abre perto do relógio) e rode:

```powershell
$exe = "$env:LOCALAPPDATA\Programs\SeaninhoPro\SeaninhoPro.exe"
$out = "$env:TEMP\seaninho-pro-verificar.json"
Start-Process $exe -ArgumentList "--verificar", "--saida", "`"$out`"" -Wait
Get-Content $out -Encoding UTF8
Test-Path "$env:LOCALAPPDATA\SeaninhoPro\chave.bin"
```

- `"versao"` tem que ser **1.6.13.1 ou maior**. Se vier menor, rode o passo 2 de novo.
- `"chave_ok": true` e `chave.bin` = `True`: tudo certo. A cópia da chave já está guardada.
- `"chave_ok": false` com `"sem chave"`: a chave já tinha sumido antes da atualização. O Seaninho abre pedindo a
  chave: diga para a pessoa colar a dela na janela do Seaninho (se não tiver mais, criar uma em
  https://ai-portal.seazone.com.br › Nova key). Depois rode este passo de novo; `chave.bin` passa a existir.
- `chave.bin` = `False` com `"chave_ok": true`: o Seaninho ainda está abrindo. Espere 10 segundos e confira de
  novo.

### 4. Fim

Diga à pessoa:
- O Seaninho Pro está atualizado e daqui em diante se atualiza sozinho toda vez que abre.
- Se ele pedir a chave de novo depois de reiniciar, avise o Arthur e mande o arquivo
  `%APPDATA%\SeaninhoPro\seaninho.log`. A versão nova anota ali por que a chave faltou.
