#importando arquivos
include("entrada.jl")
include("solver.jl")
include("saida.jl")

function main()
    caminho = busca_de_arquivo();
    T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, Tud, Tpdd , Hi, I, J, K, Ki, Vi, Qk = ler_parametros(caminho);
    estado, primal, w, num_solucoes = resolucao_modelo(T, D, Sd, P, Sdp, G, Ij, Ig, Lmax, Np, Tud, Tpdd, Hi, I, J, K, Ki, Vi, Qk);
    for cont in 1:num_solucoes
        valor_atual = value.(w, result = cont)
        mostra_resultado(estado, primal, valor_atual, D, Sd, G, Ij, Ig, I , K);
    end
end

main()