# Fase P.1 — Gestão de equipe pela interface: passo a passo

Agora cadastrar e promover alguém é só dentro da Central — não precisa mais abrir o SQL Editor no dia a
dia. Faltam 2 passos de uma vez só (parecido com o que você já fez na Fase P).

## Passo 1 — Rodar o SQL novo

1. Abra `https://supabase.com/dashboard/project/vlwrjidrlsfizdxfsyea/sql/new`
2. Abra o arquivo **`SUPABASE_FASE_P1_EQUIPE_UI.sql`**, copie tudo, cole, clique em **Run**.

Isso adiciona o e-mail em `profiles` (pra você ver quem é quem na tela), e dá permissão pra um admin ler a
equipe inteira e trocar a função de qualquer um pelo dropdown, direto na tela.

## Passo 2 — Publicar a Edge Function nova

Essa é a peça que de fato cria o login (só o servidor consegue fazer isso, por segurança).

1. Em **Edge Functions**, clique em **"Deploy a new function"** / **"Create a new function"**.
2. Nome da function: `admin-create-team-member` (exatamente assim, minúsculo com hífen).
3. Abra o arquivo **`supabase/functions/admin-create-team-member/index.ts`**, copie tudo, cole no editor.
4. Clique em **Deploy**.

Não precisa configurar nenhum secret novo — essa function usa as mesmas credenciais que o Supabase já
disponibiliza automaticamente pra toda function do projeto (mesma coisa que já acontecia com a `send-push`).

**Dica pra colar sem cortar** (aconteceu da última vez): copie o arquivo abrindo ele direto na pasta do
projeto (Finder/VS Code), não do chat — e depois de colar, role até o final do editor pra confirmar que a
última linha é `});`, fechando o `Deno.serve`.

---

## Como usar

1. Vá em **Admin → Equipe** (novo item na sidebar).
2. Clique em **"+ Novo membro"**: preencha nome, e-mail, uma senha provisória (já vem uma gerada, pode usar
   ou trocar), e a função (Admin/Vendedor/Membro).
3. Clique em **"Criar login"**. Vai aparecer a senha de novo, uma última vez — copie e manda pra pessoa
   (WhatsApp, o que for). Ela pode entrar com essa senha **ou com o Google**, tanto faz — o Supabase já
   reconhece como a mesma conta automaticamente, desde que ela use **exatamente o mesmo e-mail** que você
   digitou aqui. Só e-mail diferente é que cria uma conta separada, sem função nenhuma.
4. Pra trocar a função de alguém depois (inclusive rebaixar, se quiser tirar o acesso), é só clicar no
   badge de função na lista e escolher outra — não precisa recriar nada.

Zero SQL no dia a dia a partir de agora — só nesses 2 passos de hoje.
