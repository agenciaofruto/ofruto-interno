# Fase N — Notificações push: guia completo, passo a passo

Tudo que eu conseguia escrever/testar sozinho já está pronto no código (manifest, service worker, tela de
"Ativar notificações" dentro de Editar Perfil, a função genérica que qualquer parte futura do sistema vai
usar pra te avisar). Faltam alguns passos dentro do painel do Supabase que só você tem acesso pra fazer.

Este guia assume que você nunca mexeu nessas telas do Supabase — vou descrever cada clique.

**Link do seu projeto**: `https://supabase.com/dashboard/project/vlwrjidrlsfizdxfsyea`

---

## Passo 1 — Rodar o SQL que cria a tabela

1. Entre no link do projeto acima (faça login se pedir).
2. No menu da esquerda (ícones verticais), clique no ícone de **SQL Editor** (parece um `</>` ou "SQL").
3. Clique em **"+ New query"** (canto superior, geralmente verde/destaque).
4. Abra o arquivo **`SUPABASE_PUSH_NOTIFICATIONS.sql`** (está na pasta do projeto, `ofruto-interno/`),
   selecione todo o conteúdo e copie.
5. Cole tudo dentro da caixa de texto do SQL Editor (onde tinha um espaço em branco pra escrever).
6. Clique em **"Run"** (botão verde, canto inferior direito, ou `Cmd+Enter`).
7. Deve aparecer "Success. No rows returned" (ou parecido) embaixo. Se aparecer algo em vermelho, me manda
   o print do erro que eu leio.

Pronto — isso criou a tabela `push_subscriptions`, que guarda quais aparelhos podem receber notificação.

---

## Passo 2 — Publicar a Edge Function `send-push`

Essa é a peça que realmente manda a notificação pro seu celular/computador — só um servidor consegue fazer
isso (nenhum site sozinho manda notificação, por segurança de todo navegador), por isso vira uma "function"
dentro do Supabase, separada do `index.html`.

1. No menu da esquerda, clique em **Edge Functions**.
2. Clique em **"Deploy a new function"** (ou **"Create a new function"** — o texto exato varia um pouco
   conforme a versão do painel).
3. Se aparecer a opção de escolher um template, procure por algo como **"Via Editor"** ou **"Create
   function"** (em branco) — não use nenhum template pronto, vamos colar nosso próprio código.
4. No campo de **nome da function**, digite exatamente: `send-push` (tudo minúsculo, com hífen).
5. Vai abrir uma área de código (um editor tipo VS Code, dentro do navegador). Apague o conteúdo de
   exemplo que já vier escrito ali.
6. Abra o arquivo **`supabase/functions/send-push/index.ts`** (está na pasta do projeto), copie tudo, e
   cole no lugar do exemplo.
7. Clique em **"Deploy function"** (ou "Deploy", botão de destaque, geralmente no canto superior direito).
8. Espere a publicação terminar — deve aparecer um status verde tipo "Deployed" ou "Active".

**Alternativa pra quem já usa a Supabase CLI no terminal**: em vez dos passos acima, dentro da pasta do
projeto, rode `supabase functions deploy send-push`. Se você não sabe o que é isso, ignore e siga pelo
Dashboard mesmo, é mais simples.

---

## Passo 3 — Configurar os 3 segredos ("Secrets") da function

Ainda dentro da tela da function `send-push` que você acabou de publicar, procure uma aba ou seção chamada
**"Secrets"** (às vezes fica em Edge Functions → Secrets, no menu, não necessariamente dentro da function
em si — se não achar dentro da function, procure "Edge Functions" → "Secrets" no menu lateral daquela
seção).

Adicione, um de cada vez (nome à esquerda, valor à direita):

| Nome do secret | Valor |
|---|---|
| `VAPID_PUBLIC_KEY` | `BOZpC1ebkIfl_ndxFpRA33EgzoBrKuwKFtYfb-esUaAZVcDp7fgYJ63Y-tmx5T1oPyTGDlBIr19_qk1nvoJVOb8` |
| `VAPID_PRIVATE_KEY` | *(já configurada como secret no Supabase — valor não repetido aqui por segurança, já que este arquivo vai pro repositório Git. Confira em Edge Functions → Secrets se precisar conferir/trocar; se precisar gerar um par novo, rode `npx web-push generate-vapid-keys` localmente.)* |
| `VAPID_SUBJECT` | `mailto:` + **o seu e-mail** (ex: `mailto:davi@ofruto.com`) |

