// Fase N — Edge Function que efetivamente envia a notificação push.
// Roda no servidor do Supabase (Deno), nunca no navegador — é aqui, e só aqui,
// que a chave VAPID privada existe (como secret da function, nunca em código).
//
// Chamada por duas origens:
// 1. O próprio app (sb.functions.invoke('send-push', {body:{title,body,url}})),
//    autenticado com a sessão normal do Davi.
// 2. O cron job no banco (pg_net, ver SUPABASE_CRON_ALERTAS_PUSH.sql), autenticado
//    com a service_role key — só o cron, que roda dentro do próprio Supabase, guarda essa chave.
import webpush from "npm:web-push@3.6.7";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    // Checado aqui dentro (não no topo do arquivo) de propósito: se faltar secret, isso agora
    // vira um erro 500 com mensagem clara, em vez de derrubar a function inteira silenciosamente
    // (foi exatamente isso que aconteceu na primeira versão — setVapidDetails no topo do arquivo
    // com chave vazia quebrava toda chamada antes mesmo de chegar no try/catch).
    const vapidPublic = Deno.env.get("VAPID_PUBLIC_KEY");
    const vapidPrivate = Deno.env.get("VAPID_PRIVATE_KEY");
    const vapidSubject = Deno.env.get("VAPID_SUBJECT");
    if (!vapidPublic || !vapidPrivate || !vapidSubject) {
      return new Response(
        JSON.stringify({ error: "Faltam secrets VAPID_PUBLIC_KEY/VAPID_PRIVATE_KEY/VAPID_SUBJECT nesta function. Configure em Edge Functions → send-push → Secrets." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    webpush.setVapidDetails(vapidSubject, vapidPublic, vapidPrivate);

    const { title, body, url, roles } = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Fase P: `roles` (opcional) restringe o envio a quem tem uma dessas funções em `profiles`
    // — administradores sempre recebem também, mesmo fora da lista (é o comportamento pedido:
    // CRM só pra vendedor, mas quem é admin recebe tudo). Sem `roles`, manda pra todo mundo
    // (mesmo comportamento de antes da Fase P).
    let subsQuery = supabase.from("push_subscriptions").select("*");
    if (Array.isArray(roles) && roles.length > 0) {
      const { data: perfis, error: perfisError } = await supabase
        .from("profiles")
        .select("id")
        .or(`role.in.(${roles.join(",")}),role.eq.admin`);
      if (perfisError) throw perfisError;
      const ids = (perfis || []).map((p: { id: string }) => p.id);
      subsQuery = subsQuery.in("user_id", ids.length > 0 ? ids : ["00000000-0000-0000-0000-000000000000"]);
    }
    const { data: subs, error } = await subsQuery;
    if (error) throw error;

    const payload = JSON.stringify({
      title: title || "Central oFruto",
      body: body || "",
      url: url || "/",
    });

    const results = await Promise.allSettled(
      (subs || []).map((s: { endpoint: string; p256dh: string; auth: string }) =>
        webpush
          .sendNotification({ endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } }, payload)
          .catch(async (err: { statusCode?: number }) => {
            // assinatura expirada/inválida (dispositivo desconectado, notificação desativada no SO) — limpa sozinho
            if (err.statusCode === 410 || err.statusCode === 404) {
              await supabase.from("push_subscriptions").delete().eq("endpoint", s.endpoint);
            }
            throw err;
          })
      )
    );

    const enviados = results.filter((r) => r.status === "fulfilled").length;
    return new Response(JSON.stringify({ enviados, total: (subs || []).length }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : JSON.stringify(e);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
