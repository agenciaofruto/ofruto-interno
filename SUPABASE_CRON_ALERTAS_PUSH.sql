-- ============================================================================
-- Fase N (N4) — depois que a tabela push_subscriptions existir (rode
-- SUPABASE_PUSH_NOTIFICATIONS.sql antes) e a Edge Function send-push estiver
-- publicada (ver FASE_N_NOTIFICACOES_PUSH.md), este SQL faz o banco avisar
-- sozinho, todo dia, quando tiver conta vencendo hoje — sem precisar abrir a Central.
--
-- ANTES DE RODAR: troque <COLE_AQUI_A_SERVICE_ROLE_KEY> pela sua service_role
-- key de verdade (Dashboard do Supabase → Project Settings → API → service_role).
-- Essa chave só fica guardada aqui dentro do banco (numa function seguida por
-- `security definer`, ninguém de fora consegue ler o código/os secrets dela) —
-- é o mesmo nível de confiança que qualquer SQL que você roda direto no projeto.
-- NUNCA cole essa chave em nenhum arquivo do index.html/frontend.
--
-- Rode isso uma vez no SQL Editor do Supabase.
-- ============================================================================

create extension if not exists pg_net;

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
  v_titulo text;
  v_corpo text;
begin
  select id into v_receber_mod from modules where name = 'Contas a Receber' limit 1;
  select id into v_pagar_mod from modules where name = 'Contas a Pagar' limit 1;
  if v_receber_mod is null or v_pagar_mod is null then
    return;
  end if;

  select count(*), coalesce(sum((data->>'valor')::numeric), 0)
    into v_qtd, v_total
  from records
  where (
      (module_id = v_receber_mod and data->>'status' = 'a_receber')
      or (module_id = v_pagar_mod and data->>'status' = 'a_pagar')
    )
    and data->>'data_vencimento' = v_hoje;

  if v_qtd = 0 then
    return;
  end if;

  v_titulo := 'Financeiro: ' || v_qtd || ' conta(s) vencem hoje';
  v_corpo := 'Total de R$ ' || to_char(v_total, 'FM999G999G999D00') || ' vencendo hoje. Toque pra ver no Financeiro.';

  perform net.http_post(
    url := 'https://vlwrjidrlsfizdxfsyea.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer <COLE_AQUI_A_SERVICE_ROLE_KEY>'
    ),
    body := jsonb_build_object('title', v_titulo, 'body', v_corpo, 'url', '/index.html')
  );
end;
$$;

-- Roda 5 minutos depois da geração das cobranças recorrentes (Fase J.2, 9h UTC),
-- pra já considerar as contas que acabaram de ser criadas nesse mesmo dia.
select cron.schedule(
  'verificar-alertas-financeiros-diario',
  '5 9 * * *',
  $$select public.verificar_alertas_financeiros();$$
);

-- Pra testar na hora, sem esperar o agendamento:
-- select public.verificar_alertas_financeiros();

-- Pra cancelar no futuro:
-- select cron.unschedule('verificar-alertas-financeiros-diario');
