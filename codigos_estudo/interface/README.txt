Python 3.9 ou mais novo (você já deve ter). Teste no terminal: python --version
Node.js (só para baixar a biblioteca; depois não é mais necessário). Baixe em nodejs.org (versão LTS). Teste: node --version
=====================
mkdir agenda
cd agenda
mkdir lib
npm init -y
npm install jspreadsheet-ce
============================
copy node_modules\jspreadsheet-ce\dist\index.js lib\jspreadsheet.js
copy node_modules\jspreadsheet-ce\dist\jspreadsheet.css lib\
copy node_modules\jsuites\dist\jsuites.js lib\
copy node_modules\jsuites\dist\jsuites.css lib\
copy node_modules\@jspreadsheet\formula\dist\index.js lib\formula.js
==============================
Crie index.html na pasta agenda:

html
<!DOCTYPE html>
<html lang="pt-br">
<head>
  <meta charset="utf-8">
  <title>Agenda</title>
  <link rel="stylesheet" href="lib/jsuites.css">
  <link rel="stylesheet" href="lib/jspreadsheet.css">
  <script src="lib/jsuites.js"></script>
  <script src="lib/formula.js"></script>
  <script src="lib/jspreadsheet.js"></script>
</head>
<body>
  <div id="planilha"></div>

  <script>
    jspreadsheet(document.getElementById("planilha"), {
      worksheets: [{
        data: [
          ["Reunião", "09:00", 2, ""],
          ["Almoço",  "12:00", 1, ""],
          ["Revisão", "15:00", 3, ""],
        ],
        columns: [
          { title: "Evento", width: 200 },
          { title: "Hora",   width: 80,  readOnly: true },
          { title: "Horas",  width: 80,  type: "numeric" },
          { title: "Notas",  width: 250 },
        ],
        minDimensions: [4, 10],
      }]
    });
  </script>
</body>
</html>

==========================

Instale:

bash
pip install pywebview

Crie app.py na pasta agenda:

python
import csv
import os
import webview

class Api:
    def salvar_csv(self, linhas):
        caminho = os.path.join(os.path.dirname(__file__), "saida.csv")
        with open(caminho, "w", newline="", encoding="utf-8") as f:
            csv.writer(f).writerows(linhas)
        return f"Salvo em {caminho}"

    def somar(self, numeros):
        # exemplo de lógica no Python
        return sum(float(n) for n in numeros if n != "")

if __name__ == "__main__":
    pasta = os.path.dirname(os.path.abspath(__file__))
    webview.create_window(
        "Agenda",
        os.path.join(pasta, "index.html"),
        js_api=Api(),
    )
    webview.start()

==========================

Agora acrescente ao index.html, antes do </body>, dois botões e o código que fala com o Python. Troque o <script> do Passo 3 por este, e guarde a planilha numa variável (planilha):

html
<button onclick="exportar()">Exportar CSV</button>
<button onclick="calcular()">Somar horas (Python)</button>
<p id="resultado"></p>

<script>
  const planilha = jspreadsheet(document.getElementById("planilha"), {
    worksheets: [{
      data: [
        ["Reunião", "09:00", 2, ""],
        ["Almoço",  "12:00", 1, ""],
        ["Revisão", "15:00", 3, ""],
      ],
      columns: [
        { title: "Evento", width: 200 },
        { title: "Hora",   width: 80,  readOnly: true },
        { title: "Horas",  width: 80,  type: "numeric" },
        { title: "Notas",  width: 250 },
      ],
      minDimensions: [4, 10],
    }]
  });

  async function exportar() {
    const dados = planilha[0].getData();      // lê a grade inteira
    const msg = await pywebview.api.salvar_csv(dados);
    document.getElementById("resultado").innerText = msg;
  }

  async function calcular() {
    const dados = planilha[0].getData();
    const horas = dados.map(linha => linha[2]);  // coluna 3
    const total = await pywebview.api.somar(horas);
    document.getElementById("resultado").innerText = "Total: " + total;
  }
</script>
=======================
Rode:

bash
python app.py

=====================

