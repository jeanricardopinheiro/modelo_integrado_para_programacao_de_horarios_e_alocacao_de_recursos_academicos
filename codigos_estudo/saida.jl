using CSV
using DataFrames
using JuMP
import MathOptInterface as MOI

function le_codigos()

    codigos_unidade = DataFrame(CSV.File("planilhas_dados/disciplinas_e_dados.csv"))
    codigos_professor = DataFrame(CSV.File("planilhas_dados/professores.csv"))
    codigos_salas = DataFrame(CSV.File("planilhas_dados/salas_labs.csv"))
    codigos_semana = DataFrame(CSV.File("planilhas_dados/semana.csv"))
    codigos_turma = DataFrame(CSV.File("planilhas_dados/turmas.csv"))

    # Dicionários -> para ler os dados mais facilmente, chama pelo código
    # e ele associa diretamente com a outra coluna
    unidade = Dict(codigos_unidade.CODIGO .=> codigos_unidade.DISCIPLINA)
    professor = Dict(codigos_professor.CODIGO .=> codigos_professor.PROFESSORES)
    salas = Dict(codigos_salas.CODIGO .=> codigos_salas.SALA)
    semana = Dict(codigos_semana.CODIGO .=> codigos_semana.DIA)
    turma = Dict(codigos_turma.CODIGO .=> codigos_turma.TURMA)

    return unidade, professor, salas, semana, turma

end


# Quebra um texto em linhas de no máximo `larg` caracteres, sem cortar palavras
function quebra(texto, larg)

    linhas = String[]
    atual = ""

    for palavra in split(texto)
        if isempty(atual)
            atual = String(palavra)
            elseif length(atual) + 1 + length(palavra) <= larg
            atual *= " " * palavra
        else
            push!(linhas, atual)
            atual = String(palavra)
        end
    end

    isempty(atual) || push!(linhas, atual)

    # Palavra maior que a coluna: corta com reticências
    return [length(l) > larg ? first(l, larg - 1) * "…" : l for l in linhas]

end

function sobrenome(nome)
    return String(last(split(nome)))
end


function mostra_resultado(status, primal, w, D, Hd, G, Up, Ug, U, S, P; larg = 20)

    unidade, professor, salas, semana, turma = le_codigos()

    if primal == MOI.FEASIBLE_POINT

        if status != MOI.OPTIMAL
            println("Atenção: o solver parou com status $status; a solução abaixo é viável")
        end

        w_opt = JuMP.value.(w)

        profs_unidade = Dict(u => [p for p in eachindex(Up) if u in Up[p]] for u in U)

            # Retorna as linhas de texto da célula (turma g, horário h)
        function celula(g, h)

            for u in Ug[g]
                for s in S
                    if w_opt[u, s, h] > 0.5

                        profs = join([sobrenome(professor[p]) for p in profs_unidade[u]]," + ")

                        return vcat(quebra(unidade[u], larg),quebra(profs, larg),["Sala $(salas[s])"],)

                        end
                    end
                end

                return ["-"]

            end

            println("\nAlocação dos horários")

            n_slots = maximum(length(Hd[d]) for d in D)
            lr = length("Slot $n_slots")

            sep = repeat("-", lr) * join(["+" * repeat("-", larg + 2) for _ in D])

                for g in G

                    println("\nTurma $(turma[g])")

                    println(rpad("", lr) * join(["| " * rpad(string(semana[d]), larg) * " " for d in D]))

                    println(sep)

                    for m in 1:n_slots

                        cels = [m <= length(Hd[d]) ? celula(g, Hd[d][m]) : [""] for d in D]

                        altura = maximum(length.(cels))

                            for l in 1:altura

                                rotulo = l == 1 ? "Slot $m" : ""

                                println(rpad(rotulo, lr) * join(["| " * rpad(l <= length(c) ? c[l] : "", larg) * " " for c in cels]))

                            end
                        println(sep)
                    end
                end
        else
        println("Nenhuma solução viável foi encontrada (status: $status).")

    end

end
