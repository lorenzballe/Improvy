"""Writes the paste-ready store texts in store_listing/ from STORE_DESCRIPTION.md.

    python3 tool/store_texts.py
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
s = open(os.path.join(ROOT, "STORE_DESCRIPTION.md")).read()


def block(heading):
    i = s.index(heading)
    j = s.index("```", i) + 3
    return s[j:s.index("```", j)].strip("\n")


name, sub, promo = block("## Name"), block("## Subtitle"), block("## Promotional text")
kw, short = block("## Keywords"), block("## Short description")
desc, new = block("## Description"), block("## What's New")
out = os.path.join(ROOT, "store_listing")

open(os.path.join(out, "1 - Apple App Store (iPhone e iPad)", "Testi da incollare.txt"), "w").write(
    f"""APP STORE CONNECT - testi da incollare (copia solo il testo sotto ogni titolo)

NOME (App Information > Name)
{name}

SOTTOTITOLO (App Information > Subtitle)
{sub}

TESTO PROMOZIONALE (versione > Promotional Text)
{promo}

PAROLE CHIAVE (versione > Keywords)
{kw}

DESCRIZIONE (versione > Description)
{desc}

NOVITA' DI QUESTA VERSIONE (versione > What's New in This Version)
{new}
""")
open(os.path.join(out, "2 - Google Play (Android)", "Testi da incollare.txt"), "w").write(
    f"""GOOGLE PLAY CONSOLE - testi da incollare (Crescita > Presenza sullo Store > Scheda principale)

NOME APP
{name}

DESCRIZIONE BREVE
{short}

DESCRIZIONE COMPLETA
{desc}

NOTE DI RILASCIO (Release > Note di rilascio)
{new}
""")
