using JuMP
using Gurobi
using CSV
using DataFrames
#import MathOptInterface as MOI

function busca_de_arquivo()
    pasta = "planilhas_csv"
    if isdir(pasta)
        arquivos = readdir(pasta)
        println("Arquivos disponíveis na pasta '$pasta':")
        for arquivo in arquivos
            println(" - ", arquivo)
        end
        println("-" ^ 30)
    else
        println("A pasta '$pasta' não foi encontrada.")
        exit()
    end

    print("Digite o nome do arquivo para o modelo: ")
    nome_arquivo = readline()
    caminho = joinpath(pasta, nome_arquivo)
    if isfile(caminho)
        println("Arquivo encontrado!")
    else
        println("Arquivo não encontrado.")
        exit()
    end 
    
    return caminho
end

function ler_parametros(caminho)
    dados = DataFrame(CSV.File(caminho))
    valores = Dict{String, Any}()

    for linha in eachrow(dados)

        nome = String(linha.NOME)
        tipo = linha.TIPO
        valor = linha.VALOR

        if tipo == "scalar"

            valores[nome] = parse(Int, valor)

        elseif tipo == "vector"

            valores[nome] = parse.(Int, split(valor))

        elseif tipo == "vector_in_vector"

            valores[nome] = [
                parse.(Int, split(parte))
                for parte in split(valor, ';')
            ]

        elseif tipo == "matrix_of_vector"

            linhas_str  = split(valor, ';')                      # cada linha = um dia
            n_linhas    = length(linhas_str)                      # D
            n_colunas   = length(split(linhas_str[1], ','))        # P

            matriz = Matrix{Vector{Int}}(undef, n_linhas, n_colunas)

            for (d, linha_str) in enumerate(linhas_str)
                colunas_str = split(linha_str, ',')
                for (p, elemento) in enumerate(colunas_str)
                    matriz[d, p] = parse.(Int, split(elemento))
                end
            end

            valores[nome] = matriz

        else

            error("Tipo desconhecido: $tipo")
        end

    end
    println("lmax = ", valores["lmax"])
    println("np = ", valores["np"])
    println("hi = ", valores["hi"])
    println("ij = ", valores["ij"])
    println("ig = ", valores["ig"])
    println("T = ", valores["T"])
    println("D = ", valores["D"])
    println("P = ", valores["P"])
    println("G = ", valores["G"])
    println("I = ", valores["I"])
    println("J = ", valores["J"])
    println("Sd = ", valores["Sd"])
    println("Sdp = ", valores["Sdp"])
    println("tud = ", valores["tud"])
    println("tpdd = ", valores["tpdd"])
    #=novos conjuntos a serem adicionados=#
    println("K = ", valores["K"])
    println("ki = ", valores["ki"])
    println("vi = ", valores["vi"])
    println("qk = ", valores["qk"])


    return valores["T"], valores["D"], valores["Sd"], valores["P"], valores["Sdp"],
           valores["G"], valores["ij"], valores["ig"], valores["lmax"], valores["np"],
           valores["tud"], valores["tpdd"], valores["hi"], valores["I"], valores["J"],
           valores["K"],valores["ki"],valores["vi"],valores["qk"];

end

