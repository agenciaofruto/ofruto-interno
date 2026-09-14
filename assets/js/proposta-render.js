/* proposta-render.js — funções puras de montagem da apresentação de uma proposta.
   Usado por index.html (preview interno, botão "Ver preview") e por proposta.html
   (página pública, lida por token). Não depende de DOM específico de nenhuma das
   duas páginas: recebe os dados da proposta (p) e o HTML do logo (logoHtml) e
   devolve strings de HTML prontas para inserir onde cada página quiser. */

/* subconjunto de DATA.servicos (id/nome/duracao/linha) necessário só para rotular
   a seção de um serviço quando ele ainda não tem molde comercial dedicado em
   MOLDES (hoje: Pomar e Marca Viva). Se o nome/duração/linha de um serviço mudar
   em DATA.servicos (dentro de index.html), atualizar aqui também.
   "comoTrabalhamos" é a copy da seção "Como trabalhamos", específica por serviço. */
const SERVICOS_META = [
  { id:'plantio', nome:'Plantio', duracao:'4 meses', linha:'oFruto',
    comoTrabalhamos:{
      texto:'No Plantio, a gente parte do que já existe: sua história, sua autoridade, o que você já construiu. Nos primeiros meses, transformamos isso num plano de marca com direção clara e colocamos esse plano em prática com você.\n\nA gente acompanha o começo de perto, produz junto e deixa uma base sólida para que, no fim do ciclo, você siga comunicando a partir dessa direção — sozinho ou com a gente, se quiser continuar.'
    }
  },
  { id:'pomar', nome:'Pomar', duracao:'6 meses', linha:'oFruto',
    comoTrabalhamos:{
      texto:'No Pomar, a gente assume o comando da operação de conteúdo — planeja, cria, produz e mantém sua marca viva no dia a dia.\n\nVocê continua por perto, acompanhando e participando das decisões importantes. A diferença é que quem toca a rotina, o que postar e como manter tudo funcionando, é a gente.'
    }
  },
  { id:'marca-viva', nome:'Marca Viva', duracao:'5 meses', linha:'Sociedade · oFruto + Brenda',
    comoTrabalhamos:{
      texto:'O Marca Viva é para marcas que querem construir presença e reconhecimento sem depender da exposição da pessoa por trás do negócio.\n\nA gente trabalha a comunicação para que a marca tenha vida própria, sem precisar colocar o dono, fundador ou especialista no centro de tudo. Nossa "Talent" se torna a comunicadora da marca, seguindo os fundamentos da estratégia de posicionamento.'
    }
  }
];

/* mesma metodologia (Solo/Semeadura/Cultivo/Colheita) já usada na aba Metodologia
   do app interno (DATA.metodologia) — copiada aqui pra proposta não depender do
   DATA completo de index.html. Se o texto mudar lá, atualizar aqui também. */
