using JuMP
using Printf
using Gurobi



if isfile("modelo1.txt")
    println("arquivo encontrado")
else
    println("arquivo nao encontrado")
end 

U=0;
P=0;
Cmin=0;
Cmax=0;
CH = Int[]
Pref = Matrix{Int}(undef,0,0);


open("modelo1.txt", "r") do inputfile
    global U = parse(Int, readline(inputfile)) #le uma linha e quando encontra um 'enter' (/n/r) 
    global P = parse(Int, readline(inputfile)) # ele vai para a próxima linha e segue guardado os dados
    global Cmin = parse(Int, readline(inputfile))
    global Cmax = parse(Int, readline(inputfile))
    
    global CH = Vector{Int}(undef, U)
    for i in 1:U
        CH[i] = parse(Int, readline(inputfile)) #lê o parametro um a um
    end

    global Pref = Matrix{Int}(undef, U, P)
    for i in 1:U
        linha = parse.(Int, split(readline(inputfile)))
        for j in 1:P
            Pref[i, j] = linha[j]
            print(Pref[i,j], " ")
        end
        println()
    end

    parametros = fill(-1.0, 9) #vetor preenchido com -1
end


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