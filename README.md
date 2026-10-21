# Seaninho Transcritor — distribuição

Binários do **Seaninho Transcritor**, o app de ditado por voz da Seazone para Windows: segure
`Ctrl+Alt`, fale, solte, e o texto aparece pronto onde o cursor estiver.

O código-fonte fica no repositório privado `seazone-tech/seaninho-transcritor`. Aqui ficam só
os executáveis publicados, para que qualquer pessoa baixe sem precisar de login.

## Instalar

Peça ao Claude (Claude Code ou o app do Claude no computador):

> Instale o Seaninho Transcritor para mim rodando no PowerShell: `irm https://raw.githubusercontent.com/seazone-tech/seaninho-transcritor-dist/main/install.ps1 | iex`

Ou rode você mesmo esse comando no PowerShell. Ele:

1. baixa o `SeaninhoTranscritor.exe` da [última release](../../releases/latest) para `%LOCALAPPDATA%\Programs\SeaninhoTranscritor`;
2. cria o atalho no Menu Iniciar e liga "Iniciar com o Windows";
3. abre o app.

Na primeira abertura o Seaninho Transcritor pede **sua chave de IA da Seazone** (ai-portal >
chaves de API, começa com `sk-`). Cada pessoa usa a própria chave.

Para atualizar, rode o mesmo comando de novo. Seu dicionário, histórico e
configuração ficam em `%APPDATA%\SeaninhoTranscritor` e não são apagados.

## Para o Claude que for instalar

- Rode o comando acima no PowerShell do usuário (não precisa de administrador).
- Não peça nem digite a chave de API pelo usuário: o próprio app pede na primeira abertura.
- Se o Windows SmartScreen avisar, o usuário clica em "Mais informações" > "Executar assim mesmo" (o executável não é assinado).
