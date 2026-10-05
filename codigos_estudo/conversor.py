import os
import pandas as pd

def limpar_texto(valor):
    """Remove espaços extras do valor lido da planilha."""
    return str(valor).strip()


def obter_valor_bruto(df, nome):
    linha = df.loc[df["NOME"] == nome]
    if linha.empty:
        raise KeyError(f"'{nome}' não encontrado na planilha de entrada.")
    return linha.iloc[0]["VALOR"]


def obter_escalar(df, nome):
    """Lê um valor escalar (ex.: t=20) e retorna como inteiro."""
    return int(limpar_texto(obter_valor_bruto(df, nome)))


def obter_vetor(df, nome):
    """Lê um valor 'vector' (ex.: np='2 2 1') e retorna como lista de inteiros."""
    texto = limpar_texto(obter_valor_bruto(df, nome))
    return [int(x) for x in texto.split()]


def obter_vetor_de_vetores(df, nome):
    """Lê um valor 'vector_in_vector' (ex.: ij='4 6 7; 1 2 5 8; 3 9 4') -> lista de listas."""
    texto = limpar_texto(obter_valor_bruto(df, nome))
    grupos = [g.strip() for g in texto.split(";") if g.strip() != ""]
    return [[int(x) for x in g.split()] for g in grupos]


def obter_vetor_de_vetores_de_vetores(df, nome):
    """Lê um valor com 3 níveis (linha -> coluna -> elementos), separados por ';' e ','."""
    texto = limpar_texto(obter_valor_bruto(df, nome))
    linhas = [l.strip() for l in texto.split(";") if l.strip() != ""]
    resultado = []
    for linha in linhas:
        colunas = [c.strip() for c in linha.split(",") if c.strip() != ""]
        resultado.append([[int(x) for x in c.split()] for c in colunas])
    return resultado


def existe_na_planilha(df, nome):
    return nome in df["NOME"].values


def preencher_conjunto(df, nome_escalar):
    """
    Gera o conjunto {1, ..., N} a partir de um escalar já existente na planilha.
    Ex.: se t = 20, retorna [1, 2, 3, ..., 20]  -> usado para gerar T, D, P, G, I, J
    """
    n = obter_escalar(df, nome_escalar)
    return list(range(1, n + 1))


def preencher_Sd(tamanho_D, tamanho_T):
    """
    Divide os T slots em D dias, em blocos sequenciais de mesmo tamanho.
    Ex.: T=20, D=5 -> 4 slots por dia -> [[1,2,3,4], [5,6,7,8], ...]
    """
    qtd_slot_dia = tamanho_T // tamanho_D
    Sd = []
    valor = 1
    for _ in range(tamanho_D):
        linha = list(range(valor, valor + qtd_slot_dia))
        Sd.append(linha)
        valor += qtd_slot_dia
    return Sd


def preencher_Sdp(tamanho_D, tamanho_P, Np):
    """
    Para cada dia 'd', divide os horários daquele dia entre os P turnos,
    de acordo com a quantidade Np[p] de horários de cada turno.

    Resultado indexado como Sdp[d][p] -> subconjunto de horários do dia d
    que pertencem ao turno p (matriz D x P de vetores, como no modelo em
    papel; equivale a Sdp[d, p] no lado Julia).

    Ex.: D=5, P=3, Np=[2,2,1] -> cada dia tem 5 horários, divididos 2/2/1
    entre os turnos.
    """
    Sdp = []
    valor = 1
    for _d in range(tamanho_D):
        linha_dia = []
        for p in range(tamanho_P):
            turno = list(range(valor, valor + Np[p]))
            linha_dia.append(turno)
            valor += Np[p]
        Sdp.append(linha_dia)

    return Sdp


def preencher_tud(Sdp):
    """
    tud[d] = índice do último horário (último turno, ex.: noturno) do dia d.
    Sdp está indexado como Sdp[d][p]. Um dia por posição (D elementos).
    """
    return [linha_dia[-1][-1] for linha_dia in Sdp]


