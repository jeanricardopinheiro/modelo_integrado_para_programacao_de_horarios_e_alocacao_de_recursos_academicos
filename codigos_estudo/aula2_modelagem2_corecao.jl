using JuMP
using Gurobi
using CSV
using DataFrames

function busca_de_arquivo()
    print("Digite o nome do arquivo para o modelo: ")
    nome_arquivo = readline()
    caminho = "planilhas_csv/$nome_arquivo"
    if isfile(caminho)
        println("arquivo encontrado")
    else
        println("arquivo nao encontrado")
        exit()
    end 
    return caminho;
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


    return valores["T"], valores["D"], valores["Sd"], valores["P"], valores["Sdp"],
           valores["G"], valores["ij"], valores["ig"], valores["lmax"], valores["np"],
           valores["tud"], valores["tpdd"], valores["hi"], valores["I"], valores["J"];

end

function resolucao_modelo(T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, t_ud, t_pd, H_i, I, J)
    caminho_lp = "arquivos_lp/modelo1_teste.lp"
    model = JuMP.Model(Gurobi.Optimizer)
    JuMP.set_silent(model)

    @variable(model, y[I ,T],Bin)
    @variable(model, v[J ,T],Bin)
    @variable(model, z[J ,D, P],Bin)

    println("I = ", I)
    println("T = ", T)
    println("G = ", G)
    println("Ig = ", Ig)
    println("Ij = ", Ij)
    println("J = ", J)
    println("D = ", D)
    println("P = ", P)

    @constraint(model, R_4[i in I], sum(y[i,t] for t in T) == H_i[i])   #se G é um vetor e estamos interresados no que tem dentro devemos
                                                                        #fazer g in G, se G for um valor ai sim g in 1:G
    @constraint(model,R_5[g in G, t in T] ,sum(y[i,t] for i in Ig[g]) <=1)

    @constraint(model, R_6[j in J,t in T] ,sum(y[i,t] for i in Ij[j]) == v[j,t])

    @constraint(model, R_7[j in J,t in T] ,v[j,t]<=1)

    @constraint(model, R_8[j in J,d in D] ,sum(v[j,t] for t in Sd[d]) <=Lmax)

    @constraint(model, R_9[j in J,d in D[1:end-1]] ,(v[j,t_ud[d]])+(v[j,t_pd[d]])<=1)

    #=adicionando restrições=#
    @constraint(model, R_9_1[j in J,d in D[1:end-1]] ,(v[j,t_ud[d]-1])+(v[j,t_pd[d]])<=1)

    @constraint(model, R_9_2[j in J,d in D[1:end-1]] ,(v[j,t_ud[d]])+(v[j,t_pd[d]+1])<=1)


    #==#

    @constraint(model, R_10[j in J, d in D, p in P],sum(v[j,t] for t in Sdp[d,p]) <= Np[p] * z[j,d,p])

    @constraint(model, R_11[j in J,d in D] ,sum(z[j,d,p] for p in P) <= 2)


    write_to_file(model, caminho_lp)

    JuMP.optimize!(model)

    status = JuMP.termination_status(model)
    println("\nStatus da Solucao: ", status)
    return status, y;
end

 function mostra_resultado(status, y, T, I, J,Ij)
        if status == MOI.OPTIMAL || status == MOI.FEASIBLE_POINT
        y_opt = JuMP.value.(y)
        println("\nAlocação dos horários:")
            for i in I
                for t in T
                    if y_opt[i, t] == 1
                        prof =0;
                        for a in eachindex(Ij)
                            vet = Int[];
                            vet = Ij[a];
                            for b in eachindex(vet)
                                if vet[b] == i
                                    prof = a;
                                    println("no horário $t a unidade $i ocorre ministrada por $prof")
                                end
                            end
                        end
                    end
                end
            end
        else
            println("Nenhuma solução viável foi encontrada.")  
        end
    end



function main()
    caminho = busca_de_arquivo();
    T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, t_ud, t_pd , H_i, I, J = ler_parametros(caminho);
    estado, y = resolucao_modelo(T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, t_ud, t_pd, H_i, I, J);
    mostra_resultado(estado, y, T, I,J,Ij);
end

main()