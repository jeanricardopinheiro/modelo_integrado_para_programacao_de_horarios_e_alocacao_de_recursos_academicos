import os
import pandas as pd

# Pede as pastas ao usuário
pasta_entrada = input("Pasta com os arquivos .xlsx: ").strip().strip('"')
pasta_saida = input("Pasta onde salvar os .csv: ").strip().strip('"')

# Cria a pasta de saída se não existir
os.makedirs(pasta_saida, exist_ok=True)

# Percorre todos os arquivos .xlsx da pasta de entrada
for arquivo in os.listdir(pasta_entrada):
    if arquivo.lower().endswith(".xlsx") and not arquivo.startswith("~$"):
        caminho_xlsx = os.path.join(pasta_entrada, arquivo)
        nome_csv = os.path.splitext(arquivo)[0] + ".csv"
        caminho_csv = os.path.join(pasta_saida, nome_csv)

        df = pd.read_excel(caminho_xlsx)          # lê a primeira aba
        df.to_csv(caminho_csv, index=False, encoding="utf-8-sig")

        print(f"OK!{arquivo} -> {nome_csv}")

print("\nConcluído!")