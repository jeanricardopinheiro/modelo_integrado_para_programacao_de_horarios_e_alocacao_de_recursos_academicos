formula.setFormula({
  // uso na célula: =DOBRO(A1)
  DOBRO: function (x) {
    return Number(x) * 2;
  },

  // uso: =SAUDACAO("Ana")
  SAUDACAO: function (nome) {
    return "Olá, " + nome + "!";
  },
});