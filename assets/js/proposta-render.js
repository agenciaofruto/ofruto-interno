/* proposta-render.js — funções puras de montagem da apresentação de uma proposta.
   Usado por index.html (preview interno, botão "Ver preview") e por proposta.html
   (página pública, lida por token). Não depende de DOM específico de nenhuma das
   duas páginas: recebe os dados da proposta (p) e o HTML do logo (logoHtml) e
   devolve strings de HTML prontas para inserir onde cada página quiser. */

/* subconjunto mínimo de DATA.servicos (id/nome/duracao/linha) necessário só para
   rotular a seção de um serviço quando ele ainda não tem molde comercial dedicado
   em MOLDES (hoje: Pomar e Marca Viva). Se o nome/duração/linha de um serviço
   mudar em DATA.servicos (dentro de index.html), atualizar aqui também. */
const SERVICOS_META = [
  { id:'plantio',    nome:'Plantio',    duracao:'4 meses', linha:'oFruto' },
  { id:'pomar',      nome:'Pomar',      duracao:'6 meses', linha:'oFruto' },
  { id:'marca-viva', nome:'Marca Viva', duracao:'5 meses', linha:'Sociedade · oFruto + Brenda' }
];

function esc(s){return String(s==null?'':s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');}
function nl2br(s){return esc(s).replace(/\n/g,'<br>');}

/* aplica lacunas [NOME] [ÁREA] [EMPRESA] etc com base nos dados do cliente */
function fill(txt,p){
  return String(txt||'')
    .replace(/\[NOME\]/g,p.nome||'[NOME]')
    .replace(/\[EMPRESA\]/g,p.empresa||'')
    .replace(/\[ÁREA\]/g,p.area||'[área]')
    .replace(/\[VALIDADE\]/g,p.validade||'—')
    .replace(/\[PAGAMENTO\]/g,p.pagamento||'—')
    .replace(/\[INÍCIO\]/g,p.inicio||'a combinar');
}

const MOLDES = { "plantio": {"capa": {"servico": "Plantio", "tagline": "A primeira safra da sua marca."}, "contexto": {"titulo": "Por que essa proposta", "texto": "Hoje, [NOME] já tem experiência, repertório e autoridade em [ÁREA]. Mas essa percepção ainda não está traduzida numa presença digital consistente.\n\nO desafio não é simplesmente produzir conteúdo. É transformar o conhecimento e a personalidade de [NOME] numa comunicação reconhecível, estratégica e sustentável."}, "objetivo": {"titulo": "O objetivo", "texto": "Estruturar a presença digital de [NOME], construir seu posicionamento e produzir uma primeira safra de conteúdo, de forma que [NOME] siga comunicando a própria marca com autonomia."}, "solucao": {"titulo": "A solução: Plantio", "texto": "O Plantio é um ciclo de quatro meses que combina estratégia de marca, produção audiovisual e acompanhamento de performance para construir a primeira base de comunicação digital.", "conceito": "Estratégia → Produção → Autonomia"}, "comofunciona": {"titulo": "Como funciona", "etapas": [{"quando": "Mês 1", "o_que": "Estratégia", "desc": "Imersão, extração e o mapa completo da marca."}, {"quando": "Meses 2 a 4", "o_que": "Produção + acompanhamento", "desc": "Roteiro, gravação, edição, calendário e leitura de performance."}, {"quando": "Final do mês 4", "o_que": "Primeira safra + autonomia", "desc": "A base pronta e você no controle pra continuar."}]}, "entregaveis": {"titulo": "Entregáveis", "grupos": [{"nome": "Estratégia", "itens": ["Imersão de 2 a 3 horas", "Mapa estratégico da marca", "Posicionamento", "Narrativa", "Tom de voz", "Direcionamento de canais e formatos"]}, {"nome": "Produção", "itens": ["2 diárias por mês", "8 vídeos por mês", "24 vídeos no ciclo", "Roteiros", "Direção", "Edição", "Calendário de postagem"]}, {"nome": "Acompanhamento", "itens": ["Análise de performance", "Ajustes para as próximas produções"]}]}, "naoinclui": {"titulo": "O que não está incluso", "itens": ["Gestão diária das redes", "Publicação dos conteúdos", "Resposta a comentários e mensagens", "Criação de identidade visual", "Estruturação de perfil", "Tráfego pago", "Captação adicional fora das diárias previstas", "Peças ou demandas não descritas nesta proposta"], "nota": "Necessidades adicionais podem ser avaliadas e contratadas separadamente."}, "responsabilidades": {"titulo": "Responsabilidades", "cliente": ["Participar da imersão", "Disponibilizar informações e materiais", "Comparecer às gravações", "Aprovar roteiros dentro do prazo", "Realizar as postagens", "Fornecer acessos quando necessário", "Cumprir os prazos combinados"], "agencia": ["Conduzir a estratégia", "Desenvolver os roteiros", "Dirigir as gravações", "Editar os conteúdos", "Organizar o calendário", "Acompanhar a performance"]}, "cronograma": {"titulo": "Cronograma", "linhas": [{"etapa": "Imersão + estratégia", "periodo": "Mês 1"}, {"etapa": "Roteirização + gravações", "periodo": "Meses 2 a 4"}, {"etapa": "Edição + calendário", "periodo": "Meses 2 a 4"}, {"etapa": "Acompanhamento", "periodo": "Meses 2 a 4"}, {"etapa": "Encerramento", "periodo": "Final do mês 4"}]}, "investimento": {"titulo": "Investimento", "linhas": [{"o_que": "Mês 1 — Estratégia", "valor": "R$ 5.000"}, {"o_que": "Meses 2 a 4 — Produção", "valor": "R$ 2.500/mês"}], "total": "R$ 12.500", "total_label": "Total do ciclo"}, "condicoes": {"titulo": "Condições comerciais", "campos": [{"k": "Validade da proposta", "v": "[VALIDADE]"}, {"k": "Forma de pagamento", "v": "[PAGAMENTO]"}, {"k": "Início previsto", "v": "[INÍCIO]"}], "texto": "Prazo de aprovação de roteiros, política de reagendamento, propriedade e uso dos materiais e demais termos são detalhados no contrato."}, "porque": {"titulo": "Por que a oFruto", "provas": [{"t": "Método", "d": "Um processo claro: extração, estratégia, produção e acompanhamento. Nada de ligar a câmera sem norte."}, {"t": "Produção com direção", "d": "Conteúdo com qualidade estética e narrativa, não volume solto."}, {"t": "Foco em autonomia", "d": "Você termina o ciclo sabendo comunicar a própria marca, não dependente de terceiros."}]}, "depois": {"titulo": "O que muda depois do Plantio", "antes": "Marca sem estrutura clara, conteúdo pontual, dependência de terceiros.", "depois": "Posicionamento definido, linguagem estabelecida, primeira biblioteca de conteúdo, processo aprendido e autonomia.", "fecho": "Você não está comprando 24 vídeos. Está comprando uma marca que passa a se comunicar sozinha."}, "proximos": {"titulo": "Próximos passos", "passos": ["Aprovação da proposta", "Assinatura do contrato", "Pagamento inicial", "Agendamento da imersão", "Início do Plantio"]}} };

/* ---- BOAS-VINDAS (tela inicial da proposta, estilo Proton) ---- */
function montarBoasVindas(p, logoHtml){
  return `
    <div class="pv-w-top"><span class="pv-logo">${logoHtml}</span><span class="pv-brand">oFruto</span></div>
    <div class="pv-w-btm">
      <h1>${esc(p.nome)}${p.empresa?`<span class="emp">${esc(p.empresa)}</span>`:''}</h1>
      <p>${nl2br(p.welcome||'Que bom ter você aqui. Preparei essa proposta com cuidado, pensando na sua marca. Quando quiser, é só avançar.')}</p>
      <button class="pv-enter" id="pvEnter">Ver proposta</button>
    </div>`;
}

/* ---- CORPO GUIADO (a partir do molde do serviço, ou fallback simples) ---- */
function montarCorpoProposta(p, logoHtml){
  // usa o primeiro serviço escolhido como base do molde comercial
  const baseId = p.servicos[0];
  const m = (typeof MOLDES!=='undefined' && MOLDES[baseId]) ? MOLDES[baseId] : null;
  let body='';

  if(m){
    // capa
    body+=`<section class="pp-cover"><div class="pp-logo">${logoHtml}</div>
      <div class="pp-c-name">Plantamos estratégia,<br>cultivamos marcas,<br>geramos fruto.</div>
      <div class="pp-c-meta">Proposta para ${esc(p.nome)}${p.empresa?' · '+esc(p.empresa):''} · ${esc(p.criada)}</div></section>`;
    // contexto
    body+=ppSecNum('01','Contexto',m.contexto.titulo, `<p>${nl2br(fill(p.o_contexto||m.contexto.texto,p))}</p>`);
    // objetivo
    body+=ppSecNum('02','Objetivo',m.objetivo.titulo, `<p>${nl2br(fill(p.o_objetivo||m.objetivo.texto,p))}</p>`);
    // solução
    body+=`<section class="pp-sec"><span class="pp-bignum">03</span><div class="pp-eyebrow">A solução</div><h3>${esc(m.solucao.titulo)}</h3><p>${nl2br(fill(m.solucao.texto,p))}</p>
      <div class="pp-conceito">${esc(m.solucao.conceito)}</div></section>`;
    // como funciona
    body+=`<section class="pp-sec"><h3>${esc(m.comofunciona.titulo)}</h3><div class="pp-flow">`+
      m.comofunciona.etapas.map((e,i)=>`<div class="pp-flow-step"><div class="pp-fs-when">${esc(e.quando)}</div><div class="pp-fs-what">${esc(e.o_que)}</div><div class="pp-fs-d">${esc(e.desc)}</div></div>${i<m.comofunciona.etapas.length-1?'<div class="pp-flow-arrow">↓</div>':''}`).join('')+`</div></section>`;
    // entregáveis
    body+=`<section class="pp-sec"><h3>${esc(m.entregaveis.titulo)}</h3>`+
      m.entregaveis.grupos.map(g=>`<div class="pp-eg"><div class="pp-eg-t">${esc(g.nome)}</div><ul>${g.itens.map(i=>`<li>${esc(i)}</li>`).join('')}</ul></div>`).join('')+`</section>`;
    // não inclui
    body+=`<section class="pp-sec"><h3>${esc(m.naoinclui.titulo)}</h3><ul class="pp-neg">${m.naoinclui.itens.map(i=>`<li>${esc(i)}</li>`).join('')}</ul><p class="pp-nota">${esc(m.naoinclui.nota)}</p></section>`;
    // responsabilidades
    body+=`<section class="pp-sec"><h3>${esc(m.responsabilidades.titulo)}</h3><div class="pp-resp">
      <div><div class="pp-r-t">Cliente</div><ul>${m.responsabilidades.cliente.map(i=>`<li>${esc(i)}</li>`).join('')}</ul></div>
      <div><div class="pp-r-t">oFruto</div><ul>${m.responsabilidades.agencia.map(i=>`<li>${esc(i)}</li>`).join('')}</ul></div></div></section>`;
    // cronograma
    body+=`<section class="pp-sec"><h3>${esc(m.cronograma.titulo)}</h3><div class="pp-cron">`+
      m.cronograma.linhas.map(l=>`<div class="pp-cron-row"><span>${esc(l.etapa)}</span><span class="pp-cron-p">${esc(l.periodo)}</span></div>`).join('')+`</div></section>`;
    // investimento (usa valor editado do escopo se houver)
    const invLinhas=m.investimento.linhas.map(l=>`<div class="pp-inv-row"><span>${esc(l.o_que)}</span><span class="pp-inv-v">${esc(l.valor)}</span></div>`).join('');
    body+=`<section class="pp-sec"><h3>${esc(m.investimento.titulo)}</h3><div class="pp-inv">${invLinhas}</div></section>`;
    // condições
    const condRows=m.condicoes.campos.map(c=>`<div class="pp-cond-row"><span class="k">${esc(c.k)}</span><span class="v">${esc(fill(c.v,p))}</span></div>`).join('');
    body+=`<section class="pp-sec"><h3>${esc(m.condicoes.titulo)}</h3><div class="pp-cond">${condRows}</div><p class="pp-nota">${esc(m.condicoes.texto)}</p></section>`;
    // por que
    body+=`<section class="pp-sec"><h3>${esc(m.porque.titulo)}</h3><div class="pp-provas">`+
      m.porque.provas.map(pr=>`<div class="pp-prova"><div class="pp-pr-t">${esc(pr.t)}</div><div class="pp-pr-d">${esc(pr.d)}</div></div>`).join('')+`</div></section>`;
    // depois
    body+=`<section class="pp-sec pp-depois"><h3>${esc(m.depois.titulo)}</h3>
      <div class="pp-ad"><div class="pp-ad-b"><span>Antes</span>${esc(m.depois.antes)}</div><div class="pp-ad-d"><span>Depois</span>${esc(m.depois.depois)}</div></div>
      <p class="pp-fecho">${esc(m.depois.fecho)}</p></section>`;
    // vídeo
    if(p.video) body+=`<section class="pp-sec"><a class="pv-video" href="${esc(p.video)}" target="_blank" rel="noopener">Ver vídeo / material</a></section>`;
    // próximos passos
    body+=`<section class="pp-sec"><h3>${esc(m.proximos.titulo)}</h3><div class="pp-steps">`+
      m.proximos.passos.map((ps,i)=>`<div class="pp-step"><span class="pp-st-n">0${i+1}</span><span>${esc(ps)}</span></div>`).join('')+`</div></section>`;
    // obs
    if(p.obs) body+=`<section class="pp-sec"><h3>Observações</h3><p>${nl2br(p.obs)}</p></section>`;
  } else {
    // fallback: serviço sem molde ainda (Pomar/Marca Viva) — versão simples
    body=p.servicos.map(id=>{
      const s=SERVICOS_META.find(x=>x.id===id)||{linha:'',duracao:'',nome:id};
      const sc=p.scopes[id]||{};
      return `<section class="pp-sec"><div class="pp-s-eye">${esc(s.linha)} · ${esc(s.duracao)}</div><h3>${esc(s.nome)}</h3>
        <p>${esc(sc.resume)}</p><div class="pv-scope">${esc(sc.escopo)}</div>
        <div class="pv-invest"><span class="k">Investimento</span><span class="v">${esc(sc.invest)}</span></div></section>`;
    }).join('');
  }
  // ---- seção final: quem sou (foto placeholder p/ Supabase) ----
  body+=`<section class="pp-sec pp-quem">
    <div class="pp-quem-foto">
      <!-- IMG-SUPABASE: trocar por <img src="URL_FOTO_DAVI"> -->
      <span class="pp-foto-ph">Davi</span>
    </div>
    <div class="pp-quem-txt">
      <div class="pp-eyebrow">Quem cuida disso</div>
      <p class="pp-quem-p">Sou o Davi, diretor criativo e sócio da oFruto. Cuido pessoalmente da estratégia e da direção de cada marca que passa por aqui.</p>
      <p class="pp-quem-fecho">Tô aqui pra te ajudar a gerar frutos.</p>
    </div>
  </section>`;
  body+=`<div class="pv-foot"><div class="pv-f-logo">${logoHtml}</div>oFruto · plantamos estratégia, cultivamos marcas, geramos fruto.</div>`;
  return body;
}

/* ---- barra de progresso lateral + animação por seção (scroll-snap) ---- */
function setupPropScroll(){
  const pv=document.getElementById('propView');
  const secs=[...pv.querySelectorAll('.pp-cover, .pp-sec')];
  let prog=pv.querySelector('.pp-progress'); if(prog) prog.remove();
  prog=document.createElement('div'); prog.className='pp-progress';
  const n=secs.length;
  let ticks='';
  for(let i=0;i<n;i++){ ticks+=`<span class="tick" data-i="${i}" style="top:${(i/(n-1))*100}%"></span>`; }
  prog.innerHTML=`<div class="track-fill"></div><div class="thumb"></div>${ticks}`;
  pv.appendChild(prog);
  const fill=prog.querySelector('.track-fill'), thumb=prog.querySelector('.thumb');
  prog.addEventListener('click',e=>{const t=e.target.closest('.tick');if(t)secs[+t.dataset.i].scrollIntoView({behavior:'smooth'});});
  function setPos(idx){ const pctv=n>1?(idx/(n-1))*100:0; fill.style.height=pctv+'%'; thumb.style.top=pctv+'%'; }
  const io=new IntersectionObserver(entries=>{
    entries.forEach(en=>{ if(en.isIntersecting){ en.target.classList.add('in'); setPos(secs.indexOf(en.target)); } });
  },{root:pv,threshold:.4});
  secs.forEach(s=>io.observe(s));
  if(secs[0]){ secs[0].classList.add('in'); setPos(0); }
}
function ppText(titulo,texto){return `<section class="pp-sec"><h3>${esc(titulo)}</h3><p>${nl2br(texto)}</p></section>`;}
function ppSecNum(num,eye,titulo,inner){return `<section class="pp-sec"><span class="pp-bignum">${num}</span><div class="pp-eyebrow">${esc(eye)}</div><h3>${esc(titulo)}</h3>${inner}</section>`;}