const METODOLOGIA = [
  {nome:'Solo', curto:'Conhecer a terra antes de plantar.', longo:'Antes de qualquer conteúdo, a extração: quem a pessoa (ou marca) já é, história, autoridade, o que quer, pra quem, por quê. Nada criado do nada, tudo lapidado do que já existe.'},
  {nome:'Semeadura', curto:'Plantar a estratégia.', longo:'O mapa: posicionamento, narrativa, tom de voz, canais que fazem sentido, formatos, metas e prazos. É o guia que rege toda a produção seguinte.'},
  {nome:'Cultivo', curto:'A câmera com norte.', longo:'A produção: roteiro em cima da estratégia, diárias, edição, conteúdo saindo com qualidade estética. É o trabalho recorrente de quem cuida.'},
  {nome:'Colheita', curto:'Acompanhar o que a terra devolve.', longo:'Leitura de performance: o que germinou, o que ressoou, o que ajustar. Colheita não é o fim, é acompanhar o resultado, no Pomar, safra após safra.'}
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

const MOLDES = {"plantio": {"capa": {"servico": "Plantio", "tagline": "A primeira safra da sua marca."}, "contexto": {"titulo": "Por que essa proposta", "texto": "Hoje, [NOME] já tem experiência, repertório e autoridade em [ÁREA]. Mas essa percepção ainda não está traduzida numa presença digital consistente.\n\nO desafio não é simplesmente produzir conteúdo. É transformar o conhecimento e a personalidade de [NOME] numa comunicação reconhecível, estratégica e sustentável."}, "objetivo": {"titulo": "O objetivo", "texto": "Estruturar a presença digital de [NOME], construir seu posicionamento e produzir uma primeira safra de conteúdo, de forma que [NOME] siga comunicando a própria marca com autonomia."}, "solucao": {"titulo": "Como funciona", "texto": "O Plantio é um ciclo de quatro meses que combina estratégia de marca, produção audiovisual e acompanhamento de performance para construir a primeira base de comunicação digital.", "conceito": "Estratégia → Produção → Autonomia"}, "entregaveis": {"titulo": "Entregáveis", "grupos": [{"nome": "Estratégia", "itens": ["Imersão de 2 a 3 horas", "Mapa estratégico da marca", "Posicionamento", "Narrativa", "Tom de voz", "Direcionamento de canais e formatos"]}, {"nome": "Produção", "itens": ["2 diárias por mês", "8 vídeos por mês", "24 vídeos no ciclo", "Roteiros", "Direção", "Edição", "Calendário de postagem"]}, {"nome": "Acompanhamento", "itens": ["Análise de performance", "Ajustes para as próximas produções"]}]}, "naoinclui": {"titulo": "O que não está incluso", "itens": ["Gestão diária das redes", "Publicação dos conteúdos", "Resposta a comentários e mensagens", "Criação de identidade visual", "Estruturação de perfil", "Tráfego pago", "Captação adicional fora das diárias previstas", "Peças ou demandas não descritas nesta proposta"], "nota": "Necessidades adicionais podem ser avaliadas e contratadas separadamente."}, "responsabilidades": {"titulo": "Responsabilidades", "cliente": ["Participar da imersão", "Disponibilizar informações e materiais", "Comparecer às gravações", "Aprovar roteiros dentro do prazo", "Realizar as postagens", "Fornecer acessos quando necessário", "Cumprir os prazos combinados"], "agencia": ["Conduzir a estratégia", "Desenvolver os roteiros", "Dirigir as gravações", "Editar os conteúdos", "Organizar o calendário", "Acompanhar a performance"]}, "cronograma": {"titulo": "Cronograma", "linhas": [{"etapa": "Imersão + estratégia", "periodo": "Mês 1"}, {"etapa": "Roteirização + gravações", "periodo": "Meses 2 a 4"}, {"etapa": "Edição + calendário", "periodo": "Meses 2 a 4"}, {"etapa": "Acompanhamento", "periodo": "Meses 2 a 4"}, {"etapa": "Encerramento", "periodo": "Final do mês 4"}]}, "investimento": {"titulo": "Investimento", "linhas": [{"o_que": "Mês 1 — Estratégia", "valor": "R$ 5.000"}, {"o_que": "Meses 2 a 4 — Produção", "valor": "R$ 2.500/mês"}], "total": "R$ 12.500", "total_label": "Total do ciclo"}, "condicoes": {"titulo": "Condições comerciais", "campos": [{"k": "Validade da proposta", "v": "[VALIDADE]"}, {"k": "Forma de pagamento", "v": "[PAGAMENTO]"}, {"k": "Início previsto", "v": "[INÍCIO]"}], "texto": "Prazo de aprovação de roteiros, política de reagendamento, propriedade e uso dos materiais e demais termos são detalhados no contrato."}, "depois": {"titulo": "O que muda depois do nosso serviço", "antes": "Marca sem estrutura clara, conteúdo pontual, dependência de terceiros.", "depois": "Posicionamento definido, linguagem estabelecida, primeira biblioteca de conteúdo, processo aprendido e autonomia.", "fecho": "Você não está comprando 24 vídeos. Está comprando uma marca que passa a se comunicar sozinha."}, "proximos": {"titulo": "Próximos passos", "passos": ["Aprovação da proposta", "Assinatura do contrato", "Pagamento inicial", "Agendamento da imersão", "Início do Plantio"]}}};
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
  const svcMeta = SERVICOS_META.find(x=>x.id===baseId);
  let body='';

  // capa — sempre, independente de o serviço ter molde dedicado ou não
  body+=`<section class="pp-cover"><div class="pp-logo">${logoHtml}</div>
    <div class="pp-c-name">Plantamos estratégia,<br>cultivamos marcas,<br>geramos fruto.</div>
    <div class="pp-c-meta">Proposta para ${esc(p.nome)}${p.empresa?' · '+esc(p.empresa):''}${p.criada?' · '+esc(p.criada):''}</div></section>`;

  // somos uma agência e produtora audiovisual — igual pros três serviços
  body+=`<section class="pp-sec"><h3>Somos uma agência e produtora audiovisual</h3>
    <p>Não começamos pelo conteúdo. Começamos entendendo onde sua marca está, onde precisa chegar e o que precisa acontecer no caminho.</p>
    <p>A partir daí, estratégia vira produção, e produção vira direção.</p></section>`;

  // contexto e objetivo — mesclados numa única seção
  const contextoTxt = p.o_contexto || (m ? m.contexto.texto : '');
  const objetivoTxt = p.o_objetivo || (m ? m.objetivo.texto : '');
  if(contextoTxt || objetivoTxt){
    body+=`<section class="pp-sec"><h3>Contexto e objetivo</h3>
      ${contextoTxt?`<p>${nl2br(fill(contextoTxt,p))}</p>`:''}
      ${objetivoTxt?`<p>${nl2br(fill(objetivoTxt,p))}</p>`:''}</section>`;
  }

  // o caminho até lá — Solo/Semeadura/Cultivo/Colheita, em cards vinculados ao scroll vertical
  body+=`<section class="pp-sec pp-jornada-sec">
    <div class="pp-jornada-sticky">
      <h3>O caminho até lá</h3>
      <div class="pp-jornada-scroll">${
        METODOLOGIA.map((f,i)=>`<div class="pp-jcard"><div class="pp-jc-top"><span class="pp-jc-nome">${esc(f.nome)}</span><span class="pp-jc-n">0${i+1}</span></div><p class="pp-jc-curto">${esc(f.curto)}</p><p>${esc(f.longo)}</p></div>`).join('')
      }</div>
    </div></section>`;

  // como trabalhamos — específico do serviço escolhido
  if(svcMeta && svcMeta.comoTrabalhamos){
    body+=`<section class="pp-sec"><h3>Como trabalhamos no ${esc(svcMeta.nome)}</h3>
      <p>${nl2br(svcMeta.comoTrabalhamos.texto)}</p></section>`;
  }

  if(m){
    // como funciona (explicação objetiva do serviço)
    body+=`<section class="pp-sec"><h3>Como funciona</h3><p>${nl2br(fill(m.solucao.texto,p))}</p>
      <div class="pp-conceito">${esc(m.solucao.conceito)}</div></section>`;
    // cronograma
    body+=`<section class="pp-sec"><h3>${esc(m.cronograma.titulo)}</h3><div class="pp-cron">`+
      m.cronograma.linhas.map(l=>`<div class="pp-cron-row"><span>${esc(l.etapa)}</span><span class="pp-cron-p">${esc(l.periodo)}</span></div>`).join('')+`</div></section>`;
    // entregáveis (expansível)
    body+=montarAcordeao(m.entregaveis.titulo, 'Ver entregáveis', 'Ocultar entregáveis',
      m.entregaveis.grupos.map(g=>`<div class="pp-eg"><div class="pp-eg-t">${esc(g.nome)}</div><ul>${g.itens.map(i=>`<li>${esc(i)}</li>`).join('')}</ul></div>`).join(''));
    // o que não está incluso (expansível)
    body+=montarAcordeao(m.naoinclui.titulo, 'Ver o que não está incluso', 'Ocultar',
      `<ul class="pp-neg">${m.naoinclui.itens.map(i=>`<li>${esc(i)}</li>`).join('')}</ul><p class="pp-nota">${esc(m.naoinclui.nota)}</p>`);
    // responsabilidades (expansível)
    body+=montarAcordeao(m.responsabilidades.titulo, 'Ver responsabilidades', 'Ocultar responsabilidades',
      `<div class="pp-resp"><div><div class="pp-r-t">Cliente</div><ul>${m.responsabilidades.cliente.map(i=>`<li>${esc(i)}</li>`).join('')}</ul></div>
      <div><div class="pp-r-t">oFruto</div><ul>${m.responsabilidades.agencia.map(i=>`<li>${esc(i)}</li>`).join('')}</ul></div></div>`);
    // investimento do projeto
    const invLinhas=m.investimento.linhas.map(l=>`<div class="pp-inv-row"><span>${esc(l.o_que)}</span><span class="pp-inv-v">${esc(l.valor)}</span></div>`).join('');
    body+=`<section class="pp-sec"><h3>Investimento do projeto</h3><div class="pp-inv">${invLinhas}</div></section>`;
    // condições comerciais
    const condRows=m.condicoes.campos.map(c=>`<div class="pp-cond-row"><span class="k">${esc(c.k)}</span><span class="v">${esc(fill(c.v,p))}</span></div>`).join('');
    body+=`<section class="pp-sec"><h3>${esc(m.condicoes.titulo)}</h3><div class="pp-cond">${condRows}</div></section>`;
    // o que muda depois do nosso serviço
    body+=`<section class="pp-sec pp-depois"><h3>${esc(m.depois.titulo)}</h3>
      <div class="pp-ad"><div class="pp-ad-b"><span>Antes</span>${esc(m.depois.antes)}</div><div class="pp-ad-d"><span>Depois</span>${esc(m.depois.depois)}</div></div>
      <p class="pp-fecho">${esc(m.depois.fecho)}</p></section>`;
    // próximos passos
    body+=`<section class="pp-sec"><h3>${esc(m.proximos.titulo)}</h3><div class="pp-steps">`+
      m.proximos.passos.map((ps,i)=>`<div class="pp-step"><span class="pp-st-n">0${i+1}</span><span>${esc(ps)}</span></div>`).join('')+`</div></section>`;
  } else {
    // fallback: serviço sem molde ainda (Pomar/Marca Viva)
    body+=p.servicos.map(id=>{
      const s=SERVICOS_META.find(x=>x.id===id)||{linha:'',duracao:'',nome:id};
      const sc=p.scopes[id]||{};
      const bullets=(sc.escopo||'').split('\n').map(l=>l.replace(/^[•\-\s]+/,'').trim()).filter(Boolean);
      return `<section class="pp-sec">
        <h3>${esc(s.nome)}</h3>
        ${sc.resume?`<p>${esc(sc.resume)}</p>`:''}
        ${bullets.length?`<div class="pp-eg"><ul>${bullets.map(b=>`<li>${esc(b)}</li>`).join('')}</ul></div>`:''}
        <div class="pp-inv">
          <div class="pp-inv-row"><span>Investimento total</span><span class="pp-inv-v">${esc(sc.invest||'')}</span></div>
          ${p.pagamento?`<div class="pp-inv-row"><span>Forma de pagamento</span><span class="pp-inv-v">${esc(p.pagamento)}</span></div>`:''}
        </div></section>`;
    }).join('');
  }

  if(p.obs) body+=`<section class="pp-sec"><h3>Observações</h3><p>${nl2br(p.obs)}</p></section>`;

  // ---- quem cuida disso — integrado ao bloco, sem label separado ----
  body+=`<section class="pp-sec pp-quem">
    <div class="pp-quem-foto">
      <img src="assets/davi.jpeg" alt="Davi">
    </div>
    <div class="pp-quem-txt">
      <p class="pp-quem-p">Quem cuida da sua marca por aqui sou eu, o Davi — diretor criativo e sócio da oFruto. Cuido pessoalmente da estratégia e da direção de cada marca que passa por aqui.</p>
      <p class="pp-quem-fecho">Tô aqui pra te ajudar a gerar frutos.</p>
    </div>
  </section>`;

  // ---- veja nosso trabalho (portfólio/vídeo) — perto do fim, antes de fechar ----
  if(p.video) body+=`<section class="pp-sec"><h3>Quer ver de perto?</h3>
    <p>Dá uma olhada nos trabalhos e resultados que já entregamos.</p>
    <a class="pv-video" href="${esc(p.video)}" target="_blank" rel="noopener">Ver portfólio</a></section>`;

  // ---- vamos conversar (fechamento) ----
  body+=`<section class="pp-sec"><h3>Vamos conversar</h3>
    <p>Combinado o caminho, o próximo passo é simples: aprovar a proposta e marcar o início.</p>
    <div class="pp-cond">
      <div class="pp-cond-row"><span class="k">Validade da proposta</span><span class="v">${esc(p.validade||'a combinar')}</span></div>
      <div class="pp-cond-row"><span class="k">Início previsto</span><span class="v">${esc(p.inicio||'a combinar')}</span></div>
    </div></section>`;

  // ---- frase final (eco da capa) ----
  body+=`<section class="pp-sec" style="text-align:center"><p class="pp-fecho">Plantamos estratégia, cultivamos marcas, geramos fruto.</p></section>`;

  return body;
}

