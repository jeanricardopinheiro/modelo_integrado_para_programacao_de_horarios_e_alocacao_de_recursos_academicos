// 1) trocar de aba
document.querySelectorAll(".aba").forEach(botao => {
  botao.addEventListener("click", () => {
    document.querySelectorAll(".aba").forEach(b => b.classList.remove("ativa"));
    document.querySelectorAll(".painel").forEach(p => p.classList.remove("visivel"));
    botao.classList.add("ativa");
    document.getElementById(botao.dataset.alvo).classList.add("visivel");
  });
});

//menu principal
async function carregarMenu() {
  const l2Info = await pywebview.api.infoMenu();
  document.getElementById("info-menu").innerText =
    "Seja bem vindo! " + l2Info.opcao;
}

// 2) a planilha
const aba = (nome, dados = [], extra = {}) => ({
  defaultColWidth: 150,
  defaultRowHeight: 32,
  tableOverflow: true,
  tableWidth: "100%",
  tableHeight: "600px",
  worksheetName: nome,
  data: dados,
  ...extra,
});

const planilha = jspreadsheet(document.getElementById("planilha"), {
    worksheets: [
    aba("turnos", [], {minDimensions:[3,4]}),
    aba("parametros", [], {minDimensions:[3,2]}),
    aba("salas_labs", [], {minDimensions:[4,70]}),
    aba("professores", [], {minDimensions:[2,40]}),
    aba("turmas", [], {minDimensions:[2,11]}),
    aba("disciplinas_info", [], {minDimensions:[5,70]}),
    aba("discentes_e_dados", [], {minDimensions:[4,40]}),
    aba("turmas_e_dados", [], {minDimensions:[3,11]}),
    aba("dados", [], {minDimensions:[3,22]}),
  ],
});

// 3) botões que falam com o Python
document.getElementById("btn-exportar").addEventListener("click", async () => {
  const msg = await pywebview.api.salvar_csv(planilha[0].getData());
  alert(msg);
});

async function carregarInfo() {
  const l1Info = await pywebview.api.info();
  document.getElementById("info-texto").innerText =
    "Versão: " + l1Info.versao + " | Informações: " + l1Info.informa;
}

document.getElementById("btn-atualizar").addEventListener("click", carregarInfo);
document.getElementById("btn-atualizar-menu").addEventListener("click", carregarMenu);

window.addEventListener("pywebviewready", () => {
  carregarInfo();
  carregarMenu();
});