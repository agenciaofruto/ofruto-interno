# Fase P.2 — Nível "Gerente" + campo "Cargo": passo a passo

Mesmos 2 passos de sempre — já testei a interface inteira simulando os dois papéis (admin e gerente), só
falta aplicar no Supabase.

## Passo 1 — Rodar o SQL novo

1. Abra `https://supabase.com/dashboard/project/vlwrjidrlsfizdxfsyea/sql/new`
2. Abra o arquivo **`SUPABASE_FASE_P2_GERENTE.sql`**, copie tudo, cole, clique em **Run**.

Isso adiciona o campo `cargo` (texto livre) em `profiles`, libera `gerente` como função válida, e ajusta a
trava do banco: um gerente consegue gerenciar a equipe, mas **nunca** consegue criar nem mexer numa conta
admin (nem pelo dropdown, nem por fora da tela) — isso é reforçado no banco, não só escondido na tela.

## Passo 2 — Atualizar a Edge Function `admin-create-team-member`

O código dela mudou (agora aceita gerente como quem cadastra, e bloqueia promoção a admin por quem não é
admin). Precisa republicar:

1. Vá em **Edge Functions → admin-create-team-member**.
2. Abra o arquivo **`supabase/functions/admin-create-team-member/index.ts`** direto da pasta do projeto
   (não do chat — evita cortar o conteúdo, como já aconteceu antes).
3. Cole substituindo tudo, confira que a última linha é `});`, clique em **Deploy**.

---

## O que muda pra você usar

- Ao cadastrar alguém em **Equipe → + Novo membro**, agora tem um campo **Cargo** (opcional, texto livre —
  "Social Media", "Sócia", o que fizer sentido) e a função **Gerente** aparece como opção.
- Gerente consegue: acessar a tela Equipe, cadastrar gente nova, trocar a função de qualquer um entre
  Gerente/Vendedor/Membro. Fora isso, hoje ele só vê o Início (igual Vendedor/Membro) — o acesso dele à
  parte operacional entra quando você trouxer os detalhes dessa base.
- Ninguém além de você (admin) consegue criar ou editar uma conta Admin — nem pela tela, nem por fora dela.

**Ainda fora de escopo** (você mencionou, mas não entra agora): acesso do Social Media à base operacional
(depende dela existir), e arquivar/editar/excluir pessoas dentro do módulo "Pessoas" — me avise quando
quiser que eu trate isso também.