/* seção com conteúdo escondido por padrão, revelado ao clicar no botão
   (Entregáveis / O que não está incluso / Responsabilidades) */
function montarAcordeao(titulo, labelAbrir, labelFechar, innerHtml){
  return `<section class="pp-sec pp-acc">
    <h3>${esc(titulo)}</h3>
    <button type="button" class="pp-acc-toggle" data-open="${esc(labelAbrir)}" data-close="${esc(labelFechar)}">${esc(labelAbrir)}</button>
    <div class="pp-acc-body" hidden>${innerHtml}</div>
  </section>`;
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
  ativarAcordeoes(pv);
  ativarJornadaScroll(pv);
}

/* seções expansíveis (Entregáveis / O que não está incluso / Responsabilidades):
   fechadas por padrão, o botão abre/fecha os bullets */
function ativarAcordeoes(root){
  root.querySelectorAll('.pp-acc-toggle').forEach(btn=>{
    if(btn.dataset.wired) return;
    btn.dataset.wired='1';
    btn.addEventListener('click',()=>{
      const corpo = btn.nextElementSibling;
      const abrindo = corpo.hasAttribute('hidden');
      if(abrindo){ corpo.removeAttribute('hidden'); btn.textContent = btn.dataset.close; }
      else{ corpo.setAttribute('hidden',''); btn.textContent = btn.dataset.open; }
    });
  });
}

