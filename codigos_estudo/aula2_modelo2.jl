using JuMP
using Gurobi
using CSV
using DataFrames

function busca_de_arquivo()
    print("Digite o nome do arquivo para o modelo: ")
    nome_arquivo = readline()
    caminho = ""planilhas_csv/$nome_arquivo")"
    if isfile(caminho)
        println("arquivo encontrado")
    else
        println("arquivo nao encontrado")
    exit()
    end 
    return caminho;
end

function ler_parametros(caminho)
    T = Int[]; #vetor
    D = Int[]; #vetor
    Sd = Vector{Vector{Int}}() #vetor de vetores
    P = Int[]; #vetor
    Sdp = Matrix{Vector{Int}}(undef,0,0) #matriz de vetores
    G = Int[]; #vetor
    n_prof = 0;
    Ij = Vector{Vector{Int}}(); #vetor de vetores
    Ig = Vector{Vector{Int}}() #vetor de vetores
    Lmax = 0; #int
    Np = Int[]; #vetor 
    t_ud = Int[]; #vetor
    t_pd = Int[]; #vetor
    H_i = Int[]; #vetor
    I = Int[]; #vetor
    J = Int[]; #vetor
    open(caminho, "r") do inputfile
        linha_T = split(readline(inputfile));
        T = parse.(Int, linha_T); #conjunto de todos os slots (horarios) t da semana
        linha_D = split(readline(inputfile));
        D = parse.(Int, linha_D); #conjunto de dias da semana
        qtd_dias = length(D);
        for d in 1:qtd_dias
            linha_sd = split(readline(inputfile));
            push!(Sd, parse.(Int, linha_sd)) #conjunto de horários que pertencem ao dia d
        end
        linha_P = split(readline(inputfile));
        P = parse.(Int, linha_P); #conjunto de turnos p
        qtd_turnos = length(P);
        Sdp = Matrix{Vector{Int}}(undef, qtd_turnos, qtd_dias) #subconjunto de horários do dia d correspodentes ao turno p
        for d in 1:qtd_dias
            for p in 1:qtd_turnos
                linha_sdp = split(readline(inputfile));
                Sdp[p,d] = parse.(Int, linha_sdp) #horários do dia d que pertencem ao turno p
            end
        end
        linha_G = split(readline(inputfile));
        G = parse.(Int, linha_G); #conjunto de turmas g
        n_prof = parse(Int, readline(inputfile)); #numero de professores
        for j in 1:n_prof 
            linha_ij = split(readline(inputfile))
            push!(Ij, parse.(Int, linha_ij)) #subconjunto de unidades ministradas pelo professor j
        end
        qtd_turmas = length(G);
        for g in 1:qtd_turmas
            linha_ig = split(readline(inputfile));
            push!(Ig, parse.(Int, linha_ig)) #subconjunto de unidades curriculares que a turma g cursa
        end
        Lmax = parse(Int, readline(inputfile)) #limite de aulas por dia para um professor
        linha_Np = split(readline(inputfile));
        Np = parse.(Int, linha_Np); #numero total de slots no turno p
        linha_tud = split(readline(inputfile)); 
        t_ud = parse.(Int, linha_tud); #incice do ultimo horário noturno do dia
        linha_tpd = split(readline(inputfile));
        t_pd = parse.(Int, linha_tpd); #indice do primeiro ho´rario matutino do prox dia
        linha_Hi = split(readline(inputfile));
        H_i = parse.(Int, linha_Hi); #carga horária semanal para a unidade curricular i
        I = collect(1:length(H_i)); #conjunto de unidades curriculares
        J = collect(1:length(Ij)); #conjunto de professores
        println("H_i = ", H_i)
        println("length(H_i) = ", length(H_i))
        println("I = ", I)
    end

    return T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, t_ud, t_pd, H_i, I, J;

end

function resolucao_modelo(T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, t_ud, t_pd, H_i, I, J)
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

    @constraint(model, [i in I], sum(y[i,t] for t in T) == H_i[i])   #se G é um vetor e estamos interresados no que tem dentro devemos
                                                                        #fazer g in G, se G for um valor ai sim g in 1:G
    @constraint(model,[g in G, t in T] ,sum(y[i,t] for i in Ig[g]) <=1)

    @constraint(model, [j in J,t in T] ,sum(y[i,t] for i in Ij[j]) == v[j,t])

    @constraint(model, [j in J,t in T] ,v[j,t]<=1)

    @constraint(model, [j in J,d in D] ,sum(v[j,t] for t in Sd[d]) <=Lmax)

    @constraint(model, [j in J,d in D, p in P] ,sum(v[j,t] for t in Sdp[p,d]) <= Np[p] * z[j,d,p])

    @constraint(model, [j in J,d in D] ,sum(z[j,d,p] for p in P) <= 2)

    write_to_file(model, "modelo1_teste.lp")

    JuMP.optimize!(model)

    status = JuMP.termination_status(model)
    println("\nStatus da Solucao: ", status)
    return status, y;
end

function mostra_resultado(status, y, T, I)
    if status == MOI.OPTIMAL || status == MOI.FEASIBLE_POINT
    y_opt = JuMP.value.(y)
    println("\nAlocação dos horários:")
    for i in I
        for t in T
            if y_opt[i, t] > 0.5  # Se a variável binária for 1
                println("no horário $t a unidade $i ocorre")
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
    mostra_resultado(estado, y, T, I);
end

main()  