# FRUTO · Modelo de Contrato (editável)
### Prestação de Serviços de Posicionamento e Produção de Conteúdo

> **Como usar:** os campos entre `{{ }}` são os variáveis — preencha por cliente
> (a mesma lógica do seu gerador de propostas). O resto é a base fixa.
>
> ⚠️ **Importante:** este é um modelo-base para agilizar, não um parecer jurídico.
> Antes de usar de verdade, peça a um advogado pra revisar e adaptar à sua realidade
> (principalmente cláusulas de rescisão, propriedade intelectual e valores). Não sou advogado.

---

**CONTRATO DE PRESTAÇÃO DE SERVIÇOS**

**CONTRATADA:** {{razao_social_ofruto}}, inscrita no CNPJ nº {{cnpj_ofruto}}, com sede em {{endereco_ofruto}}, doravante denominada **CONTRATADA**.

**CONTRATANTE:** {{nome_cliente}}, {{cpf_ou_cnpj_cliente}}, com endereço em {{endereco_cliente}}, doravante denominado **CONTRATANTE**.

As partes acima têm, entre si, justo e contratado o seguinte:

---

### Cláusula 1 — Objeto
A CONTRATADA prestará ao CONTRATANTE serviços de **{{servico_contratado}}** (ex.: Semente / Cultivo / Safra), conforme escopo detalhado no **Anexo I (Escopo de Entrega)**, que é parte integrante deste contrato.

### Cláusula 2 — Escopo e entregas
2.1. As entregas específicas, quantidades e formatos estão descritos no Anexo I.
2.2. Serviços fora do escopo descrito serão orçados à parte, mediante aprovação prévia do CONTRATANTE.
2.3. **Não estão incluídos:** {{itens_nao_incluidos}} (ex.: tráfego pago, deslocamentos fora de {{cidade}}, equipamentos de terceiros).

### Cláusula 3 — Prazo
3.1. Este contrato tem vigência de **{{vigencia}}** (ex.: 3 meses), iniciando em {{data_inicio}}.
3.2. Renovação automática por igual período, salvo aviso de {{prazo_aviso}} dias por qualquer das partes. *(ajuste conforme preferir)*

### Cláusula 4 — Valores e pagamento
4.1. Valor total/mensal: **R$ {{valor}}** ({{valor_extenso}}).
4.2. Forma de pagamento: {{forma_pagamento}} (ex.: {{percentual_entrada}}% de entrada + saldo em {{parcelas}}x, vencimento todo dia {{dia_vencimento}}).
4.3. Atraso superior a {{dias_atraso}} dias autoriza a suspensão dos serviços até a regularização.
4.4. Reajuste anual pelo {{indice_reajuste}} (ex.: IPCA), se aplicável.

### Cláusula 5 — Obrigações da CONTRATADA
- Executar os serviços com qualidade e dentro dos prazos acordados.
- Manter o CONTRATANTE informado do andamento.
- Respeitar a identidade e a voz do CONTRATANTE.
- Zelar pelo sigilo das informações recebidas.

### Cláusula 6 — Obrigações do CONTRATANTE
- Fornecer informações, acessos e materiais necessários no prazo solicitado.
- Aprovar (ou solicitar ajustes) das entregas em até {{prazo_aprovacao}} dias.
- Efetuar os pagamentos nas datas combinadas.
- **Prazos dependentes do cliente:** atrasos na entrega de material ou aprovação estendem os prazos na mesma proporção.

### Cláusula 7 — Rodadas de revisão
Cada entrega inclui até **{{num_revisoes}}** rodadas de ajustes. Revisões adicionais serão orçadas à parte.

### Cláusula 8 — Propriedade intelectual e uso de imagem
8.1. Após a quitação, os conteúdos entregues pertencem ao CONTRATANTE para uso {{uso_conteudo}} (ex.: nas redes sociais dele).
8.2. A CONTRATADA pode usar os trabalhos em seu **portfólio e redes**, salvo objeção expressa do CONTRATANTE em {{clausula_portfolio}}.
8.3. O CONTRATANTE autoriza o uso de sua imagem/material para fins de execução do contrato.

### Cláusula 9 — Confidencialidade
As partes se comprometem a manter sigilo sobre informações estratégicas e dados trocados durante a relação, inclusive após o término do contrato.

### Cláusula 10 — LGPD
As partes tratarão dados pessoais conforme a Lei nº 13.709/2018, usando-os apenas para a execução deste contrato.

### Cláusula 11 — Rescisão
11.1. Qualquer parte pode rescindir mediante aviso de {{prazo_rescisao}} dias.
11.2. Em caso de rescisão, serão devidos os valores proporcionais aos serviços já executados.
11.3. Rescisão por descumprimento pode ocorrer imediatamente, sem prejuízo de eventuais penalidades: {{multa_rescisoria}}.

### Cláusula 12 — Disposições gerais
12.1. Este contrato representa o acordo integral entre as partes.
12.2. Alterações só valem por escrito e assinadas por ambas.
12.3. Foro eleito: comarca de {{comarca}}.

---

E, por estarem de acordo, assinam:

{{cidade}}, {{data}}.

<br>

______________________________
**CONTRATADA** — {{razao_social_ofruto}}

<br>

______________________________
**CONTRATANTE** — {{nome_cliente}}

---

## Anexo I — Escopo de Entrega ({{servico_contratado}})
*Puxe daqui do seu catálogo de serviços já pronto:*
- {{entrega_1}}
- {{entrega_2}}
- {{entrega_3}}
- Prazo de cada entrega: {{prazos}}
- Formato de comunicação/aprovação: {{canal}}

---

### Campos variáveis (referência rápida pra automatizar na central)
`razao_social_ofruto, cnpj_ofruto, endereco_ofruto, nome_cliente, cpf_ou_cnpj_cliente, endereco_cliente, servico_contratado, itens_nao_incluidos, cidade, vigencia, data_inicio, prazo_aviso, valor, valor_extenso, forma_pagamento, percentual_entrada, parcelas, dia_vencimento, dias_atraso, indice_reajuste, prazo_aprovacao, num_revisoes, uso_conteudo, clausula_portfolio, prazo_rescisao, multa_rescisoria, comarca, data, entrega_1, entrega_2, entrega_3, prazos, canal`
