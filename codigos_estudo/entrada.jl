using CSV
using DataFrames
using REPL.TerminalMenus

function busca_de_arquivo()
    pasta = "planilhas_drive"

    # Verifica se a pasta existe
    if !isdir(pasta)
        error("A pasta '$pasta' não foi encontrada.")
    end

    # Lista apenas arquivos, não subpastas
    arquivos = filter(
        arquivo -> isfile(joinpath(pasta, arquivo)),
        readdir(pasta)
    )

    # Ordena os nomes alfabeticamente
    sort!(arquivos)

    # Verifica se existem arquivos disponíveis
    if isempty(arquivos)
        error("Nenhum arquivo encontrado na pasta '$pasta'.")
    end

    # Cria o menu interativo
    menu = RadioMenu(
        arquivos;
        pagesize = 10,
        charset = :unicode
    )

    # Exibe o menu e recebe a escolha
    escolha = request(
        "Selecione o arquivo com as setas e pressione Enter:",
        menu
    )

    # Trata o cancelamento
    if escolha == -1
        println("Seleção cancelada.")
        return nothing
    end

    # Monta o caminho completo
    caminho = joinpath(pasta, arquivos[escolha])

    println("Arquivo selecionado: ", arquivos[escolha])

    return caminho
end
#=function busca_de_arquivo()
    pasta = "planilhas_drive"
    if isdir(pasta)
        arquivos = readdir(pasta)
        println("Arquivos disponíveis na pasta '$pasta':")
        for arquivo in arquivos
            println(" - ", arquivo)
        end
        println("-" ^ 30)
    else
        println("A pasta '$pasta' não foi encontrada.")
        exit()
    end

    print("Digite o nome do arquivo para o modelo: ")
    nome_arquivo = readline()
    caminho = joinpath(pasta, nome_arquivo)
    if isfile(caminho)
        println("Arquivo encontrado!")
    else
        println("Arquivo não encontrado.")
        exit()
    end 
    
    return caminho
end=#

function ler_parametros(caminho)
    dados = DataFrame(CSV.File(caminho))
    valores = Dict{String, Any}()

    for linha in eachrow(dados)

        nome = String(linha.NOME)
        tipo = linha.TIPO
        valor = linha.VALOR

        if tipo == "scalar"

            valores[nome] = parse(Int, valor)

        elseif tipo == "vector"

            valores[nome] = parse.(Int, split(valor))

        elseif tipo == "vector_in_vector"

            valores[nome] = [
                parse.(Int, split(parte))
                for parte in split(valor, ';')
            ]

        elseif tipo == "matrix_of_vector"

            linhas_str  = split(valor, ';')                      # cada linha = um dia
            n_linhas    = length(linhas_str)                      # D
            n_colunas   = length(split(linhas_str[1], ','))        # P

            matriz = Matrix{Vector{Int}}(undef, n_linhas, n_colunas)

            for (d, linha_str) in enumerate(linhas_str)
                colunas_str = split(linha_str, ',')
                for (p, elemento) in enumerate(colunas_str)
                    matriz[d, p] = parse.(Int, split(elemento))
                end
            end

            valores[nome] = matriz

        else

            error("Tipo desconhecido: $tipo")
        end

    end

    println("\nLENDO DADOS - ENTRADA\n")

    println("p = ", valores["p"])
    println("u = ", valores["u"])
    println("g = ", valores["g"])
    println("s = ", valores["s"])
    println("d = ", valores["d"])
    println("h = ", valores["h"])
    println("t = ", valores["t"])
    println("gt = ", valores["gt"])
    println("hd = ", valores["hd"])
    println("hdt = ", valores["hdt"])
    println("up = ", valores["up"])
    println("ug = ", valores["ug"])
    println("ut = ", valores["ut"])
    println("s = ", valores["s"])
    println("su = ", valores["su"])
    println("lmax = ", valores["lmax"])
    println("nt = ", valores["nt"])
    println("hld = ", valores["hld"])
    println("hfd1 = ", valores["hfd1"])
    println("vu = ", valores["vu"])
    println("qs = ", valores["qs"])
    println("hu = ", valores["hu"])

    println("\n")

    return valores["p"], valores["u"], valores["g"], valores["s"], valores["d"],
           valores["h"], valores["t"], valores["gt"], valores["hd"], valores["hdt"], valores["up"],
           valores["ug"], valores["ut"], valores["su"], valores["lmax"],valores["nt"],
           valores["hld"], valores["hfd1"], valores["vu"], valores["qs"], valores["hu"];

end
