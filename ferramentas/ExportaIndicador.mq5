//+------------------------------------------------------------------+
//| ExportaIndicador.mq5                                             |
//|                                                                  |
//| Script para MetaTrader 5.                                        |
//|                                                                  |
//| Le os buffers de um indicador customizado e grava tudo num CSV,  |
//| junto com os candles. Serve para analisar fora do MT5 o que o    |
//| indicador produziu, sem precisar do codigo-fonte dele.           |
//|                                                                  |
//| COMO USAR                                                        |
//|   1. Salve este arquivo em  MQL5/Scripts/                        |
//|   2. Abra no MetaEditor e compile com F7                         |
//|   3. No MT5, arraste o script para o grafico do ativo            |
//|   4. Em NomeIndicador ponha o nome do arquivo .ex5 sem extensao, |
//|      por exemplo "Seta" ou "Fluxo"                               |
//|   5. O CSV sai em  MQL5/Files/                                   |
//|                                                                  |
//| O indicador precisa estar em MQL5/Indicators/.                   |
//| Rode uma vez para cada indicador: um CSV para a Seta, outro      |
//| para o Fluxo. A analise junta os dois depois pela data e hora.   |
//+------------------------------------------------------------------+
#property copyright "Uso pessoal"
#property version   "1.01"
#property script_show_inputs

#define MAX_BUFFERS 8

input string NomeIndicador = "Seta";   // nome do .ex5, sem extensao
input int    Barras        = 20000;    // quantas barras exportar

//+------------------------------------------------------------------+
//| Carrega o indicador com os parametros padrao dele.               |
//+------------------------------------------------------------------+
int BuscaHandle()
  {
   int h = iCustom(_Symbol, _Period, NomeIndicador);
   if(h == INVALID_HANDLE)
     {
      PrintFormat("Nao consegui carregar '%s'. Erro %d.", NomeIndicador, GetLastError());
      Print("Confira se o arquivo esta em MQL5/Indicators/ e se o nome esta correto.");
     }
   return h;
  }

//+------------------------------------------------------------------+
void OnStart()
  {
   int handle = BuscaHandle();
   if(handle == INVALID_HANDLE)
      return;

   //--- o indicador precisa terminar de calcular antes de a gente ler
   int tentativas = 0;
   while(BarsCalculated(handle) <= 0 && tentativas < 100)
     {
      Sleep(100);
      tentativas++;
     }
   if(BarsCalculated(handle) <= 0)
     {
      Print("O indicador nao calculou nada. Ele funciona neste ativo e tempo grafico?");
      IndicatorRelease(handle);
      return;
     }

   int total = MathMin(Barras, Bars(_Symbol, _Period));
   if(total <= 0)
     {
      Print("Sem barras disponiveis.");
      IndicatorRelease(handle);
      return;
     }
   PrintFormat("Exportando %d barras de %s em %s.", total, _Symbol, EnumToString(_Period));

   //--- le cada buffer para uma coluna, marcando as que existem
   double colunas[][MAX_BUFFERS];
   ArrayResize(colunas, total);

   // Sem isso, um buffer mais curto que o pedido deixaria lixo nas sobras.
   for(int i = 0; i < total; i++)
      for(int k = 0; k < MAX_BUFFERS; k++)
         colunas[i][k] = EMPTY_VALUE;

   int indiceOriginal[];
   ArrayResize(indiceOriginal, MAX_BUFFERS);
   int nColunas = 0;

   double temp[];
   ArraySetAsSeries(temp, true);

   for(int b = 0; b < MAX_BUFFERS; b++)
     {
      int copiados = CopyBuffer(handle, b, 0, total, temp);
      if(copiados <= 0)
         continue;                 // este indice nao existe; tenta o proximo

      indiceOriginal[nColunas] = b;
      for(int i = 0; i < copiados && i < total; i++)
         colunas[i][nColunas] = temp[i];
      nColunas++;
     }

   if(nColunas == 0)
     {
      Print("Nenhum buffer legivel. O indicador pode usar buffers apenas de calculo.");
      IndicatorRelease(handle);
      return;
     }
   PrintFormat("Buffers encontrados: %d", nColunas);

   //--- candles
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int nRates = CopyRates(_Symbol, _Period, 0, total, rates);
   if(nRates <= 0)
     {
      PrintFormat("Nao consegui copiar os candles. Erro %d.", GetLastError());
      IndicatorRelease(handle);
      return;
     }

   //--- grava o CSV
   string nome = StringFormat("%s_%s_%s.csv", NomeIndicador, _Symbol, EnumToString(_Period));
   int f = FileOpen(nome, FILE_WRITE | FILE_CSV | FILE_ANSI, ',');
   if(f == INVALID_HANDLE)
     {
      PrintFormat("Nao consegui criar o arquivo. Erro %d.", GetLastError());
      IndicatorRelease(handle);
      return;
     }

   string cabecalho = "data_hora,abertura,maxima,minima,fechamento,negocios,volume";
   for(int k = 0; k < nColunas; k++)
      cabecalho += StringFormat(",buffer_%d", indiceOriginal[k]);
   FileWrite(f, cabecalho);

   // do mais antigo para o mais novo, que e a ordem que a analise espera
   int limite = MathMin(nRates, total);
   int gravadas = 0;
   for(int i = limite - 1; i >= 0; i--)
     {
      string linha = StringFormat("%s,%.2f,%.2f,%.2f,%.2f,%I64d,%I64d",
                                  TimeToString(rates[i].time, TIME_DATE | TIME_MINUTES),
                                  rates[i].open, rates[i].high, rates[i].low, rates[i].close,
                                  rates[i].tick_volume, rates[i].real_volume);

      for(int k = 0; k < nColunas; k++)
        {
         double v = colunas[i][k];
         // Em indicador de seta, a barra sem sinal vem como EMPTY_VALUE.
         // Deixamos a celula vazia para a analise distinguir de um zero real.
         if(v == EMPTY_VALUE || !MathIsValidNumber(v))
            linha += ",";
         else
            linha += StringFormat(",%.4f", v);
        }
      FileWrite(f, linha);
      gravadas++;
     }

   FileClose(f);
   IndicatorRelease(handle);

   PrintFormat("Pronto: %d linhas em MQL5/Files/%s", gravadas, nome);
   Print("No MT5: Arquivo > Abrir Pasta de Dados > MQL5 > Files");
  }
//+------------------------------------------------------------------+
