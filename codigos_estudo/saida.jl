using JuMP

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