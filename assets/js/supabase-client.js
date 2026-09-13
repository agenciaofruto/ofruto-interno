/* supabase-client.js — fonte única das credenciais e do client Supabase.
   Usado por index.html (app interno) e proposta.html (página pública).
   Requer que o script do supabase-js (CDN) seja carregado ANTES deste arquivo. */

const SUPABASE_URL = 'https://vlwrjidrlsfizdxfsye.supabase.co';
const SUPABASE_KEY = 'sb_publishable_REMINpQNTezds4hWd7AOXQ_kTNBJoiu';

const sb = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
