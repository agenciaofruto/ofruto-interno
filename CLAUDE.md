# CLAUDE.md — Central oFruto

Manual permanente deste projeto. Leia antes de fazer qualquer alteração.

## O que é este projeto

**Central oFruto** é o sistema interno da oFruto — um app de uso da própria agência (não é o site institucional público, que vive em outro diretório fora deste repositório).

## Stack e arquitetura

- **HTML, CSS e JavaScript vanilla puro.** Sem framework (React, Vue, etc.) e sem build step (sem bundler, sem transpilador, sem npm/package.json).
- **`index.html` é o arquivo principal e único da aplicação.** HTML, CSS (`<style>`) e JS (`<script>`) vivem todos inline nesse arquivo.
- Dados de negócio (serviços, metodologia, filtros) ficam embutidos num `<script id="data" type="application/json">` dentro do próprio `index.html`.
- Não introduzir framework, bundler ou dependência de build sem alinhar antes — o projeto é intencionalmente simples e roda direto como arquivo estático.

## Supabase

- O Supabase já está integrado (client `@supabase/supabase-js@2` via CDN) e é usado hoje para **persistir as propostas comerciais**.
- **Tabela principal em uso: `propostas`.** CRUD feito através de `dbSalvar`, `dbAtualizar`, `dbExcluir`, `dbCarregar`.
- A chave usada no frontend é a **chave publicável (`anon`/`publishable`)** — isso é esperado e aceitável para este tipo de chave.
- **Nunca expor, criar ou sugerir uso de `service_role key` no frontend.** Essa chave dá acesso irrestrito ao banco e jamais deve aparecer em código client-side.
- **Não alterar credenciais existentes do Supabase (URL, chave, nomes de tabela) sem autorização explícita do usuário.**

## Git / GitHub / Deploy

- O projeto está versionado em Git e conectado a um repositório no GitHub (`origin`, branch `main`).
- A publicação de produção é feita pela **Vercel**, integrada diretamente ao GitHub — ou seja, mudanças no branch de produção podem ir ao ar automaticamente.
- **Nunca executar `git commit`, `git push` ou qualquer ação de publicação/deploy sem pedir autorização ao usuário primeiro.** Isso vale mesmo para mudanças pequenas.

## Como trabalhar neste projeto

1. **Antes de alterar qualquer funcionalidade existente**, analisar como ela funciona hoje no `index.html` (ler o trecho relevante de HTML/CSS/JS antes de editar).
2. **Preservar funcionalidades existentes** ao implementar novas — uma nova feature não pode quebrar o que já funciona (views, tabbar, gerador de propostas, integração Supabase, etc.).
3. **Evitar duplicar funções, variáveis ou blocos de código.** Antes de criar algo novo, verificar se já existe uma função ou variável equivalente no arquivo (ex.: helpers como `esc()`, `nl2br()`, `fill()`, `$`, `$$`).
4. Fazer alterações **de forma incremental e organizada** — mudanças pequenas e revisáveis em vez de reescritas grandes de uma vez.
5. **Depois de cada alteração importante, verificar se não há erros de JavaScript ou HTML** (sintaxe, tags não fechadas, funções quebradas, erros de console) antes de considerar a tarefa concluída.
6. Como é um arquivo único e grande, ao editar preferir mudanças cirúrgicas (edição pontual) a reescrever seções inteiras sem necessidade.