A chave pública é segura pra ficar neste arquivo e até dentro do `index.html` (é assim que Web Push
funciona — ela só serve pra "endereçar" o navegador, nunca pra assinar nada). A privada eu já gerei e
você já configurou como secret; o `VAPID_SUBJECT` é o único que você mesmo escreve: é uma exigência do
protocolo de notificações da web, pra quem recebe poder saber quem está mandando (tipo um remetente).

**Sobre a chave privada**: ela deve existir só aqui, dentro do Supabase, como secret. Nunca vai (e nunca
vai precisar ir) pra dentro do `index.html` ou qualquer arquivo que o navegador do cliente carrega.

---

## Passo 4 (opcional, mas recomendado) — Ativar o alerta automático "vence hoje"

Depois dos 3 passos acima funcionando, esse último faz o próprio banco de dados avisar sozinho, todo dia,
quando tiver alguma conta vencendo hoje no Financeiro — sem precisar abrir a Central pra descobrir.

1. Abra o arquivo **`SUPABASE_CRON_ALERTAS_PUSH.sql`** num editor de texto (TextEdit, VS Code, o que
   tiver).
2. Ache a linha com `<COLE_AQUI_A_SERVICE_ROLE_KEY>`.
3. Pra achar sua `service_role key`: no painel do Supabase, vá em **Project Settings** (ícone de engrenagem)
   → **API**. Vai ter duas chaves listadas — uma delas chamada **`service_role`** (secreta, geralmente vem
   com um botão de "olhinho" pra revelar). Copie ela.
4. Volte pro SQL Editor do Supabase (Passo 1), abra uma nova query.
5. Cole o conteúdo do arquivo `SUPABASE_CRON_ALERTAS_PUSH.sql` **direto na caixa de texto do SQL Editor** —
   e só ali, na caixa de texto (não salve essa troca de volta no arquivo do seu computador), substitua
   `<COLE_AQUI_A_SERVICE_ROLE_KEY>` pela chave que você copiou.
6. Clique em **"Run"**.

Fazendo a substituição só dentro do SQL Editor (sem salvar no arquivo do projeto), a `service_role key`
nunca fica gravada em nenhum arquivo que possa um dia ir parar no GitHub.

---

## Dica extra: testando localmente fora do Vercel (não é obrigatório)

O site de produção já é servido certinho pelo Vercel, então isso só importa se um dia você quiser rodar o
projeto na sua própria máquina, fora do ar. Nesse caso, use `node .claude/dev-server.js` em vez de
`python3 -m http.server` — o servidor do Python fala um protocolo antigo (HTTP/1.0) que faz o Chrome
recusar registrar o service worker. O `dev-server.js` é um servidorzinho sem dependências que resolve isso.

---

## Como testar se deu tudo certo

1. Abra a Central (o site de verdade, não localhost), clique no seu avatar (canto superior direito) →
   **Editar perfil**.
2. Clique em **"Ativar notificações neste aparelho"**.
3. O navegador vai perguntar se pode mandar notificação — clique em **Permitir/Allow**.
4. O botão deve virar **"Notificações ativadas ✓"**.
5. **No iPhone**: notificação push só funciona depois de "Adicionar à Tela de Início" (Compartilhar → 
   Adicionar à Tela de Início) — é exigência da própria Apple, não é limitação nossa. **No Android/Chrome
   e no computador**, funciona direto no navegador, sem precisar instalar nada.
6. Pra mandar uma notificação de teste: com a Central aberta, abra o Console do navegador (aperte F12, ou
   botão direito → Inspecionar → aba Console) e cole:
   ```js
   enviarNotificacaoPush('Teste', 'Chegou!', '/index.html')
   ```
   e aperte Enter. Se a notificação aparecer no aparelho em alguns segundos, está tudo funcionando.

Qualquer erro/mensagem estranha no meio do caminho, me manda o print que eu te ajudo a resolver.
