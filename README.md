# Lista Inteligente

Aplicativo de lista de compras que aprende com o seu histórico: em vez de você anotar manualmente o que falta em casa, o app analisa seus padrões de consumo e sugere automaticamente quais produtos já estão "no prazo" de recompra, inclusive lendo notas fiscais por foto com IA generativa.

Projeto desenvolvido em prática acompanhando a [playlist de Data App com Streamlit](https://www.youtube.com/watch?v=yzNe5buOsDw&list=PLvlkVRRKOYFSd81Ic1ec46pf9x479HgH8) do [Téo Calvo (Téo Me Why)](https://www.youtube.com/@teomewhy).

---

## Como funciona

O coração do projeto é uma pergunta de negócio simples: **"o que eu já deveria ter comprado de novo?"**

Para responder isso, o app:

1. Registra cada compra (produto, valor, data) em um banco SQLite.
2. Calcula, por produto, o intervalo médio histórico entre compras (`avg_diff_dias`).
3. Compara esse intervalo com o tempo que já se passou desde a última compra (`dias_ult_compra`).
4. Marca como `comprar = True` qualquer produto cujo tempo sem compra (somado a uma margem de dias que você define) ultrapasse o intervalo médio.

Toda essa lógica fica isolada em [`query_inteligente.sql`](query_inteligente.sql), usando CTEs e `LAG()` para calcular a recorrência direto no banco — sem trazer o processamento pesado para o Python.

```sql
-- trecho simplificado da lógica de recorrência
lag(dt_compra) OVER (PARTITION BY produto ORDER BY dt_compra) AS dt_anterior
...
avg(julianday(dt_compra) - julianday(dt_anterior)) AS avg_diff_dias
```

##  Funcionalidades

- ** Login com autorização por e-mail** - usa `st.login()` / `st.user` do Streamlit e libera o acesso apenas para o e-mail definido em `EMAIL_AUTHORIZED`.
- ** Lista inteligente de recompra** - tabela com produto, última compra, valor médio, intervalo médio entre compras e dias sem comprar, com checkbox indicando o que está "no prazo" de reposição. Dá pra ajustar quantos dias à frente o app deve considerar.
- ** Registro manual** - adiciona um novo produto e valor diretamente, reaproveitando os produtos já cadastrados via `selectbox`.
- ** Importação de histórico via CSV** - sobe um arquivo `.csv` com compras antigas, edita os dados em tela (`st.data_editor`) antes de confirmar a gravação.
- ** Leitura de nota fiscal com IA** - envia uma foto da nota fiscal, e o Gemini 2.0 Flash extrai produto, valor e data automaticamente, devolvendo um JSON estruturado pronto para revisão e gravação no banco.

## Leitura de nota fiscal com Gemini

A funcionalidade mais "data app" do projeto: a imagem da nota fiscal é enviada para o **Gemini 2.0 Flash** (`gen_ai.py`) junto de um prompt (`prompt_template.md`) que instrui o modelo a:

- extrair apenas o nome do produto (sem marca, peso ou quantidade);
- usar valor unitário para itens contados e valor total para itens vendidos por peso;
- responder em JSON, seguindo a estrutura definida em [`resposta_template.json`](resposta_template.json).

O resultado já volta pronto para virar um `DataFrame` editável antes de ser gravado no banco, o usuário sempre revisa antes de confirmar.

## Stack

| Camada | Tecnologia |
|---|---|
| Interface | [Streamlit](https://streamlit.io/) |
| Dados | SQLite + [SQLAlchemy](https://www.sqlalchemy.org/) |
| Manipulação de dados | Pandas |
| IA generativa | Google Gemini 2.0 Flash (`google-genai`) |
| Config | `python-dotenv` |

## Estrutura do projeto

```
datapp-lista-compras/
├── main.py                  # app Streamlit (UI, abas, login, regras de exibição)
├── gen_ai.py                # integração com o Gemini para leitura de nota fiscal
├── query.sql                # query base de consulta às compras
├── query_inteligente.sql    # query analítica: recorrência e sugestão de recompra
├── prompt_template.md       # prompt usado na extração de dados da nota fiscal
├── resposta_template.json   # exemplo do JSON esperado como resposta da IA
├── init_data.csv            # dados iniciais de exemplo para o banco
└── database.db              # banco SQLite local
```

## Como rodar localmente

```bash
# 1. Clone o repositório
git clone https://github.com/marialicer/datapp-lista-compras.git
cd datapp-lista-compras

# 2. Crie e ative um ambiente virtual
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 3. Instale as dependências
pip install streamlit pandas sqlalchemy python-dotenv google-genai

# 4. Configure as variáveis de ambiente
echo "GEMINI_API_KEY=sua_chave_aqui" >> .env
echo "EMAIL_AUTHORIZED=seu_email@exemplo.com" >> .env

# 5. Rode o app
streamlit run main.py
```

> A chave da API do Gemini pode ser gerada gratuitamente no [Google AI Studio](https://aistudio.google.com/).


## Créditos

Base do projeto construída em prática acompanhando o [Téo Calvo (Téo Me Why)](https://www.youtube.com/@teomewhy) na playlist [Data App com Streamlit](https://www.youtube.com/watch?v=yzNe5buOsDw&list=PLvlkVRRKOYFSd81Ic1ec46pf9x479HgH8), onde ele constrói esse mesmo app ao vivo.

## Autora

Desenvolvido por **Maria Alice Rocha** - Data Analyst, especialista em Analytics e BI pela PUC Minas.
[GitHub](https://github.com/marialicer) · [Portfólio](https://marialicer.github.io)
