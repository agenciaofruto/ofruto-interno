-- ============================================================================
-- Automação do Financeiro: faz o Supabase gerar sozinho a cobrança do mês de
-- cada cliente recorrente, todo dia, sem precisar que ninguém abra a Central.
--
-- Hoje isso só acontecia quando alguém abria a aba Financeiro (o navegador
-- disparava a geração). Esse SQL recria a mesma lógica dentro do banco e
-- agenda ela pra rodar sozinha via pg_cron (extensão nativa do Postgres,
-- já disponível no Supabase).
--
-- Rode isso uma vez no SQL Editor do Supabase.
-- ============================================================================

-- 1. Habilita a extensão de agendamento (se já estiver habilitada, não faz nada).
--    Se der erro de permissão aqui, habilite manualmente em:
--    Dashboard → Database → Extensions → busque "pg_cron" → Enable.
create extension if not exists pg_cron;

-- 2. Função que faz o mesmo que gerarContasRecorrentes() faz no navegador:
--    pra cada cliente ativo com valor_recorrente + dia_vencimento preenchidos,
--    cria a conta a receber do mês atual — só se ainda não existir uma
--    (mesma checagem de idempotência, pode rodar todo dia sem duplicar nada).
create or replace function public.gerar_contas_recorrentes()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_clientes_mod uuid;
  v_receber_mod uuid;
  v_mes_atual text := to_char(now(), 'YYYY-MM');
  v_hoje date := now()::date;
  r record;
  v_dia int;
  v_vencimento date;
  v_ja_existe boolean;
begin
  select id into v_clientes_mod from modules where name = 'Clientes' and section = 'Negócio' limit 1;
  select id into v_receber_mod from modules where name = 'Contas a Receber' limit 1;
  if v_clientes_mod is null or v_receber_mod is null then
    return;
  end if;

  for r in
    select * from records
    where module_id = v_clientes_mod
      and data->>'status_contrato' = 'ativo'
      and (data->>'valor_recorrente') is not null
      and (data->>'dia_vencimento') is not null
  loop
    select exists(
      select 1 from records
      where module_id = v_receber_mod
        and data->>'cliente' = r.data->>'nome'
        and (data->>'recorrente')::boolean is true
        and left(data->>'data_vencimento', 7) = v_mes_atual
    ) into v_ja_existe;

    if not v_ja_existe then
      v_dia := least(28, greatest(1, (r.data->>'dia_vencimento')::int));
      v_vencimento := to_date(v_mes_atual || '-' || lpad(v_dia::text, 2, '0'), 'YYYY-MM-DD');

      insert into records (module_id, data)
      values (
        v_receber_mod,
        jsonb_build_object(
          'cliente', r.data->>'nome',
          'projeto', null,
          'descricao', 'Cobrança recorrente mensal',
          'valor', (r.data->>'valor_recorrente')::numeric,
          'data_emissao', v_hoje::text,
          'data_vencimento', v_vencimento::text,
          'data_recebimento', null,
          'forma_pagamento', '',
          'numero_parcela', '',
          'recorrente', true,
          'status', 'a_receber',
          'observacoes', '',
          'anexo_url', ''
        )
      );
    end if;
  end loop;
end;
$$;

-- 3. Agenda a função pra rodar todo dia às 9h UTC (6h da manhã em Brasília,
--    fora do horário de verão — Brasil não usa mais horário de verão desde
--    2019, então 9h UTC = 6h Brasília o ano inteiro).
--    Rodar de manhã cedo não tem nenhum efeito prático diferente de rodar
--    à meia-noite (a cobrança do mês é a mesma o dia inteiro) — só escolhi
--    um horário "normal" de expediente.
select cron.schedule(
  'gerar-contas-recorrentes-diario',
  '0 9 * * *',
  $$select public.gerar_contas_recorrentes();$$
);

-- Pra conferir que o agendamento foi criado:
-- select * from cron.job;

-- Pra rodar manualmente agora (teste, sem esperar o agendamento):
-- select public.gerar_contas_recorrentes();

-- Pra cancelar a automação no futuro, se quiser:
-- select cron.unschedule('gerar-contas-recorrentes-diario');
