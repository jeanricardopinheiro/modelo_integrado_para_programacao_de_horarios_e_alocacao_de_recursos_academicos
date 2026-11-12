using JuMP
using Gurobi

const MOI = JuMP.MOI

include("salvateste.jl")

function resolucao_modelo_teste(P, U, G, S, D, H, T, Gt, Hd, Hdt, Up, Ug, Ut, Su, Lmax, Nt, hld, hfd1, Vu, Qs, Hu)
    caminho_lp = "arquivos_lp/aloc_horarios_lp.lp"
    model = JuMP.Model(Gurobi.Optimizer)

    #=adicionando possibilidade de multiplas soluções=#
    set_attribute(model, "PoolSearchMode", 2) #foco em soluções distintas
    set_attribute(model, "PoolSolutions", 5) #numero máximo de soluções distintas

    JuMP.set_silent(model)

    @variable(model, y[U ,H],Bin)
    #@variable(model, v[P ,H],Bin)
    #@variable(model, z[P , D, T],Bin)
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

    @constraint(model, R_1[u in U], sum(y[u,h] for h in H) == Hu[u])   #se G é um vetor e estamos interresados no que tem dentro devemos
                                                                    #fazer g in G, se G for um valor ai sim g in 1:G
    @constraint(model, R_2[g in G, h in H], sum(y[u,h] for u in Ug[g]) <=1)

    @constraint(model, R_3[p in P, d in D], sum(sum(y[u,h] for u in Up[p]) for h in Hd[d]) <= Lmax)

    @constraint(model, R_4_1[p in P, d in D[1:end-1]], (sum(y[u, hld[d]] for u in Up[p]) +
                                                        sum(y[u,hfd1[d]] for u in Up[p])) <= 1)


    @constraint(model, R_4_2[p in P, d in D[1:end-1]], (sum(y[u, hld[d]-1] for u in Up[p]) +
                                                        sum(y[u,hfd1[d]] for u in Up[p])) <= 1)


    @constraint(model, R_4_3[p in P, d in D[1:end-1]], (sum(y[u, hld[d]] for u in Up[p]) +
                                                        sum(y[u,hfd1[d]+1] for u in Up[p])) <= 1)

    @constraint(model, R_5[u in U, s in S, h in H], (w[u,s,h]*Vu[u])<=Qs[s])

    @constraint(model, R_6[s in S, h in H], sum(w[u,s,h] for u in U) <= 1)

    @constraint(model, R_7[g in G, h in H], sum(sum(w[u,s,h] for s in S) for u in Ug[g]) <= 1)

    @constraint(model, R_8[p in P, h in H], sum(sum(w[u,s,h] for s in S) for u in Up[p]) <= 1)

    S_nao = Dict(u => [s for s in S if !(s in Su[u])] for u in U)

    @constraint(model, R_9[u in U, s in S_nao[u], h in H], w[u,s,h] == 0)

    @constraint(model, R_10[u in U, s in S_nao[u], h in H], sum(w[u,s,h] for s in S) == y[u,h])

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