def preencher_tpdd(Sdp):
    """
    tpdd[d] = índice do primeiro horário (primeiro turno, ex.: matutino) do
    dia SEGUINTE a d (d+1). Por isso só existem D-1 elementos: o último dia
    não tem "dia seguinte". Sdp está indexado como Sdp[d][p].
    Ex.: T=20, D=5, Np=[4] -> tud = [4, 8, 12, 16, 20], tpdd = [5, 9, 13, 17]
    """
    return [linha_dia[0][0] for linha_dia in Sdp[1:]]


def lista_para_texto(lista, separadores=(";", ",", " ")):
    """
    Converte listas (com até 3 níveis de profundidade) em texto para caber
    numa célula de CSV, usando um separador diferente por nível:
      nível 1 (mais externo) -> ';'
      nível 2               -> ','
      nível 3 (mais interno) -> ' '
    Ex.: [1,2,3]                     -> '1 2 3'
         [[1,2],[3,4]]               -> '1 2;3 4'
         [[[1,2],[3]],[[4],[5,6]]]   -> '1 2,3;4,5 6'
    """
    if len(lista) > 0 and isinstance(lista[0], list):
        sep, *resto = separadores
        return sep.join(lista_para_texto(sub, resto) for sub in lista)
    return separadores[-1].join(str(v) for v in lista)


def formatar_passthrough(tipo, valor_bruto):
    """
    Para variáveis que não entram em nenhum cálculo (ex.: lmax, np, hi, ij, ig):
    apenas relê o valor no formato correto e reescreve no padrão do CSV,
    sem alterar seu conteúdo.
    """
    tipo = tipo.strip().lower()
    texto = limpar_texto(valor_bruto)

    if tipo == "scalar":
        return tipo, str(int(texto))

    if tipo == "vector":
        numeros = [int(x) for x in texto.split()]
        return tipo, lista_para_texto(numeros)

    if tipo == "vector_in_vector":
        grupos = [g.strip() for g in texto.split(";") if g.strip() != ""]
        vetor2d = [[int(x) for x in g.split()] for g in grupos]
        return tipo, lista_para_texto(vetor2d)

    # Tipo desconhecido: mantém o texto como está, só limpo.
    return tipo, texto


NOMES_RAW_CONSUMIDOS = {"t", "d", "p", "g", "i", "j"}

# Nomes das variáveis derivadas, tratadas à parte (nunca repassadas por
# formatar_passthrough, para não duplicar no CSV final).
NOMES_DERIVADOS = {"T", "D", "P", "G", "I", "J", "Sd", "Sdp", "tud", "tpdd"}


