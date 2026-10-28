# Instalar o Seaninho com o Claude

Este arquivo é para o **Claude** (Claude Code ou o app do Claude no computador) seguir. A pessoa só precisa colar
no Claude:

> Instale o Seaninho para mim seguindo https://raw.githubusercontent.com/seazone-tech/seaninho-transcritor-dist/main/INSTALAR_COM_CLAUDE.md

---

## Para o Claude

Você vai instalar o Seaninho no Windows desta pessoa, do jeito mais fácil para ela: você roda os comandos, e ela
só cola a chave na janela do Seaninho e autoriza as contas (Gmail, Agenda...) no Composio, pelo navegador. Fale com ela em português, em frases curtas,
e diga o que está fazendo a cada passo. Nada aqui precisa de administrador.

**Regras:**
- **Nunca peça a chave de API no chat** e nunca a digite. O Seaninho abre a própria janela para a pessoa colar.
- Não clique em telas de autorização (Google, AI Portal, Nekt) pela pessoa: abra a página e diga onde clicar.
- Rode os comandos no PowerShell. Cada comando do Seaninho grava o resultado em JSON; leia o arquivo para decidir
  o próximo passo.

### 1. Básico ou Pro?

Pergunte qual ela quer (se ela já disse, não pergunte de novo):

- **Seaninho Transcritor (básico):** só o ditado. Segura `Ctrl+Alt`, fala, solta, e o texto aparece onde está o
  cursor, já corrigido.
- **Seaninho Pro:** o ditado e mais um assistente de voz: agenda e lembretes de reunião, e-mails, Google Drive e
  planilhas, Slack, anotações e lembretes, pausas de saúde, histórico de cópias e prints, "responde essa
  conversa", pesquisa rápida e os dados da Seazone (tarefas do Taskdex, números do Nekt, base de conhecimento).

### 2. Instalar

Básico:

```powershell
$env:SEANINHO_VERSAO = "basico"; irm https://raw.githubusercontent.com/seazone-tech/seaninho-transcritor-dist/main/install.ps1 | iex
```

Pronto: o básico pede a chave sozinho na primeira abertura. Explique como usar (`Ctrl+Alt`) e termine aqui.

Pro (não abre o app no fim, porque você configura antes):

```powershell
$env:SEANINHO_VERSAO = "pro"; $env:SEANINHO_PRO_NO_START = "1"; irm https://raw.githubusercontent.com/seazone-tech/seaninho-transcritor-dist/main/install.ps1 | iex
```

Se o básico já estiver instalado, o instalador pergunta numa janela se troca pelo Pro (a chave, o dicionário e o
histórico vêm junto). Para não perguntar, antes defina `$env:SEANINHO_PRO_REPLACE = "sim"` (troca) ou `"nao"`
(mantém os dois). Na dúvida, pergunte à pessoa: o recomendado é trocar, porque os dois usam `Ctrl+Alt`.

Se o Windows SmartScreen avisar ao abrir, ela clica em "Mais informações" › "Executar assim mesmo" (o executável
não é assinado).

Nos passos seguintes:

```powershell
$exe = "$env:LOCALAPPDATA\Programs\SeaninhoPro\SeaninhoPro.exe"
$out = "$env:TEMP\seaninho-pro-setup.json"
```

### 3. Chave e nome

Se `%APPDATA%\SeaninhoPro\.env` já existe (veio do básico), pule para o passo 4: o `--verificar` do passo 5 diz se
a chave funciona.

Diga à pessoa: "Vai abrir uma janela do Seaninho pedindo sua chave de IA da Seazone. Se você ainda não tem uma,
crie em https://ai-portal.seazone.com.br (Nova key) e cole na janela." Se ela não tiver chave, abra o
portal para ela (`Start-Process https://ai-portal.seazone.com.br/dashboard/nova-key`).

Se souber o nome dela (git config, e-mail), passe em `SEANINHO_NOME` para a janela não perguntar:

