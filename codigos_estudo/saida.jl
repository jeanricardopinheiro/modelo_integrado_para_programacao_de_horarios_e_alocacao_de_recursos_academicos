using JuMP

function mostra_resultado(status, primal, w, D, Hd, G, Up, Ug, U , S, P)
    if primal == MOI.FEASIBLE_POINT
        if status != MOI.OPTIMAL
            println("Atenção: o solver parou com status $status; a solução abaixo é viável")
        end

        w_opt = JuMP.value.(w)

        profs_unidade = Dict(
            u => [p for P in eachindex(Ij) if u in Up[p]]
            for u in U
        )

        function celula(g, h)
            for u in Ug[g]
                for s in S
                    if w_opt[u, s, h] > 0.5
                        profs = join(profs_unidade[u], "+P")
                        return "U$u/P$profs/K$k"
                    end
                end
            end
            return "-"
        end

        println("\nAlocação dos horários (U = unidade, P = professor, K = sala)")

        n_slots = maximum(length(Hd[d]) for d in D)
        larg_rot = maximum(length("Dia $d") for d in D)

        for g in G
            tabela = [
                m <= length(Hd[d]) ? celula(g, Hd[d][m]) : ""
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
