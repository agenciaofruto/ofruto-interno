-- ============================================================================
-- Fase O + Fase P — estende o alerta automático diário (Fase N4) pra também avisar
-- sobre leads do CRM com "próxima ação" marcada pra hoje, não só Financeiro — e, com
-- a Fase P, manda cada assunto só pra quem deveria ver: o resumo financeiro só pra
-- admin, o resumo de CRM só pra vendedor (administradores recebem os dois sempre,
-- isso é decidido dentro da própria Edge Function send-push, não aqui).
-- Reaproveita a mesma Edge Function send-push, já publicada — não cria nada
-- novo no Supabase além desta função.
--
-- Pré-requisito: já ter rodado SUPABASE_CRON_ALERTAS_PUSH.sql e
-- SUPABASE_FASE_P_CONTAS_EQUIPE.sql antes (esta função depende da tabela `profiles`
-- existir, indiretamente, através da Edge Function).
-- ANTES DE RODAR: troque <COLE_AQUI_A_SERVICE_ROLE_KEY> pela sua service_role
-- key de verdade (Project Settings → API), só dentro da caixa do SQL Editor
-- (não salve essa troca de volta no arquivo do projeto).
--
-- Se você já rodou a versão antiga deste arquivo (sem separação por função), pode
-- rodar esta de novo sem problema — é um CREATE OR REPLACE, substitui a anterior.
--
-- Rode isso no SQL Editor do Supabase.
-- ============================================================================

create or replace function public.verificar_alertas_financeiros()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_receber_mod uuid;
  v_pagar_mod uuid;
  v_hoje text := to_char(now(), 'YYYY-MM-DD');
  v_qtd int;
  v_total numeric;
  v_qtd_leads int;
begin
  select id into v_receber_mod from modules where name = 'Contas a Receber' limit 1;
  select id into v_pagar_mod from modules where name = 'Contas a Pagar' limit 1;

  v_qtd := 0;
  v_total := 0;
  if v_receber_mod is not null and v_pagar_mod is not null then
    select count(*), coalesce(sum((data->>'valor')::numeric), 0)
      into v_qtd, v_total
    from records
    where (
        (module_id = v_receber_mod and data->>'status' = 'a_receber')
        or (module_id = v_pagar_mod and data->>'status' = 'a_pagar')
      )
      and data->>'data_vencimento' = v_hoje;
  end if;

  -- leads de qualquer funil do CRM com próxima ação marcada pra hoje.
  select count(*) into v_qtd_leads
  from records r
  join modules m on m.id = r.module_id
  where m.kind = 'funil'
    and r.data->>'proxima_acao' is not null
    and r.data->>'proxima_acao_data' = v_hoje;

  -- Financeiro: só pra quem é admin.
  if v_qtd > 0 then
    perform net.http_post(
      url := 'https://vlwrjidrlsfizdxfsyea.supabase.co/functions/v1/send-push',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer <COLE_AQUI_A_SERVICE_ROLE_KEY>'
      ),
      body := jsonb_build_object(
        'title', 'Hoje na Central oFruto',
        'body', v_qtd || ' conta(s) financeira(s) vencendo (R$ ' || to_char(v_total, 'FM999G999G999D00') || '). Toque pra ver.',
        'url', '/index.html',
        'roles', jsonb_build_array('admin')
      )
    );
  end if;

  -- CRM: só pra quem é vendedor (admin recebe de todo jeito, por regra da própria function).
  if v_qtd_leads > 0 then
    perform net.http_post(
      url := 'https://vlwrjidrlsfizdxfsyea.supabase.co/functions/v1/send-push',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer <COLE_AQUI_A_SERVICE_ROLE_KEY>'
      ),
      body := jsonb_build_object(
        'title', 'Hoje na Central oFruto',
        'body', v_qtd_leads || ' próxima(s) ação(ões) do CRM. Toque pra ver.',
        'url', '/index.html',
        'roles', jsonb_build_array('vendedor')
      )
    );
  end if;
end;
$$;

-- O agendamento (cron.schedule) já existe desde a Fase N4 e continua valendo — como só trocamos
-- o conteúdo da função (CREATE OR REPLACE), não precisa recriar o job. Pra testar na hora:
-- select public.verificar_alertas_financeiros();
