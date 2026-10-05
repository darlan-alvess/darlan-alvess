# -*- coding: utf-8 -*-
"""
Extrai candles do MetaTrader 5 e salva em CSV.

Para que serve
--------------
O Claude nao consegue acessar o seu MT5 pela internet. Este script roda na
SUA maquina, puxa os dados do terminal aberto e gera um CSV que voce envia
na conversa para a analise.

Pre-requisitos
--------------
    pip install MetaTrader5 pandas

O terminal do MT5 precisa estar ABERTO e logado.

Como usar
---------
    python extrai_mt5.py --listar              # descobre o nome do simbolo
    python extrai_mt5.py --simbolo WIN$N       # extrai com os padroes
    python extrai_mt5.py --simbolo WIN$N --tf M1 --barras 50000
"""

import argparse
import sys

try:
    import MetaTrader5 as mt5
    import pandas as pd
except ImportError as e:
    sys.exit(
        f"Falta instalar um pacote ({e.name}).\n"
        f"Rode:  pip install MetaTrader5 pandas"
    )


# Os tempos graficos que interessam para day trade no mini indice.
TIMEFRAMES = {
    "M1": mt5.TIMEFRAME_M1,
    "M2": mt5.TIMEFRAME_M2,
    "M5": mt5.TIMEFRAME_M5,
    "M15": mt5.TIMEFRAME_M15,
    "M30": mt5.TIMEFRAME_M30,
    "H1": mt5.TIMEFRAME_H1,
    "D1": mt5.TIMEFRAME_D1,
}


def conecta():
    if not mt5.initialize():
        sys.exit(
            f"Nao consegui conectar no MT5: {mt5.last_error()}\n"
            f"O terminal esta aberto e logado?"
        )


def lista_simbolos(filtro):
    """Mostra os simbolos disponiveis, para voce descobrir o nome exato.

    O nome do mini indice muda de corretora para corretora: WIN$, WIN$N,
    WINZ25... Por isso vale listar antes de extrair.
    """
    simbolos = mt5.symbols_get()
    if simbolos is None:
        sys.exit(f"Nao consegui listar os simbolos: {mt5.last_error()}")

    achados = [s.name for s in simbolos if filtro.upper() in s.name.upper()]
    if not achados:
        print(f"Nenhum simbolo contem '{filtro}'.")
        print(f"Total de simbolos na corretora: {len(simbolos)}")
        print("Tente um filtro mais curto, por exemplo: --listar WIN")
        return

    print(f"{len(achados)} simbolo(s) com '{filtro}':")
    for nome in sorted(achados):
        print(f"  {nome}")


def extrai(simbolo, tf, barras, saida):
    if tf not in TIMEFRAMES:
        sys.exit(f"Tempo grafico invalido. Use um destes: {', '.join(TIMEFRAMES)}")

    # O simbolo precisa estar visivel no Market Watch para o MT5 servir os dados.
    if not mt5.symbol_select(simbolo, True):
        sys.exit(
            f"Nao consegui selecionar '{simbolo}'.\n"
            f"Rode  python extrai_mt5.py --listar  para ver o nome correto."
        )

    rates = mt5.copy_rates_from_pos(simbolo, TIMEFRAMES[tf], 0, barras)
    if rates is None or len(rates) == 0:
        sys.exit(f"Nenhum dado retornado para {simbolo} em {tf}: {mt5.last_error()}")

    df = pd.DataFrame(rates)
    df["time"] = pd.to_datetime(df["time"], unit="s")
    df = df.rename(
        columns={
            "time": "data_hora",
            "open": "abertura",
            "high": "maxima",
            "low": "minima",
            "close": "fechamento",
            "tick_volume": "negocios",
            "real_volume": "volume",
        }
    )

    colunas = ["data_hora", "abertura", "maxima", "minima", "fechamento", "negocios"]
    if "volume" in df.columns and df["volume"].sum() > 0:
        colunas.append("volume")

    # 2 casas bastam para WIN e WDO, e o arquivo fica muito menor para enviar.
    df[colunas].to_csv(saida, index=False, encoding="utf-8", float_format="%.2f")

    # Um resumo rapido, para voce conferir que veio o que esperava.
    amplitude = (df["maxima"] - df["minima"]).mean()
    print(f"\nArquivo gerado: {saida}")
    print(f"  simbolo .......... {simbolo} em {tf}")
    print(f"  barras ........... {len(df):,}")
    print(f"  periodo .......... {df['data_hora'].min()}  ate  {df['data_hora'].max()}")
    print(f"  amplitude media .. {amplitude:,.1f} pontos por candle")
    print(f"\nEnvie este arquivo na conversa para a analise.")


def main():
    p = argparse.ArgumentParser(description="Extrai candles do MT5 para CSV.")
    p.add_argument("--listar", nargs="?", const="WIN", metavar="FILTRO",
                   help="lista os simbolos que contem FILTRO (padrao: WIN)")
    p.add_argument("--simbolo", help="nome exato do simbolo, ex: WIN$N")
    p.add_argument("--tf", default="M5", help=f"tempo grafico ({', '.join(TIMEFRAMES)})")
    p.add_argument("--barras", type=int, default=20000, help="quantas barras puxar")
    p.add_argument("--saida", help="nome do arquivo CSV de saida")
    args = p.parse_args()

    conecta()
    try:
        if args.listar is not None:
            lista_simbolos(args.listar)
        elif args.simbolo:
            saida = args.saida or f"{args.simbolo.replace('$', '')}_{args.tf}.csv"
            extrai(args.simbolo, args.tf, args.barras, saida)
        else:
            p.print_help()
    finally:
        mt5.shutdown()


if __name__ == "__main__":
    main()
