# Zonas de Reversão v2 + Painel de Risco

Dois indicadores NTSL para o Profit (Nelogica).

| Arquivo | Onde vai | O que faz |
|---|---|---|
| `zonas-de-reversao-v2.src` | gráfico de preço | zonas, sinais filtrados, média de tendência |
| `painel-risco.src` | janela separada | stop sugerido em pontos e quantos contratos cabem |
| `zonas-de-reversao.src` | — | versão 1, mantida só como referência |

---

## O que a v2 corrige da v1

**1. Não repinta.** A v1 avaliava `Low` do candle em formação, então um sinal
podia aparecer e sumir. A v2 avalia a barra já fechada (`BarraFechada = 1`).
O candle pintado é o **candle de entrada**; o sinal nasceu no fechamento do
candle anterior.

**2. Filtro de tendência.** Compra só em correção dentro de alta, venda só em
repique dentro de baixa. Tocar a banda inferior numa queda forte não é
exaustão, é continuação.

**3. Confirmação por rejeição.** O candle precisa ter pavio contra a zona e
fechar de volta para dentro. Entrar em zona é diferente de ser **expulso** dela.

**4. Um sinal por visita.** Se o preço ficar colado na banda por 8 candles, a
v1 pintava 8. A v2 pinta só o primeiro.

**5. Nota de 0 a 3**, na cor do candle:

| Cor | Nota | Significado |
|---|---|---|
| verde claro / vermelho vivo | 3 | passou do meio da zona + pavio ≥ corpo + a favor da tendência |
| verde escuro / vermelho escuro | 2 | dois dos três critérios |

---

## Instalação

1. Profit → **Estratégias** → **Editor de Estratégias**
2. **Novo** → **Indicador**
3. Cole o conteúdo do `.src`, **F9** para compilar
4. Salve como `Zonas de Reversão v2` e `Painel de Risco`
5. No gráfico: botão direito → **Inserir Indicador**

O `Painel de Risco` precisa ir em **janela separada**, não sobre o preço — os
valores dele são pontos, não preço, e quebrariam a escala.

### Visual das zonas
Para ficar como o do vídeo: plots 1 e 2 em vermelho com preenchimento entre
eles, plots 3 e 4 em verde idem. O plot 5 é a média de tendência — cinza, fina.

---

## Calibração medida

Rodei a lógica da v2 em 80 dias de séries sintéticas calibradas para o ATR
típico do WIN (200 pts no 5min, 70 pts no 1min). **São dados sintéticos: servem
para comparar configurações entre si, não para prever acerto no mercado real.**

### 5 minutos (ATR ~200 pts)

| Configuração | Sinais/dia |
|---|---|
| sem nenhum filtro (igual v1) | ~25 |
| **NotaMinima = 2 (padrão)** | **0,8** |
| NotaMinima = 3 | 0,2 |
| MultInterno = 1,8 | 0,9 |
| sem filtro de tendência | 1,1 |

### 1 minuto (ATR ~70 pts)

| Configuração | Sinais/dia |
|---|---|
| **NotaMinima = 2 (padrão)** | **3,6** |
| NotaMinima = 3 | 0,6 |
| MultInterno = 2,5 | 2,0 |

---

## Qual tempo gráfico usar

O dado mais importante que saiu do teste:

| Tempo | ATR | Stop 1,5× ATR | Contratos (risco R$200) |
|---|---|---|---|
| 5 min | 200 pts | **300 pts** | **3** |
| 1 min | 70 pts | 106 pts | 9 |

**O gráfico de 5 minutos é o que casa com o seu método.** Stop de 300 pontos e
3 contratos é exatamente a faixa em que você já opera.

No 1 minuto o stop coerente com a volatilidade é de ~100 pontos, o que pede 9
contratos. Isso não está errado, mas é **outro jogo**: contrato maior, stop
curto, e um alvo de 250 pontos passa a ser um movimento longo em vez de um
movimento normal. Se for operar 1 minuto, mude a configuração inteira, não só
o tempo gráfico.

Sugestão: **5 minutos como gráfico de decisão, 1 minuto só para afinar a
entrada** depois que o sinal de 5 minutos apareceu.

---

## Parâmetros

### zonas-de-reversao-v2.src

| Parâmetro | Padrão | O que faz |
|---|---|---|
| `PeriodoMedia` | 20 | média central das zonas |
| `PeriodoATR` | 14 | largura das zonas |
| `MultInterno` | 2.0 | borda de gatilho. Menor = mais sinais |
| `MultExterno` | 3.0 | borda do extremo |
| `PeriodoTendencia` | 200 | média longa do filtro de tendência |
| `FiltroTendencia` | 1 | 0 desliga |
| `ExigeRejeicao` | 1 | exige pavio + fechamento de volta |
| `PavioMinimo` | 0.5 | pavio mínimo, em múltiplos do corpo |
| `BarrasRearme` | 8 | barras sem novo sinal na mesma zona |
| `BarraFechada` | 1 | **não mude para 0** — volta a repintar |
| `NotaMinima` | 2 | nota mínima do sinal |

### painel-risco.src

| Parâmetro | Padrão | Observação |
|---|---|---|
| `MultStop` | 1.5 | stop = múltiplo do ATR |
| `RiscoReais` | 200 | o mesmo da planilha de controle |
| `ValorPonto` | 0.20 | WIN. Para WDO use 10.00 |
| `RefContratosA/B/C` | 4 / 3 / 2 | no 1 minuto, use 12 / 9 / 6 |

---

## Como calibrar

Faça isso **no Replay**, antes de ativar a mesa.

1. Deixe os padrões e rode uma semana de Replay no 5 minutos
2. Conte os sinais. Menos de 2 por semana → baixe `MultInterno` para 1,8
3. Sinais demais em dia lateral → suba `NotaMinima` para 3
4. Compare o stop do painel com o stop que você usaria no olho. Se o painel
   disser 180 e você usaria 400, **você está arriscando o dobro do necessário**

---

## Limitações, ditas na cara

- O indicador do vídeo é proprietário. Isto é um equivalente funcional
  construído a partir do comportamento observado, não uma cópia da fórmula.
- O código **não foi compilado** — não tenho Profit aqui. A lógica foi portada
  para Python e testada, mas erro de sintaxe no F9 é possível. Me avise o erro
  e eu corrijo.
- O filtro de horário está comentado no código: o nome da função de hora muda
  entre versões do Profit. Descomente se a sua aceitar `Time`.
- O rearme compara as barras anteriores com a borda **atual** da banda, não com
  a borda que existia naquele momento. A banda se move devagar, então a
  diferença é pequena, e evita recalcular tudo barra a barra.
- `PeriodoTendencia = 200` faz o indicador percorrer 200 barras por candle. Em
  históricos longos de 1 minuto ele fica lento. Baixe para 100 se incomodar.
