import csv
import os
import webview

class Api:
    def salvar_csv(self, linhas):
        caminho = os.path.join(os.path.dirname(__file__), "saida.csv")
        with open(caminho, "w", newline="", encoding="utf-8") as f:
            csv.writer(f).writerows(linhas)
        return f"Salvo em {caminho}"
    
    def info(self):
        return {"versao": "1", "informa": "Este programa aloca recursos e organiza horários acadêmicos."} #adicionado 

    def infoMenu(self):
        return {"opcao": "escolha uma das opções abaixo:"}

    def somar(self, numeros):
        # exemplo de lógica no Python
        return sum(float(n) for n in numeros if n != "")

if __name__ == "__main__":
    pasta = os.path.dirname(os.path.abspath(__file__))
    webview.create_window(
        "Modelo",
    os.path.join(pasta, "index.html"),
    js_api=Api(),
    width=1400,
    height=850,
    min_size=(900, 600),
    # maximized=True,   # abre maximizada
    # resizable=True,   # padrão
    )
    webview.start()