function resolucao_modelo(T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, tud, tpdd, H_i, I, J, K, K_i, V_i, Q_k)
    caminho_lp = "arquivos_lp/aloc_horarios_lp.lp"
    model = JuMP.Model(Gurobi.Optimizer)
    JuMP.set_silent(model)

    @variable(model, y[I ,T],Bin)
    @variable(model, v[J ,T],Bin)
    @variable(model, z[J , D, P],Bin)
    @variable(model, w[I , K, T],Bin)


    println("I = ", I)
    println("T = ", T)
    println("G = ", G)
    println("Ig = ", Ig)
    println("Ij = ", Ij)
    println("J = ", J)
    println("D = ", D)
    println("P = ", P)
    println("K = ", K)
    println("K_i = ", K_i)
    println("V_i = ", V_i)
    println("Q_k = ", Q_k)

    @constraint(model, R_4[i in I], sum(y[i,t] for t in T) == H_i[i])   #se G é um vetor e estamos interresados no que tem dentro devemos
                                                                        #fazer g in G, se G for um valor ai sim g in 1:G
    @constraint(model,R_5[g in G, t in T] ,sum(y[i,t] for i in Ig[g]) <=1)

    @constraint(model, R_6[j in J,t in T] ,sum(y[i,t] for i in Ij[j]) == v[j,t])

    @constraint(model, R_7[j in J,t in T] ,v[j,t]<=1)

    @constraint(model, R_8[j in J,d in D] ,sum(v[j,t] for t in Sd[d]) <=Lmax)

    #@constraint(model, R_9[j in J,d in D[1:end-1]] ,(v[j,tud[d]])+(v[j,tpdd[d]])<=1) # jornada de descanso minimo (descartável?)

    #=adicionando restrições de tempo de descanso=#
    @constraint(model, R_9_1[j in J,d in D[1:end-1]] ,(v[j,tud[d]-1])+(v[j,tpdd[d]])<=1) #(1) penultimo e primeiro

    @constraint(model, R_9_2[j in J,d in D[1:end-1]] ,(v[j,tud[d]])+(v[j,tpdd[d]])<=1) #(2) ultimo e primeiro

    @constraint(model, R_9_3[j in J,d in D[1:end-1]] ,(v[j,tud[d]])+(v[j,tpdd[d]+1])<=1) #(3) ultimo e segundo
    #==#

    @constraint(model, R_10[j in J, d in D, p in P],sum(v[j,t] for t in Sdp[d,p]) <= Np[p] * z[j,d,p])

    @constraint(model, R_11[j in J,d in D] ,sum(z[j,d,p] for p in P) <= 2)

    @constraint(model, R_12[i in I,k in K, t in T] ,V_i[i]*w[i,k,t] <= Q_k[k])

    @constraint(model, R_13[k in K,t in T] ,sum(w[i,k,t] for i in I) <= 1)

    @constraint(model, R_14[g in G,t in T] ,sum(sum(w[i,k,t] for k in K) for i in Ig[g]) <= 1)

    #=novas restricoes 06-10=#

    @constraint(model, R_15[j in J,t in T] ,sum(sum(w[i,k,t] for k in K) for i in Ij[j]) == v[j,t])
    
    @constraint(model, R_16[j in J,t in T] ,v[j,t] <= 1)

    @constraint(model, R_17[i in I, k in K, t in T; !(k in K_i[i])], w[i,k,t] == 0) #nao existe 'not' entao tem que usar o !

    write_to_file(model, caminho_lp)

    JuMP.optimize!(model)

    status = JuMP.termination_status(model)
    primal = JuMP.primal_status(model)
    println("\nStatus da Solucao: ", status, " (primal: ", primal, ")")
    return status, primal, w;
end


function mostra_resultado(status, primal, w, D, Sd, G, Ij, Ig, I, K)
    if primal == MOI.FEASIBLE_POINT
        if status != MOI.OPTIMAL
            println("Atenção: o solver parou com status $status; a solução abaixo é viável")
        end

        w_opt = JuMP.value.(w)

        profs_unidade = Dict(
            i => [j for j in eachindex(Ij) if i in Ij[j]]
            for i in I
        )

        function celula(g, t)
            for i in Ig[g]
                for k in K
                    if w_opt[i, k, t] > 0.5
                        profs = join(profs_unidade[i], "+P")
                        return "U$i/P$profs/K$k"
                    end
                end
            end
            return "-"
        end

        println("\nAlocação dos horários (U = unidade, P = professor, K = sala)")

        n_slots = maximum(length(Sd[d]) for d in D)
        larg_rot = maximum(length("Dia $d") for d in D)

        for g in G
            tabela = [
                m <= length(Sd[d]) ? celula(g, Sd[d][m]) : ""
                for d in D, m in 1:n_slots
            ]

            cab = ["Slot $m" for m in 1:n_slots]
            larg = max(maximum(length.(tabela)), maximum(length.(cab)))

            println("\nTurma $g")
            println(
                rpad("", larg_rot), " | ",
                join([rpad(c, larg) for c in cab], " | ")
            )

            println(repeat("-", larg_rot + 3 + n_slots * larg + 3 * (n_slots - 1)))

            for (r, d) in enumerate(D)
                println(
                    rpad("Dia $d", larg_rot), " | ",
                    join([rpad(tabela[r, m], larg) for m in 1:n_slots], " | ")
                )
            end
        end

    else
        println("Nenhuma solução viável foi encontrada (status: $status).")
    end
end

function main()
    caminho = busca_de_arquivo();
    T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, tud, tpdd , H_i, I, J, K, K_i, V_i, Q_k = ler_parametros(caminho);
    estado, primal, w = resolucao_modelo(T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, tud, tpdd, H_i, I, J, K, K_i, V_i, Q_k);
    mostra_resultado(estado, primal, w, D, Sd, G, Ij, Ig, I , K);
end

main()