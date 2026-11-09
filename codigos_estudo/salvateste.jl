using JuMP
using DataFrames
using CSV

function salvaVariavel(variavel_entrada_w,I,K,T,variavel_entrada_y)
    # 1. Extrai os valores do modelo
    copia_salvar = JuMP.value.(variavel_entrada_w)
    #copia_salvar = variavel_entrada

    # 2. Constrói a lista de linhas para o DataFrame
    # (Funciona tanto para índices Numéricos (1:N) quanto para Nomes/Conjuntos)
    df = DataFrame(
        i = [i for i in I for k in K for t in T],
        k = [k for i in I for k in K for t in T],
        t = [t for i in I for k in K for t in T],
        valor = [copia_salvar[i, k, t] for i in I for k in K for t in T]
    )

    #filter!(row -> row.valor > 0.5, df)

    # 3. Salva no arquivo CSV
    CSV.write("resultado_wsf.csv", df)

    copia_salvar = JuMP.value.(variavel_entrada_y)
    
    # 2. Constrói a lista de linhas para o DataFrame
    # (Funciona tanto para índices Numéricos (1:N) quanto para Nomes/Conjuntos)
    df = DataFrame(
        i = [i for i in I for t in T],
        t = [t for i in I for t in T],
        valor = [copia_salvar[i, t] for i in I for t in T]
    )

    filter!(row -> row.valor > 0.5, df)

    # 3. Salva no arquivo CSV
    CSV.write("resultado_yf.csv", df)
end