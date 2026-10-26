import os
import requests

from datetime import datetime
from pathlib import Path

def selecionar_pasta(diretorio_atual="."):
    caminho = Path(diretorio_atual).resolve()

    while True:
        print(f"\nPasta atual: {caminho}")

        # Lista apenas subpastas
        subpastas = [d for d in caminho.iterdir() if d.is_dir()]

        # Exibe opções básicas
        print("0: [ Selecionar esta pasta ]")
        print("1: [ Voltar / Pasta acima ]")
        for i, pasta in enumerate(subpastas, start=2):
            print(f"{i}: {pasta.name}")

        try:
            escolha = int(input("\nDigite o número: "))

            if escolha == 0:
                return str(caminho)
            elif escolha == 1:
                caminho = caminho.parent
            elif 2 <= escolha < len(subpastas) + 2:
                # Entra na subpasta e continua o loop
                caminho = subpastas[escolha - 2]
            else:
                print("Opção inválida.")
        except ValueError:
            print("Digite apenas números.")


#colocar o URL da página 
#https://docs.google.com/spreadsheets/d/1E_H_YNE5hjf5Fq9Yr0QEZ1g1gthpkQDFkbj4IsVQpos/edit?gid=1307573813#gid=1307573813

# 1. Configurações da Planilha
SPREADSHEET_ID = "1E_H_YNE5hjf5Fq9Yr0QEZ1g1gthpkQDFkbj4IsVQpos"
GID = "1307573813"  # O número do #gid= no final da URL da aba (no meu caso a aba 'dados')

# 2. Configurações de Destino no Computador

#define nome padrão como uma string da data hora atual
nome_padrao = datetime.now().strftime('%Y-%m-%d_%H_%M_%S')
nome_csv = input(
    f"Nome do arquivo CSV de saída (sem .csv) [Enter = '{nome_padrao}']: "
    ).strip()
if nome_csv == "":
    nome_csv = nome_padrao
if not nome_csv.lower().endswith(".csv"):
    nome_csv += ".csv"

#NOME_ARQUIVO = "minha_aba.csv"

pasta_destino = selecionar_pasta()

# Monta o URL de exportação do Google Sheets
url = f"https://docs.google.com/spreadsheets/d/{SPREADSHEET_ID}/export?format=csv&gid={GID}"

# Garante que a pasta de destino exista no computador (cria se não existir)
os.makedirs(pasta_destino, exist_ok=True)

# Monta o caminho completo onde o arquivo será salvo
caminho_completo = os.path.join(pasta_destino, nome_csv)

print("Iniciando o download...")
response = requests.get(url)

if response.status_code == 200:
    # Salva o conteúdo baixado no caminho especificado
    with open(caminho_completo, "wb") as f:
        f.write(response.content)
    print(f"Sucesso! Arquivo salvo em: {caminho_completo}")
else:
    print(f"Erro no download. Código de status HTTP: {response.status_code}")
    print("Verifique se a planilha está configurada como 'Qualquer pessoa com o link pode ver'.")