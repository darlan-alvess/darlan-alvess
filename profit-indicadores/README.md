# Zonas de Reversão — indicador NTSL para Profit

Indicador que reproduz o comportamento visual e os sinais do indicador mostrado no vídeo de referência:
duas zonas de volatilidade (uma acima e outra abaixo do preço) e **pintura do candle** quando o preço entra na zona.

> **Nota:** o indicador do vídeo é proprietário e a fórmula exata não é pública.
> Este é um equivalente funcional construído a partir do comportamento observado, com parâmetros abertos para calibração.

---

## Como funciona

1. Calcula uma média central (simples ou exponencial) do fechamento.
2. Calcula o ATR (volatilidade média real) do período configurado.
3. Monta duas zonas:
   - **Zona vermelha (venda):** entre `média + MultInterno × ATR` e `média + MultExterno × ATR`
   - **Zona verde (compra):** entre `média − MultInterno × ATR` e `média − MultExterno × ATR`
4. Gera o sinal:
   - **Compra** → a mínima do candle toca ou entra na zona verde → candle pintado de verde
   - **Venda** → a máxima do candle toca ou entra na zona vermelha → candle pintado de vermelho

A lógica é de **exaustão / reversão**: o preço se afastou demais da média e tende a voltar.

---

## Instalação

1. Profit → menu **Estratégias** → **Editor de Estratégias**
2. **Novo → Indicador**
3. Cole o conteúdo de `zonas-de-reversao.src`
4. **Compilar** (F9) e salvar com o nome `Zonas de Reversão`
5. No gráfico: **Inserir Indicador** → escolha `Zonas de Reversão`

### Deixando igual ao vídeo (preenchimento das zonas)

Nas propriedades do indicador, aba de plotagens:

- Plot 1 e Plot 2 (superiores): cor vermelha, estilo **área/preenchimento entre plots**
- Plot 3 e Plot 4 (inferiores): cor verde, estilo **área/preenchimento entre plots**
- Espessura 1 ou 2

---

## Parâmetros

| Parâmetro | Padrão | O que faz |
|---|---|---|
| `PeriodoMedia` | 20 | Período da média central |
| `TipoMedia` | 1 | 0 = simples, 1 = exponencial |
| `PeriodoATR` | 14 | Período do ATR (controla a largura das zonas) |
| `MultInterno` | 2.0 | Onde começa a zona (borda mais próxima do preço) |
| `MultExterno` | 3.0 | Onde termina a zona (borda mais distante) |
| `ConfirmaFechamento` | 0 | 0 = sinal no toque; 1 = só sinaliza se o candle fechar de volta para dentro |
| `PintarCandle` | 1 | 1 = pinta o candle no sinal |

### Como calibrar

- **Sinais demais** → aumente `MultInterno` (ex.: 2.5 ou 3.0)
- **Sinais de menos** → reduza `MultInterno` (ex.: 1.5)
- **Zonas muito "nervosas"** → aumente `PeriodoATR` ou `PeriodoMedia`
- **Menos falso sinal** → ligue `ConfirmaFechamento = 1`

O ajuste depende do ativo e do tempo gráfico. No vídeo o gráfico principal é de 5 minutos e os auxiliares de 60 minutos.

---

## Avisos

- O indicador **não é uma estratégia automatizada**: ele marca contexto, não garante entrada.
- Um toque na zona não é sinal de entrada isolado — o vídeo mostra o indicador usado junto com leitura de tendência em tempo gráfico maior.
- Recomendo testar no **simulador** e usar o **backtest** do Profit antes de operar com dinheiro real.
