"""Search keys in Python: fold() as the database's compact form, and Latin spellings of names and titles in other
scripts, so that "kino" finds "Кино" and "tokyo jihen" finds "東京事変" (the search_latin columns).
"""

import re
import threading
import unicodedata

from anyascii import anyascii

_kakasi = None
_kakasi_lock = threading.Lock()
_KANA = re.compile(r"[぀-ヿㇰ-ㇿｦ-ﾟ]")
_HAN = re.compile(r"[㐀-䶿一-鿿豈-﫿]")
# Hepburn writes long vowels out ("toukyou", "arigatou"); people mostly type them short ("tokyo", "arigato").
_LONG_VOWELS = re.compile(r"(?<=[aeiou])[aeiou]|(?<=o)u")
# Letters unaccent() spells out that Unicode does not decompose.
_SPELLED = str.maketrans({"ß": "ss", "æ": "ae", "œ": "oe", "ø": "o", "ł": "l", "đ": "d", "ð": "d", "þ": "th"})


def fold(text: str) -> str:
    """Lower case letters and digits without accents, as the database's compact search form."""
    text = unicodedata.normalize("NFKD", text.lower().translate(_SPELLED))
    return "".join(c for c in text if c.isalnum() and not unicodedata.combining(c))


def _foreign(text: str) -> bool:
    """Letters outside the Latin script (Latin with accents is folded by the database itself)."""
    for c in unicodedata.normalize("NFKD", text):
        if c.isalpha() and ord(c) > 0x24F and not unicodedata.combining(c):
            return True
    return False


def _japanese(text: str) -> list[str]:
    global _kakasi
    with _kakasi_lock:
        if _kakasi is None:
            import pykakasi

            _kakasi = pykakasi.kakasi()
        parts = _kakasi.convert(text)
    hepburn = " ".join(part["hepburn"] for part in parts if part["hepburn"].strip())
    return [hepburn, " ".join(_LONG_VOWELS.sub("", word) for word in hepburn.split())]


def latin(text: str | None) -> str:
    """The Latin spellings in compact form, separated by spaces; "" when the text needs none."""
    if not text or not _foreign(text):
        return ""
    forms = []
    if _KANA.search(text) or _HAN.search(text):
        # Japanese readings; Chinese characters alone could be either language, so they also get Pinyin below.
        forms += _japanese(text)
    if not _KANA.search(text):
        forms.append(anyascii(text))
    return " ".join(dict.fromkeys(compact for form in forms if (compact := fold(form))))[:2048]
