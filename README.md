<div align="center">

# Mini-CPU de 16 bits na DE2-115

**Projeto 2 · Sistemas Digitais (CIN0007)**<br>
Engenharia da Computação · Centro de Informática · UFPE · 2026.2<br>
Prof. Abel Guilhermino

<br>

![Verilog](https://img.shields.io/badge/Verilog-1f2937?style=flat-square)
![DE2-115](https://img.shields.io/badge/placa-DE2--115-1f2937?style=flat-square)
![Quartus](https://img.shields.io/badge/Quartus_Prime-20.1_Lite-1f2937?style=flat-square)

[O projeto](#o-projeto) · [Como usar](#como-usar-na-placa) · [Instruções](#instruções) · [Teste rápido](#um-teste-rápido) · [Problemas comuns](#problemas-comuns) · [Equipe](#equipe)

</div>

---

## O projeto

A ideia do projeto é montar uma CPU pequena, de 16 bits, e fazê-la rodar de verdade numa FPGA. Não tem programa armazenado: quem faz o papel de "programa" é a gente, digitando cada instrução nas chaves da placa e apertando um botão para executar. O resultado aparece no LCD, em decimal, junto com o nome da operação e o registrador onde ele foi guardado.

A CPU tem 16 registradores (R0 a R15), faz soma, subtração e multiplicação com números positivos e negativos, e avisa quando o resultado não cabe em 16 bits. Escrevemos tudo em Verilog e usamos o Quartus para compilar e gravar na DE2-115.

<table>
<tr>
<td width="50%" valign="top">

**O que você usa na placa**

| | |
|---|---|
| Chaves `SW17..SW0` | a instrução |
| Botão `KEY3` | liga e desliga |
| Botão `KEY2` | executa a instrução |

</td>
<td width="50%" valign="top">

**O que a placa mostra**

| | |
|---|---|
| LCD | operação, registrador e resultado |
| Displays `HEX` | a instrução que está nas chaves |
| LEDs verdes | ligado · pronto · overflow |

</td>
</tr>
</table>

## Como usar na placa

1. Abra o projeto `03_quartus/mini_cpu.qpf` no Quartus e compile (Ctrl+L).
2. Grave o arquivo `03_quartus/saida_compilacao/mini_cpu.sof` pelo Programmer.
3. A placa começa desligada: LCD apagado e displays apagados. Aperte e solte o **KEY3** para ligar. O LCD mostra a tela inicial:
   ```
   ____      [----]
             +00000
   ```
4. Monte a instrução nas chaves. Antes de enviar, confira nos displays HEX se ela está do jeito que você queria.
5. Aperte e solte o **KEY2**. O resultado aparece no LCD.
6. Para desligar, aperte e solte o **KEY3** de novo. Ao desligar, todos os registradores voltam a zero.

> [!NOTE]
> Os botões só agem quando você **solta**. Segurar o botão apertado não faz nada, e isso é proposital: o enunciado pede assim.

## Instruções

Os três primeiros bits (SW17, SW16 e SW15) dizem qual é a operação. O resto da instrução muda de significado dependendo dela.

| Código | Instrução | O que faz | Exemplo |
|:---:|:---|:---|:---|
| `000` | `LOAD` | guarda um número num registrador | `LOAD R2, 12` |
| `001` | `ADD` | soma dois registradores | `ADD R1, R0, R2` |
| `010` | `ADDI` | soma um registrador com um número | `ADDI R3, R1, 5` |
| `011` | `SUB` | subtrai dois registradores | `SUB R5, R4, R3` |
| `100` | `SUBI` | subtrai um número de um registrador | `SUBI R4, R2, 20` |
| `101` | `MUL` | multiplica um registrador por um número | `MUL R6, R5, -3` |
| `110` | `CLEAR` | zera todos os registradores | `CLEAR` |
| `111` | `DISPLAY` | mostra o valor de um registrador | `DISPLAY R2` |

### Montando a instrução nas chaves

As chaves são lidas da esquerda (SW17) para a direita (SW0), em grupos:

| Chaves | 17 a 15 | 14 a 11 | 10 a 7 | 6 a 0 |
|:---|:---:|:---:|:---:|:---|
| **Com número** (LOAD, ADDI, SUBI, MUL) | operação | registrador de destino | registrador de origem | sinal na chave 6 (1 = negativo) e o número, de 0 a 63, nas chaves 5 a 0 |
| **Com registradores** (ADD, SUB) | operação | registrador de destino | primeiro registrador | segundo registrador nas chaves 6 a 3; chaves 2 a 0 em zero |

Os registradores são escritos em binário com 4 bits: R2 é `0010`, R10 é `1010`. Os números também vão em binário: 12 é `001100`.

Um exemplo completo, `LOAD R2, 12`:

```
SW:  000   0010   0000   0   001100
     LOAD   R2     ---   +     12
```

```
┌────────────────┐
│LOAD      [0010]│   ← operação e registrador de destino (em binário)
│          +00012│   ← resultado em decimal
└────────────────┘
```

> [!TIP]
> Quando uma instrução não usa algum campo, deixe aquelas chaves em zero. Os displays HEX apagam os campos que a instrução não usa, o que ajuda a perceber se você escolheu a operação certa.

## Um teste rápido

Com a placa recém-ligada, faça esta sequência. Ela passa por todas as instruções, e cada linha depende da anterior:

| # | Instrução | Chaves (SW17 → SW0) | LCD mostra |
|:---:|:---|:---|:---|
| 1 | `LOAD R2, 12` | `000 0010 0000 0 001100` | `LOAD [0010]` · `+00012` |
| 2 | `ADD R1, R0, R2` | `001 0001 0000 0010 000` | `ADD [0001]` · `+00012` |
| 3 | `ADDI R3, R1, 5` | `010 0011 0001 0 000101` | `ADDI [0011]` · `+00017` |
| 4 | `SUBI R4, R2, 20` | `100 0100 0010 0 010100` | `SUBI [0100]` · `-00008` |
| 5 | `SUB R5, R4, R3` | `011 0101 0100 0011 000` | `SUB [0101]` · `-00025` |
| 6 | `MUL R6, R5, -3` | `101 0110 0101 1 000011` | `MUL [0110]` · `+00075` |
| 7 | `DISPLAY R2` | `111 0010 0000 0000 000` | `DPL [0010]` · `+00012` |
| 8 | `CLEAR` | `110 0000 0000 0000 000` | `CLEAR` |
| 9 | `DISPLAY R2` | `111 0010 0000 0000 000` | `DPL [0010]` · `+00000` |

<details>
<summary><b>Quer ver o LED de overflow acender?</b></summary>
<br>

O maior número que cabe é 32767. Multiplicando 63 por 63 duas vezes, o resultado passa disso:

| Instrução | Chaves | Resultado |
|:---|:---|:---|
| `LOAD R1, 63` | `000 0001 0000 0 111111` | `+00063` |
| `MUL R1, R1, 63` | `101 0001 0001 0 111111` | `+03969` |
| `MUL R2, R1, 63` | `101 0010 0001 0 111111` | `-12097` e o **LEDG2 acende** |

O valor certo seria 250047, mas ele não cabe em 16 bits, então a placa mostra o que sobrou depois de cortar e acende o LED para avisar.

</details>

## Problemas comuns

<details>
<summary><b>A placa não aparece no Programmer</b></summary>
<br>

Confira se o cabo está na porta USB marcada como **USB Blaster** (ao lado da entrada da fonte), se a chave RUN/PROG na lateral está em **RUN** e se a placa está ligada. Se mesmo assim a lista do Hardware Setup ficar vazia, falta o driver: no Gerenciador de Dispositivos do Windows, atualize o driver do USB-Blaster apontando para a pasta `drivers` da instalação do Quartus.
</details>

<details>
<summary><b>Gravei, mas nada acontece</b></summary>
<br>

É o esperado: o sistema começa desligado. Aperte e **solte** o KEY3.
</details>

<details>
<summary><b>O resultado não é o que eu esperava</b></summary>
<br>

Quase sempre é uma chave na posição errada. Antes de soltar o KEY2, olhe os displays HEX: o da esquerda mostra a operação, depois vêm os registradores e, à direita, o número. Lembre também que os registradores guardam os valores das instruções anteriores, então a ordem das instruções importa.
</details>

<details>
<summary><b>Apertei o KEY2 e nada mudou</b></summary>
<br>

Ou o sistema está desligado (LEDG0 apagado), ou a CPU ainda estava ocupada com a instrução anterior (LEDG1 apagado). Espere o LEDG1 acender e tente de novo.
</details>

## O que aprendemos

A parte que mais deu trabalho não foi a CPU em si, e sim falar com o mundo de fora dela. O botão, por exemplo: o contato mecânico "treme" por alguns milissegundos quando é apertado ou solto, e sem um filtro um único toque executaria a instrução várias vezes. O LCD também tem o seu tempo: se a gente manda os caracteres rápido demais, ele mostra lixo. A solução foi dar ao LCD um controle próprio, que trabalha no ritmo dele enquanto a CPU segue livre para a próxima instrução.

Outra lição foi dividir bem o código. No começo quase tudo ficava num arquivo só; no fim, separamos o projeto em dez módulos pequenos, cada um fazendo uma coisa. Isso facilitou muito testar cada parte separada antes de juntar tudo na placa.

## Organização dos arquivos

```
MiniCPU_Projeto2_Final/
├── 01_codigo_verilog/   código do projeto (module_mini_cpu, module_alu, memory e módulos auxiliares)
├── 02_simulacao/        testes no computador antes de ir para a placa
├── 03_quartus/          projeto do Quartus, já com a pinagem configurada
└── 04_apresentacao/     relatório técnico e material da apresentação
```

O relatório em `04_apresentacao` explica cada módulo em detalhe, com diagramas e simulações.

## Ideias para continuar

Do jeito que está, a CPU executa uma instrução por vez, sempre digitada nas chaves. O passo natural seria guardar um pequeno programa numa memória e deixar a CPU buscar as instruções sozinha. Também dá para acrescentar operações lógicas (AND, OR) e mostrar o conteúdo de todos os registradores nos displays.

## Equipe

| Nome | Login |
|:---|:---:|
| Francisco Gabriel Brito Gomes | `fgbg` |
| Francisco Estevão Lira de Araújo | `fela` |
| Alam Guilherme Tavares Menezes | `agtm` |
| Matheus Emanuel de Souza Agra | `mesa2` |

<div align="center">
<sub>Centro de Informática · Universidade Federal de Pernambuco · 2026</sub>
</div>
