using JuMP
using Gurobi

#teste de commit

if isfile("modelo2.txt")
    println("arquivo encontrado")
else
    println("arquivo nao encontrado")
    exit()
end 
function entrada_modelo()
    #printf("digite o nome do arquivo para o modelo: ")
    if isfile("modelo2.txt")
        println("arquivo encontrado")
    else
        println("arquivo nao encontrado")
    exit()
    end 
end

function ler_parametros(T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, t_ud, t_pd)
    T = Int[]; #vetor
    D = Int[]; #vetor
    Sd = Int[]; #vetor de vetores inteiros
    P = Int[]; #vetor
    Sdp = Matrix{Int}(undef,0,0);
    G = Int[]; #vetor
    Ij = Int[]; #vetor de vetores inteiros
    Ig = Int[]; #vetor de vetores inteiros
    Lmax = 0; #int
    Np = Int[]; #vetor
    t_ud = Int[]; #vetor
    t_pd = Int[]; #vetor

    open("modelo2.txt", "r") do inputfile
    linha_T = split(readline(inputfile)) #le a linha toda
    T = parse.(Int, linha_T) #isola os valores pelos espaços 'perse.'
    D = parse(Int, readline(inputfile))
    Cmin = parse(Int, readline(inputfile))
    Cmax = parse(Int, readline(inputfile))
    Sd = Int[]; #vetor de vetores inteiros
    P = parse(Int, readline(inputfile)) #vetor
    Sdp = Matrix{Int}(undef,0,0); #matriz
    G = parse(Int, readline(inputfile)) #vetor
    Ij = Int[]; #vetor de vetores inteiros
    Ig = Int[]; #vetor de vetores inteiros
    Lmax = parse(Int, readline(inputfile)); #int #le uma linha e quando encontra um 'enter' (/n/r) ele vai para a próxima linha e segue guardado os dados
    Np = Int[]; #vetor
    t_ud = Int[]; #vetor
    t_pd = Int[]; #vetor
    
    CH = Vector{Int}(undef, U)
    for i in 1:U
        CH[i] = parse(Int, readline(inputfile)) #lê o parametro um a um
    end

    Pref = Matrix{Int}(undef, U, P)
    for i in 1:U
        linha = parse.(Int, split(readline(inputfile)))
        for j in 1:P
            Pref[i, j] = linha[j]
            print(Pref[i,j], " ")
        end
        println()
    end

    return T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, t_ud, t_pd;

end

function resolucao_modelo(T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, t_ud, t_pd)
    model = JuMP.Model(Gurobi.Optimizer)
    JuMP.set_silent(model)

    @variable(model, x[1:U ,1:P],Bin)

    @objective(model, Max, sum(Pref[i,j]*x[i,j] for i in 1:U, j in 1:P))

    @constraint(model, [i=1:U],sum(x[i,j] for j in 1:P) == 1)

    @constraint(model,[j=1:P] ,sum(CH[i]*x[i,j] for i in 1:U) <=Cmax)

    @constraint(model, [j=1:P] ,sum(CH[i]*x[i,j] for i in 1:U) >=Cmin)

    write_to_file(model, "modelo1_teste.lp")

    JuMP.optimize!(model)

    status = JuMP.termination_status(model)
    println("\nStatus da Solucao: ", status)
    return status;
end

function mostra_resultado(status)
    if status == MOI.OPTIMAL || status == MOI.FEASIBLE_POINT
    println("Preferencia Total Maximizada: ", JuMP.objective_value(model))
    
    x_opt = JuMP.value.(x)
    println("\nAlocação das UCs aos Professores:")
    for i in 1:U
        for j in 1:P
            if x_opt[i, j] > 0.5  # Se a variável binária for 1
                println("UC $i (CH: $(CH[i])) -> Professor $j (Peso Pref: $(Pref[i, j]))")
            end
        end
    end
    else
        println("Nenhuma solução viável foi encontrada.")  
    end
end



function main()
    entrada_modelo();
    T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, t_ud, t_pd = ler_parametros(T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, t_ud, t_pd);
    estado = resolucao_modelo(T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, t_ud, t_pd);
    mostra_resultado(estado);


end

main()
