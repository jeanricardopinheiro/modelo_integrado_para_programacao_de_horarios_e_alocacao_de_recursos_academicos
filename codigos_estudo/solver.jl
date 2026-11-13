using JuMP
using Gurobi

const MOI = JuMP.MOI

include("salvateste.jl")

function resolucao_modelo(P, U, G, S, D, H, T, Gt, Hd, Hdt, Up, Ug, Ut, Su, Lmax, Nt, hld, hfd1, Vu, Qs, Hu)
    caminho_lp = "arquivos_lp/aloc_horarios_lp.lp"
    model = JuMP.Model(Gurobi.Optimizer)

    #=adicionando possibilidade de multiplas soluções=#
    set_attribute(model, "PoolSearchMode", 2) #foco em soluções distintas
    set_attribute(model, "PoolSolutions", 5) #numero máximo de soluções distintas

    JuMP.set_silent(model)

    @variable(model, y[U ,H],Bin)
    @variable(model, v[P ,H],Bin)
    @variable(model, z[P , D, T],Bin)
    @variable(model, w[U , S, H],Bin)

    println("\nPASSAGEM DE DADOS - SOLVER\n")

    println("P = ", P)
    println("U = ", U)
    println("G = ", G)
    println("S = ", S)
    println("D = ", D)
    println("H = ", H)
    println("T = ", T)
    println("Gt = ", Gt)
    println("Hd = ", Hd)
    println("Hdt = ", Hdt)
    println("Up = ", Up)
    println("Ug = ", Ug)
    println("Ut = ", Ut)
    println("S = ", S)
    println("Su = ", Su)
    println("Lmax = ", Lmax)
    println("Nt = ", Nt)
    println("hld = ", hld)
    println("hfd1 = ", hfd1)
    println("Vu = ", Vu)
    println("Qs = ", Qs)

    println("\n")

    Ut_nao = Dict(t => [u for u in U if !(u in Ut[t])] for t in T)

    println("Ut = ", Ut)
    println("Ut_nao = ", Ut_nao)


    @constraint(model, R_123[u in U],sum(y[u,h] for t in T if u in Ut[t] for d in D for h in Hdt[d,t]) == Hu[u])

    @constraint(model, R_124[t in T, u in Ut_nao[t], d in D, h in Hdt[d,t]],y[u,h] == 0)

    #=@constraint(model, R_125[
        u in U,
        h in first(H):(last(H)-2),
        k in (h+2):last(H)
        ],
    y[u,h] + y[u,k] <= 1 + y[u,h+1]
    )=#

    #@constraint(model, R_1[u in U], sum(y[u,h] for h in H) == Hu[u])   #se G é um vetor e estamos interresados no que tem dentro devemos
                                                                        #fazer g in G, se G for um valor ai sim g in 1:G
    @constraint(model,R_2[g in G, h in H] ,sum(y[u,h] for u in Ug[g]) <=1)

    @constraint(model, R_3[p in P,h in H] ,sum(y[u,h] for u in Up[p]) == v[p,h])

    @constraint(model, R_4[p in P,h in H] ,v[p,h]<=1)

    @constraint(model, R_5[p in P,d in D] ,sum(v[p,h] for h in Hd[d]) <=Lmax)

    #=adicionando restrições de tempo de descanso=#
    @constraint(model, R_6[p in P,d in D[1:end-1]] ,(v[p,hld[d]])+(v[p,hfd1[d]])<=1) #(2) ultimo e primeiro

    @constraint(model, R_7[p in P,d in D[1:end-1]] ,(v[p,hld[d]-1])+(v[p,hfd1[d]])<=1) #(1) penultimo e primeiro

    @constraint(model, R_8[p in P,d in D[1:end-1]] ,(v[p,hld[d]])+(v[p,hfd1[d]+1])<=1) #(3) ultimo e segundo
    #==#

    #@constraint(model, R_9[j in J,d in D[1:end-1]] ,(v[j,tud[d]])+(v[j,tpdd[d]])<=1) # jornada de descanso minimo (descartável?)

    @constraint(model, R_9[p in P, d in D, t in T],sum(v[p,h] for h in Hdt[d,t]) <= ( Nt[t] * z[p,d,t] ) )

    @constraint(model, R_10[p in P,d in D] ,sum(z[p,d,t] for t in T) <= 2)

    #constraint(model, R_11[p in P] , sum(sum(v[p,h] for h in Hd[h]) for d in D[d]) == sum(H[u] for u in Up[u])) (dispensável)

    @constraint(model, R_12[u in U,s in S, h in H] ,Vu[u]*w[u,s,h] <= Qs[s])

    @constraint(model, R_13[s in S,h in H] ,sum(w[u,s,h] for u in U) <= 1)

    @constraint(model, R_14[g in G,h in H] ,sum(sum(w[u,s,h] for s in S) for u in Ug[g]) <= 1)

    #=novas restricoes 06-10=#

    @constraint(model, R_15[p in P,h in H] ,sum(sum(w[u,s,h] for s in S) for u in Up[p]) == v[p,h])
    
    #@constraint(model, R_16[p in P,h in H] ,v[p,h] <= 1) #já existe a restrição 4 que é exatamente igual
    #=
    S_nao = [Int64[] for s in S]

    for s in S
        for u in U
            if !(s in Su[u])
                push!(S_nao[s], u)
            end
        end
    end

    println("Su   = ", Su)
    println("S_nao = ", S_nao)
    =#
    S_nao = Dict(u => [s for s in S if !(s in Su[u])] for u in U)

    println("S_nao = ", S_nao)

    @constraint(model, R_17[u in U, s in S_nao[u], h in H], w[u,s,h] == 0) #restricao problematica

    #restricoes dia 27-10#

    @constraint(model, R_18[u in U,#=s in S_nao[u],=# h in H], y[u,h] == sum(w[u,s,h] for s in S))

    write_to_file(model, caminho_lp)

    JuMP.optimize!(model)

    status = JuMP.termination_status(model)
    
    if status == MOI.INFEASIBLE || status == MOI.INFEASIBLE_OR_UNBOUNDED
    # Accessa o ponteiro C do Gurobi diretamente
        grb_model = JuMP.unsafe_backend(model)
    
    # Executa o IIS e exporta o arquivo
        Gurobi.GRBcomputeIIS(grb_model)
        Gurobi.GRBwrite(grb_model, "modelo_inviavel.ilp")
    
        println("Arquivo 'modelo_inviavel.ilp' gerado com sucesso!")
    end
    

    num_solucoes = result_count(model)
    println("encontradas $num_solucoes soluções")

    #status = JuMP.termination_status(model)
    primal = JuMP.primal_status(model)
    println("\nStatus da Solucao: ", status, " (primal: ", primal, ")")

    salvaVariavel(w,U,S,H,y)
    
    
    return status, primal, w, num_solucoes;
end
