// Fase P.1 — Edge Function que cria o login de um novo membro da equipe.
// Roda no servidor do Supabase (Deno) porque criar conta (auth.users) exige a
// Admin API, que só funciona com a service_role key — isso nunca pode rodar
// no navegador (mesma regra de sempre: service_role key nunca no frontend).
//
// Chamada pela tela "Equipe" (Admin), autenticada com a sessão de quem está
// logado. Antes de criar qualquer coisa, confirma que quem chamou é admin de
// verdade (consultando `profiles` com o token de quem chamou, respeitando a
// RLS normal) — sem essa checagem, qualquer login autenticado poderia chamar
// esta function direto (sem passar pela tela) e criar contas à vontade.
import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = "https://vlwrjidrlsfizdxfsyea.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_REMINpQNTezds4hWd7AOXQ_kTNBJoiu";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Faltou o cabeçalho de autenticação." }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Client "como quem chamou" — respeita a RLS normal, só enxerga a própria linha de profiles.
    const supabaseCaller = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user: caller } } = await supabaseCaller.auth.getUser();
    if (!caller) {
      return new Response(JSON.stringify({ error: "Sessão inválida." }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const { data: callerProfile } = await supabaseCaller.from("profiles").select("role").eq("id", caller.id).single();
    // Fase P.2: gerente também pode cadastrar gente, mas nunca como admin (checado abaixo,
    // depois de saber qual `role` foi pedido) — admin segue podendo tudo.
    if (!["admin", "gerente"].includes(callerProfile?.role)) {
      return new Response(JSON.stringify({ error: "Só administradores ou gerentes podem cadastrar membros da equipe." }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { email, password, full_name, cargo, role } = await req.json();
    if (!email || !password) {
      return new Response(JSON.stringify({ error: "E-mail e senha são obrigatórios." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (password.length < 8) {
      return new Response(JSON.stringify({ error: "A senha precisa ter pelo menos 8 caracteres." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (!["admin", "gerente", "vendedor", "membro"].includes(role)) {
      return new Response(JSON.stringify({ error: "Função inválida." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (role === "admin" && callerProfile.role !== "admin") {
      return new Response(JSON.stringify({ error: "Só administradores podem criar outra conta admin." }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Só agora, já confirmado que quem chamou é admin, usa a service_role key (secret da
    // function, nunca sai daqui) pra de fato criar o login.
    const supabaseAdmin = createClient(
      SUPABASE_URL,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: created, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: full_name ? { full_name } : undefined,
    });
    if (createError) throw createError;

    // O trigger handle_new_user() já grava a linha em profiles (role 'membro', e-mail preenchido).
    // Se a função pedida for diferente, ou tiver cargo, atualiza agora.
    if (role !== "membro" || cargo) {
      const patch: Record<string, string> = {};
      if (role !== "membro") patch.role = role;
      if (cargo) patch.cargo = cargo;
      const { error: updateError } = await supabaseAdmin
        .from("profiles")
        .update(patch)
        .eq("id", created.user.id);
      if (updateError) throw updateError;
    }

    return new Response(JSON.stringify({ id: created.user.id, email: created.user.email }), {
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
