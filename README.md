# Filtro FIR Sequencial (Arquitetura MAC) project

> Projeto Orientado 1 (SD192) do Programa de formação em Micro-eletrônica e Sistemas Embarcados CI DIGITAL - T2/25, realizado pela instituição INATEL, Santa Rita do Sapucaí / MG. 

# 1 Objetivo

Implementar um filtro digital de Resposta ao Impulso Finita (FIR) utilizando uma arquitetura de hardware compartilhado. O objetivo é otimizar o uso de área da FPGA através de uma unidade de Multiplicação e Acúmulo (MAC) única, processando as amostras de forma sequencial no tempo.

# 2	Descrição do Desafio Técnico

Diferente de uma implementação paralela direta, a versão sequencial exige o domínio de três pilares da microeletrônica:

- **Gestão de Fluxo de Dados**: Uso de uma Máquina de Estados (FSM) para coordenar o reuso do multiplicador.

- **Aritmética de Ponto Fixo**: Controle de crescimento de bits, truncamento e prevenção de overflow.

- **Sincronismo de Memória**: Gerenciamento de uma linha de atraso (Shift Register) para amostras e uma ROM para coeficientes.

# 3	Detalhamento Técnico e Requisitos

Para a validação do projeto, o cumprimento dos seguintes requisitos arquiteturais é obrigatório:

- **Arquitetura MAC Única (Hardware Sharing)**: É estritamente proibido o uso de múltiplos multiplicadores em paralelo. O projeto deve utilizar uma única unidade de Multiplicação e Acúmulo. O cálculo de cada saída y[n] deve ocorrer de forma iterativa, consumindo exatamente K ciclos de clock de processamento (onde K é o número de taps).

## Parâmetros de Projeto

- [ ] **Ordem do Filtro**: Mínimo de 8 taps. O hardware deve ser parametrizado para permitir a expansão da ordem do filtro sem alteração na lógica da FSM.

- [ ] **Representação Numérica**: Entrada (x) e Coeficientes (h) devem ser obrigatoriamente representados em Ponto Fixo, utilizando Complemento de Dois (sinalizados).

- [ ] **Precisão e Bit-Growth**: O acumulador deve ser dimensionado para evitar overflow. Para 8 taps, o acumulador deve possuir a largura do produto (x vezes h) acrescida de, no mínimo, 3 bits de guarda (ex: se o produto resulta em 16 bits, o acumulador deve ter 19 bits).

- [ ] **FSM de Controle**: A máquina de estados deve orquestrar o fluxo de dados seguindo rigorosamente estas etapas síncronas:

- [ ] **Captura**: Amostragem da nova entrada x[n].

- [ ] **Shift**: Atualização da linha de atraso na memória de amostras.

- [ ] **Processamento (Loop MAC)**: Ciclo iterativo de leitura de coeficiente na ROM, leitura da amostra correspondente, multiplicação e acúmulo.

- [ ] **Finalização**: Estabilização da saída y[n] e ativação do sinal data_valid por apenas um ciclo de clock, indicando que o processamento daquela amostra foi concluído.

# 4	Requisitos de Robustez

- [ ] **Tratamento de Overflow**: O acumulador deve ser projetado com bits de guarda (guard bits) suficientes para garantir que o somatório dos produtos não sature ou cause erro de sinal antes da saída final.

- [ ] **Validação Numérica**: O grupo deve apresentar um script (*Python, MATLAB ou Excel*) que execute o mesmo filtro. Os resultados da simulação RTL devem ser
idênticos aos do script para comprovar a correta implementação da aritmética.

# 5	Entregáveis Detalhados

1. **Código RTL Sequencial**: Implementação modular separando a Unidade de Controle (FSM) da Unidade de Dados (Multiplicador e Acumulador).

2. **Diagrama de Estados**: Representação visual da FSM de controle, detalhando as transições de ciclo.

3. **Testbench com Injeção de Dados**: Uso obrigatório das diretivas $readmemb ou $readmemh para carregar vetores de teste (amostras) e coeficientes a
partir de arquivos externos.

4. **Relatório de Análise Teórica**: Comparação gráfica entre o sinal de saída esperado e o gerado pelo hardware, incluindo uma breve análise sobre a resposta em frequência implementada.

# ARQUIVOS DE SUPORTE

1. Relatório Final: []()

2. Github: []()

3. Artigo: []()
 
# ORIENTADORES

<Inserir orientadores> 

# REFERENCES

[1] []();
[2] []();
[3] []();
[4] []();
[5] []();

# COLABORADORS

- [ ] Configurar lista de colaboradores do grupo 3; 
