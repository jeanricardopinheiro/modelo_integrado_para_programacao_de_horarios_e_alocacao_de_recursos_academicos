#importando arquivos
include("entrada.jl")
include("solver_teste.jl")
include("saida.jl")

function main()
    caminho = busca_de_arquivo();
    P, U, G, S, D, H, T, Gt, Hd, Hdt, Up, Ug, Ut, Su, Lmax, Nt, hld, hfd1, Vu, Qs, Hu = ler_parametros(caminho);

    estado, primal, w, num_solucoes = resolucao_modelo_teste(P, U, G, S, D, H, T, Gt, Hd, Hdt, Up, Ug, Ut, Su, Lmax, Nt, hld, hfd1, Vu, Qs,Hu);

    for cont in 1:num_solucoes
        valor_atual = value.(w, result = cont)
        mostra_resultado(estado, primal, valor_atual, D, Hd, G, Up, Ug, U , S, P);
    end
end

main()