```powershell
$env:SEANINHO_NOME = "Nome Sobrenome"
Start-Process $exe -ArgumentList "--configurar", "--saida", "`"$out`"" -Wait
Get-Content $out -Encoding UTF8
```

`"ok": true` = chave salva e testada. `"ok": false` mostra o motivo em `erro` ("A pessoa fechou a janela da
chave", "chave recusada"): explique e rode de novo.

### 4. Contas pelo Composio (Gmail, Agenda, Drive, Tarefas, Slack)

O Seaninho usa as contas que a pessoa conecta no **Composio** (o mesmo que o Claude usa), com a chave da Seazone:
não tem login do Google no app. Diga antes: "Vou abrir uma aba para cada conta que falta. Em cada uma, escolha sua
conta @seazone.com.br e clique em permitir."

```powershell
Start-Process $exe -ArgumentList "--conectar-google", "--saida", "`"$out`"" -Wait
Get-Content $out -Encoding UTF8
```

- `"ok": true`: tudo conectado (`conectadas` lista as contas).
- `"ok": false` com `abri_no_navegador`: essas abas foram abertas, cada uma com o link direto do Composio. Espere a
  pessoa autorizar todas e rode o comando de novo para conferir. Se um link não abrir, mande ela em `portal`
  (AI Portal › MCPs › Hub MCP › Suas contas) e diga para clicar em **Conectar** na linha do Composio.
- `"ok": false` com `erro`: o Hub não respondeu; confira a chave (passo 3).

Se ela não quiser conectar alguma conta, tudo bem: o ditado e o resto funcionam sem elas, e o próprio Seaninho
avisa com o botão **Conectar** quando ela pedir algo que precise da conta.

### 5. Conferir e dados da Seazone (Nekt)

```powershell
Start-Process $exe -ArgumentList "--verificar", "--saida", "`"$out`"" -Wait
Get-Content $out -Encoding UTF8
```

- `chave_ok`: a chave funciona no hub.seazone.dev.
- `google.conectado` e `google.contas_faltando` (contas do Composio que ainda faltam).
- `hub.sistemas`: sistemas da Seazone que ela consegue consultar por voz com a própria chave (Taskdex, base de
  conhecimento, Reservas, Data Lake, Grafana...).
- `hub.nekt` = false: o Nekt pede uma autorização pessoal, uma vez só. Ofereça (é opcional): abra
  `hub.portal` (`Start-Process` com o endereço) e diga: "Na seção **Suas contas**, clique em **Conectar** só na
  linha do **Nekt**, confirme a conta Google e escolha um token do Nekt (o ideal é criar um só para isso no Nekt:
  Integrations › MCP Server › Manage tokens › Create token)." Depois rode o `--verificar` de novo.

### 6. Abrir e ensinar

```powershell
Start-Process $exe
```

Diga, em poucas linhas:
- **Ditado:** segure `Ctrl+Alt`, fale e solte. O texto sai limpo e pontuado; o `Ctrl+Alt` só dita, nunca vira
  comando.
- **Assistente (com Shift):** segure `Ctrl+Shift+Alt` e peça: "qual minha próxima reunião?", "me lembra de ligar pro
  cliente daqui a pouco", "tenho e-mail importante?", "abre a planilha de…", "minhas tarefas no Taskdex",
  "vê essa conversa e responde", "abre minha saúde", "abre a conversa com a Marina no WhatsApp". Se o pedido for um
  texto ("escreve um e-mail agradecendo a reunião"), ele escreve a mensagem pronta (modo Scribe).
- **Janelas:** `Ctrl+Alt+S` Saúde, `Ctrl+Alt+N` Anotações, `Ctrl+Alt+V` cópias e prints, `Ctrl+Alt+A`
  Atualizações (avisos que passaram). Quem usa o Claude Code: `Ctrl+Alt+C` Monitor Claude e `Ctrl+Alt+L` Conta do
  Claude.
- **Painel:** clique no ícone da Seazone perto do relógio. O Início tem um botão para cada janela.

Se algo falhar, o registro fica em `%APPDATA%\SeaninhoPro\seaninho.log`.
