-- ============================================================================
-- Fase N — Notificações push. Cria a tabela que guarda a "assinatura" de cada
-- aparelho que ativou notificação (celular, computador — um por dispositivo).
-- Diferente dos módulos do motor genérico (Clientes, Financeiro etc.), essa
-- tabela não cabe no padrão `modules`/`records` — é estrutura de verdade.
--
-- Rode isso uma vez no SQL Editor do Supabase.
-- ============================================================================

create table if not exists push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  created_at timestamptz default now()
);

alter table push_subscriptions enable row level security;

create policy "push_subscriptions_authenticated" on push_subscriptions
  for all to authenticated using (true) with check (true);

grant select, insert, update, delete on push_subscriptions to authenticated;
