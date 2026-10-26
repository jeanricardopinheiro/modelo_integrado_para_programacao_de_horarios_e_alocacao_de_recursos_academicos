using JuMP
using Gurobi

function resolucao_modelo(T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, Tud, Tpdd, Hi, I, J, K, Ki, Vi, Qk)
    caminho_lp = "arquivos_lp/aloc_horarios_lp.lp"
    model = JuMP.Model(Gurobi.Optimizer)

    #=adicionando possibilidade de multiplas soluções=#
    set_attribute(model, "PoolSearchMode", 2) #foco em soluções distintas
    set_attribute(model, "PoolSolutions", 5) #numero máximo de soluções distintas

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
    println("Ki = ", Ki)
    println("Vi = ", Vi)
    println("Qk = ", Qk)

    @constraint(model, R_4[i in I], sum(y[i,t] for t in T) == Hi[i])   #se G é um vetor e estamos interresados no que tem dentro devemos
                                                                        #fazer g in G, se G for um valor ai sim g in 1:G
    @constraint(model,R_5[g in G, t in T] ,sum(y[i,t] for i in Ig[g]) <=1)

    @constraint(model, R_6[j in J,t in T] ,sum(y[i,t] for i in Ij[j]) == v[j,t])

    @constraint(model, R_7[j in J,t in T] ,v[j,t]<=1)

    @constraint(model, R_8[j in J,d in D] ,sum(v[j,t] for t in Sd[d]) <=Lmax)

    #@constraint(model, R_9[j in J,d in D[1:end-1]] ,(v[j,tud[d]])+(v[j,tpdd[d]])<=1) # jornada de descanso minimo (descartável?)

    #=adicionando restrições de tempo de descanso=#
    @constraint(model, R_9_1[j in J,d in D[1:end-1]] ,(v[j,Tud[d]-1])+(v[j,Tpdd[d]])<=1) #(1) penultimo e primeiro

    @constraint(model, R_9_2[j in J,d in D[1:end-1]] ,(v[j,Tud[d]])+(v[j,Tpdd[d]])<=1) #(2) ultimo e primeiro

    @constraint(model, R_9_3[j in J,d in D[1:end-1]] ,(v[j,Tud[d]])+(v[j,Tpdd[d]+1])<=1) #(3) ultimo e segundo
    #==#

    @constraint(model, R_10[j in J, d in D, p in P],sum(v[j,t] for t in Sdp[d,p]) <= Np[p] * z[j,d,p])

    @constraint(model, R_11[j in J,d in D] ,sum(z[j,d,p] for p in P) <= 2)

    @constraint(model, R_12[i in I,k in K, t in T] ,V_i[i]*w[i,k,t] <= Qk[k])

    @constraint(model, R_13[k in K,t in T] ,sum(w[i,k,t] for i in I) <= 1)

    @constraint(model, R_14[g in G,t in T] ,sum(sum(w[i,k,t] for k in K) for i in Ig[g]) <= 1)

    #=novas restricoes 06-10=#

    @constraint(model, R_15[j in J,t in T] ,sum(sum(w[i,k,t] for k in K) for i in Ij[j]) == v[j,t])
    
    @constraint(model, R_16[j in J,t in T] ,v[j,t] <= 1)

    K_nao = [Int64[] for k in K]

    for k in K
        for i in I
            if !(i in Ki[k])
                push!(K_nao[k], i)
            end
        end
    end

    println("Ki   = ", Ki)
    println("K_nao = ", K_nao)

    @constraint(model, R_17[k in K, i in K_nao[k], t in T], w[i,k,t] == 0)

    write_to_file(model, caminho_lp)

    JuMP.optimize!(model)

    num_solucoes = result_count(model)
    println("encontradas $num_solucoes soluções")

    status = JuMP.termination_status(model)
    primal = JuMP.primal_status(model)
    println("\nStatus da Solucao: ", status, " (primal: ", primal, ")")
    return status, primal, w, num_solucoes;
end