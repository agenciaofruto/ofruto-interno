-- ============================================================================
-- Fase Q2 — Aprovação do cliente: 3 funções RPC (mesmo padrão já usado por
-- `get_proposta_publica`, que o proposta.html já usa) — são a ÚNICA porta de
-- entrada pro `anon` (chave pública, sem login). A chave anon NUNCA recebe
-- GRANT direto em `records`/`modules` — só executa estas 3 funções, cada uma
-- devolvendo/aceitando exatamente o que precisa, revalidando o token sempre.
--
-- Pré-requisito: já ter rodado as SQLs da Fase P e Q1.
-- Rode isso inteiro no SQL Editor do Supabase, de uma vez.
-- ============================================================================

-- 1. Dados básicos do cliente (nome/empresa), pra tela pública saudar certo.
create or replace function public.get_cliente_publico(p_token text)
returns table(id uuid, nome text, empresa text)
language sql
security definer
stable
set search_path = public
as $$
  select r.id, r.data->>'nome' as nome, r.data->>'empresa' as empresa
  from records r
  join modules m on m.id = r.module_id
  where m.name = 'Clientes' and r.data->>'token' = p_token
  limit 1;
$$;

-- 2. Projetos (não arquivados) + conteúdos de cada um, só os campos que o
--    cliente precisa ver (nunca briefing/roteiro/responsavel/etapa interna).
--    Antes de montar a resposta, auto-aprova qualquer conteúdo "pendente" cujo
--    projeto já passou do prazo (mesma regra simples do Selo Br — sem cron
--    novo, só reavalia toda vez que alguém abre o link).
create or replace function public.get_conteudos_publicos(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cliente_id uuid;
  v_hoje date := current_date;
  v_result jsonb;
begin
  select r.id into v_cliente_id
  from records r join modules m on m.id = r.module_id
  where m.name = 'Clientes' and r.data->>'token' = p_token
  limit 1;

  if v_cliente_id is null then
    return null;
  end if;

  update records c
  set data = c.data || jsonb_build_object('status_aprovacao', 'aprovado')
  where c.module_id = (select id from modules where name = 'Conteúdos')
    and coalesce(c.data->>'status_aprovacao','pendente') = 'pendente'
    and exists (
      select 1 from records p
      where p.id = (c.data->>'projeto_id')::uuid
        and p.module_id = (select id from modules where name = 'Projetos de Conteúdo')
        and p.data->>'cliente_id' = v_cliente_id::text
        and p.data->>'deadline' is not null
        and (p.data->>'deadline')::date < v_hoje
    );

  select jsonb_agg(proj order by proj_created desc) into v_result
  from (
    select p.created_at as proj_created, jsonb_build_object(
      'id', p.id,
      'nome', p.data->>'nome',
      'tipo', p.data->>'tipo',
      'conteudos', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', c.id,
          'titulo', c.data->>'titulo',
          'embed', c.data->>'embed',
          'legenda', c.data->>'legenda',
          'data_publicacao', c.data->>'data_publicacao',
          'status_aprovacao', coalesce(c.data->>'status_aprovacao','pendente'),
          'ajuste_texto', c.data->>'ajuste_texto'
        ) order by c.created_at), '[]'::jsonb)
        from records c
        where c.module_id = (select id from modules where name = 'Conteúdos')
          and c.data->>'projeto_id' = p.id::text
      )
    ) as proj
    from records p
    where p.module_id = (select id from modules where name = 'Projetos de Conteúdo')
      and p.data->>'cliente_id' = v_cliente_id::text
      and coalesce((p.data->>'arquivado')::boolean, false) = false
  ) sub;

  return jsonb_build_object('cliente_id', v_cliente_id, 'projetos', coalesce(v_result, '[]'::jsonb));
end;
$$;

-- 3. Único jeito de escrever vindo de fora — revalida a cadeia token → cliente
--    → projeto → conteúdo antes de aceitar qualquer mudança, e só mexe em
--    status_aprovacao/ajuste_texto, nada mais.
create or replace function public.atualizar_aprovacao_conteudo(
  p_token text, p_conteudo_id uuid, p_status text, p_ajuste_texto text default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cliente_id uuid;
  v_rows int;
begin
  if p_status not in ('pendente','aprovado','reprovado','ajustes') then
    return false;
  end if;

  select r.id into v_cliente_id
  from records r join modules m on m.id = r.module_id
  where m.name = 'Clientes' and r.data->>'token' = p_token
  limit 1;

  if v_cliente_id is null then
    return false;
  end if;

  update records c
  set data = c.data
    || jsonb_build_object('status_aprovacao', p_status)
    || case when p_status = 'ajustes' then jsonb_build_object('ajuste_texto', coalesce(p_ajuste_texto,'')) else '{}'::jsonb end
  where c.id = p_conteudo_id
    and c.module_id = (select id from modules where name = 'Conteúdos')
    and exists (
      select 1 from records p
      where p.id = (c.data->>'projeto_id')::uuid
        and p.module_id = (select id from modules where name = 'Projetos de Conteúdo')
        and p.data->>'cliente_id' = v_cliente_id::text
    );

  get diagnostics v_rows = row_count;
  return v_rows > 0;
end;
$$;

-- 4. Só EXECUTE nas 3 funções — nunca GRANT direto nas tabelas pro anon.
grant execute on function public.get_cliente_publico(text) to anon, authenticated;
grant execute on function public.get_conteudos_publicos(text) to anon, authenticated;
grant execute on function public.atualizar_aprovacao_conteudo(text, uuid, text, text) to anon, authenticated;