/* "O caminho até lá": em vez de arrastar horizontalmente, o scroll vertical da
   página empurra os cards para o lado enquanto a seção passa pela tela — a
   seção é mais alta que a tela (min-height maior em CSS) e o bloco de cards
   fica fixo (position:sticky) até o scroll "consumir" essa altura extra. */
function ativarJornadaScroll(root){
  const sec = root.querySelector('.pp-jornada-sec');
  if(!sec || sec.dataset.jornadaWired) return;
  sec.dataset.jornadaWired='1';
  const sticky = sec.querySelector('.pp-jornada-sticky');
  const track = sec.querySelector('.pp-jornada-scroll');

  // a altura extra da seção precisa bater com a distância que os cards vão
  // percorrer — calculada aqui (não em CSS), pra não sobrar scroll "parado"
  // no fim nem faltar espaço antes do fim.
  let maxScroll = 0, total = 0;
  function medir(){
    maxScroll = Math.max(0, track.scrollWidth - sticky.clientWidth);
    sec.style.minHeight = (sticky.offsetHeight + maxScroll + 120) + 'px';
    total = sec.offsetHeight - sticky.offsetHeight;
  }
  medir();
  window.addEventListener('resize', medir);

  function update(){
    const rect = sec.getBoundingClientRect();
    // revela a seção assim que ela começa a entrar na tela — sem isso, o
    // fade-in (pensado pra seções de 1 tela) só disparava depois de um scroll
    // enorme, porque essa seção é bem mais alta que a tela.
    if(rect.top < window.innerHeight) sec.classList.add('in');
    let progresso = total>0 ? (-rect.top)/total : 0;
    progresso = Math.max(0, Math.min(1, progresso));
    track.style.transform = `translateX(${-progresso*maxScroll}px)`;
  }

  root.addEventListener('scroll', update, {passive:true});
  update();
}
