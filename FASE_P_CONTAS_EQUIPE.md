# Fase P — Contas de equipe: passo a passo

O código já está pronto e testado (simulei as funções `admin`/`vendedor` no navegador pra confirmar que
sidebar, tabbar, atalhos do Início e o bloqueio de navegação funcionam certinho). Faltam 3 coisas que só
você consegue fazer, porque exigem o painel do Supabase.

**IMPORTANTE — ordem importa**: a partir do momento em que você rodar o Passo 1, qualquer login sem uma
função (`role`) cadastrada em `profiles` passa a ter o acesso mais restrito (`membro`, só vê Início) — tanto
na interface quanto no banco de dados de verdade. O arquivo SQL já inclui um passo que te dá (admin) de
volta automaticamente, usando seu e-mail — não pule esse pedaço.

---

## Passo 1 — Rodar o SQL da Fase P

1. Abra o SQL Editor do seu projeto: `https://supabase.com/dashboard/project/vlwrjidrlsfizdxfsyea/sql/new`
2. Abra o arquivo **`SUPABASE_FASE_P_CONTAS_EQUIPE.sql`** (pasta do projeto), copie tudo, cole no editor.
3. **Confira a seção 6, perto do final do arquivo**: tem um `insert into public.profiles ... where email =
   'davimourx@gmail.com'`. Se você loga na Central com esse e-mail (Google ou e-mail/senha), está certo,
   não precisa mudar nada. Se usa outro e-mail pra logar, troque antes de rodar.
4. Clique em **Run**. Deve aparecer "Success" no final.
5. Pra confirmar que você virou admin de verdade, rode isso numa nova query:
   ```sql
   select u.email, p.role from public.profiles p join auth.users u on u.id = p.id;
   ```
   Deve aparecer uma linha com seu e-mail e `role = admin`.

O que esse SQL cria: tabela `profiles` (função de cada login), a trava de verdade no banco (RLS) pra
`modules`/`fields`/`records`/`statuses` baseada na função, e marca os funis de CRM que já existem como
visíveis pra função `vendedor`.

## Passo 2 — Atualizar a Edge Function `send-push`

A function já publicada (Fase N) precisa da versão nova do código, que sabe filtrar notificação por função.

1. Vá em **Edge Functions → send-push** no painel do Supabase.
2. Abra o arquivo **`supabase/functions/send-push/index.ts`** (pasta do projeto), copie tudo.
3. Cole no editor da function (substitua o conteúdo todo), clique em **Deploy**.

Sem isso, a Central continua mandando notificação pra todo mundo sempre (comportamento de antes) — não
quebra nada, só não aplica o filtro por função ainda.

## Passo 3 (opcional) — Atualizar o alerta automático do CRM

Se você já rodou o `SUPABASE_CRON_ALERTAS_CRM.sql` antes (versão antiga, que juntava financeiro e CRM numa
notificação só), rode o arquivo de novo — ele foi atualizado pra mandar duas notificações separadas: o
resumo financeiro só pra quem é `admin`, o resumo de CRM só pra quem é `vendedor` (administradores recebem
os dois, sempre). Se você nunca rodou esse arquivo, pode rodar agora (ele já está na versão nova).

---

## Quando for cadastrar seu vendedor (ou qualquer conta nova)

1. **Authentication → Users → Add user** (mesmo lugar de sempre), crie o login dele (e-mail/senha, ou ele
   usa Google na primeira vez que acessar — nesse caso crie com um e-mail placeholder e oriente ele a usar
   "Esqueci a senha" ou entre direto com o Google, o Supabase casa pelo e-mail).
2. Assim que a conta existe, ela já ganha uma linha em `profiles` sozinha (função `membro`, só vê Início —
   é o trigger criado no Passo 1). Promova ele rodando, no SQL Editor:
   ```sql
   update public.profiles set role = 'vendedor'
   where id = (select id from auth.users where email = 'email-da-pessoa@exemplo.com');
   ```
3. Pronto. Na próxima vez que ele logar, já vê só Início/CRM/Propostas/Serviços — no menu e também se tentar
   acessar qualquer outra coisa direto (bloqueado de verdade, não só escondido).

## O que eu não consigo testar sozinho

Criar uma conta de teste de verdade no Supabase é uma ação fora do meu alcance (mesma regra que já vale a
sessão inteira — não crio contas em painéis de terceiros). Então o teste final — logar como um vendedor de
teste num navegador diferente (ou anônimo) e confirmar que ele só vê CRM/Propostas/Serviços, e que tentar
abrir Clientes ou Financeiro é bloqueado de verdade (não só escondido) — precisa ser feito por você. Se
quiser, crie uma conta de teste, me avise o resultado, e eu ajudo a investigar qualquer coisa que não bata.