def processar_planilha(caminho_xlsx):
    df = pd.read_excel(caminho_xlsx)
    df["NOME"] = df["NOME"].astype(str).str.strip()
    df["TIPO"] = df["TIPO"].astype(str).str.strip().str.lower()

    linhas_saida = []

    # 1) Repassa (copia e formata) tudo que não é matéria-prima de cálculo
    #    nem uma variável derivada (ex.: lmax, np, hi, ij, ig).
    for _, linha in df.iterrows():
        nome = linha["NOME"]
        if nome in NOMES_RAW_CONSUMIDOS or nome in NOMES_DERIVADOS:
            continue
        tipo_formatado, valor_formatado = formatar_passthrough(linha["TIPO"], linha["VALOR"])
        linhas_saida.append({"NOME": nome, "TIPO": tipo_formatado, "VALOR": valor_formatado})

    # 2) T, D, P, G, I, J: usa o que já existir na planilha, senão calcula
    #    a partir do escalar correspondente (t, d, p, g, i, j).
    conjuntos = {"T": "t", "D": "d", "P": "p", "G": "g", "I": "i", "J": "j"}
    valores = {}
    for nome_conjunto, nome_escalar in conjuntos.items():
        if existe_na_planilha(df, nome_conjunto):
            valores[nome_conjunto] = obter_vetor(df, nome_conjunto)
            print(f"'{nome_conjunto}' já definido na planilha, copiando.")
        else:
            valores[nome_conjunto] = preencher_conjunto(df, nome_escalar)
            print(f"'{nome_conjunto}' calculado: {valores[nome_conjunto]}")
        linhas_saida.append({
            "NOME": nome_conjunto,
            "TIPO": "vector",
            "VALOR": lista_para_texto(valores[nome_conjunto]),
        })

    # 3) Sd
    if existe_na_planilha(df, "Sd"):
        Sd = obter_vetor_de_vetores(df, "Sd")
        print("'Sd' já definido na planilha, copiando.")
    else:
        Sd = preencher_Sd(len(valores["D"]), len(valores["T"]))
        print(f"'Sd' calculado: {Sd}")
    linhas_saida.append({"NOME": "Sd", "TIPO": "vector_in_vector", "VALOR": lista_para_texto(Sd)})

    # 4) Sdp (precisa de Np, se for calcular) -> matriz D x P de vetores,
    #    indexada como Sdp[d][p] (dia primeiro, turno depois).
    if existe_na_planilha(df, "Sdp"):
        Sdp = obter_vetor_de_vetores_de_vetores(df, "Sdp")
        print("'Sdp' já definido na planilha, copiando.")
    else:
        Np = obter_vetor(df, "np")
        Sdp = preencher_Sdp(len(valores["D"]), len(valores["P"]), Np)
        print(f"'Sdp' calculado: {Sdp}")
    linhas_saida.append({
        "NOME": "Sdp",
        "TIPO": "matrix_of_vector",
        "VALOR": lista_para_texto(Sdp),
    })

    # 5) tud
    if existe_na_planilha(df, "tud"):
        tud = obter_vetor(df, "tud")
        print("'tud' já definido na planilha, copiando.")
    else:
        tud = preencher_tud(Sdp)
        print(f"'tud' calculado: {tud}")
    linhas_saida.append({"NOME": "tud", "TIPO": "vector", "VALOR": lista_para_texto(tud)})

    # 6) tpdd
    if existe_na_planilha(df, "tpdd"):
        tpdd = obter_vetor(df, "tpdd")
        print("'tpdd' já definido na planilha, copiando.")
    else:
        tpdd = preencher_tpdd(Sdp)
        print(f"'tpdd' calculado: {tpdd}")
    linhas_saida.append({"NOME": "tpdd", "TIPO": "vector", "VALOR": lista_para_texto(tpdd)})

    return pd.DataFrame(linhas_saida, columns=["NOME", "TIPO", "VALOR"])


def main():
    pasta_entrada = input("Pasta com os arquivos .xlsx: ").strip().strip('"')
    pasta_saida = input("Pasta onde salvar os .csv: ").strip().strip('"')
    os.makedirs(pasta_saida, exist_ok=True)

    arquivos_xlsx = [
        a for a in os.listdir(pasta_entrada)
        if a.lower().endswith(".xlsx") and not a.startswith("~$")
    ]
    if not arquivos_xlsx:
        print("Nenhum arquivo .xlsx encontrado na pasta informada.")
        return

    for arquivo in arquivos_xlsx:
        caminho_xlsx = os.path.join(pasta_entrada, arquivo)
        print(f"\n=== Processando {arquivo} ===")

        nome_padrao = os.path.splitext(arquivo)[0]
        nome_csv = input(
            f"Nome do arquivo CSV de saída (sem .csv) [Enter = '{nome_padrao}']: "
        ).strip()
        if nome_csv == "":
            nome_csv = nome_padrao
        if not nome_csv.lower().endswith(".csv"):
            nome_csv += ".csv"
        caminho_csv = os.path.join(pasta_saida, nome_csv)

        df_completo = processar_planilha(caminho_xlsx)
        df_completo.to_csv(caminho_csv, index=False, encoding="utf-8-sig")
        print(f"OK! {arquivo} -> {nome_csv}")

    print("\nConcluído!")


if __name__ == "__main__":
    main()