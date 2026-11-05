"""Подставляет палитру в main.gd, city_view.gd, island_map.gd между метками PALETTE.
Запуск из папки проекта: python3 tools/apply_palette.py <warm|sky|teal|sunset>
"""
import re
import sys

PALETTES = {
    # Голубое небо + жёлтое такси: дополнительная пара, белые карточки, тёмно-синий текст.
    "sky": {
        "main": {
            "BG_TOP": "62c6ff", "BG_BOTTOM": "2b8ae6", "TEXT": "1c2b4d", "MUTED": "5c6d90",
            "PANEL": "ffffff", "PANEL_EDGE": "b8d6f2", "ACCENT": "ffc93c", "INK": "1c2b4d",
            "GOLD": "c77d00", "MONEY": "ffd23f", "PILL": "1c2b4d", "CHIP": "ffffff", "DOCK": "ffffff",
            "BUY": "2fbf5f", "DISABLED": "d5e2f0", "INCOME": "1e9e4a", "DANGER": "ff4d5e",
            "TRICK": "ff8a3d", "SKY": "3fb2ff", "SHIFT": "8c9eff", "TITLE": "ffffff", "TITLE_OUTLINE": "1c4f8f",
        },
        "city": {"GROUND": "8fdc6e", "SIDEWALK": "f3efe2", "ROAD": "5a6684", "PARK": "6fd75a", "POND": "3fb2ff",
                 "TREE": "43b65c", "TREE_DARK": "2e8a44", "ROOFS": ["ff8a65", "ffd166", "4fc3f7", "e8edf2", "90caf9", "ffab91"],
                 "RING": "ffc93c"},
        "map": {"OCEAN": "3aa2ff", "OCEAN_DEEP": "2f88e0", "LOCKED": "c3d3e6"},
    },
    # Тёплое небо (текущая): то же голубое небо, но кремовые карточки, тёплые рамки,
    # контрастнее серые подписи — «ламповее» и читаемее.
    "warm": {
        "main": {
            "BG_TOP": "6ccaf7", "BG_BOTTOM": "3a8fdc", "TEXT": "2a2a48", "MUTED": "52607c",
            "PANEL": "fffaf0", "PANEL_EDGE": "e6dcc8", "ACCENT": "ffc93c", "INK": "2a2a48",
            "GOLD": "2b6cb0", "MONEY": "1f9d55", "PILL": "2a2a48", "CHIP": "fffaf0", "DOCK": "fffaf0",
            "BUY": "2fbf5f", "DISABLED": "e6e2da", "INCOME": "1b8f43", "DANGER": "e8434f",
            "TRICK": "2f4a7a", "SKY": "3fb2ff", "SHIFT": "8c9eff", "TITLE": "ffffff", "TITLE_OUTLINE": "1c4f8f",
        },
        "city": {"GROUND": "9bdc75", "SIDEWALK": "f4f1e8", "ROAD": "5d6582", "PARK": "78d562", "POND": "4cb8f5",
                 "TREE": "46b35c", "TREE_DARK": "2f8a46", "ROOFS": ["f28b82", "b39ddb", "4fc3f7", "fff6e6", "a5d6a7", "cfd8dc"],
                 "RING": "ffc93c"},
        "map": {"OCEAN": "45a7f5", "OCEAN_DEEP": "368fe0", "LOCKED": "d4dbe4"},
    },
    # Бирюзовый фон + коралловый акцент + солнечно-жёлтая покупка.
    "teal": {
        "main": {
            "BG_TOP": "149a9c", "BG_BOTTOM": "0b5e66", "TEXT": "ffffff", "MUTED": "b9e6e2",
            "PANEL": "1b8a8f", "PANEL_EDGE": "0a4f56", "ACCENT": "ff7b5c", "INK": "103a40",
            "GOLD": "ffd166", "MONEY": "ffd166", "PILL": "0a3d44", "CHIP": "0e6d74", "DOCK": "0a4f56",
            "BUY": "ffd166", "DISABLED": "2b7c81", "INCOME": "b6f5c9", "DANGER": "ff5a5f",
            "TRICK": "ff7b5c", "SKY": "7fdcff", "SHIFT": "c3b5ff", "TITLE": "ffd166", "TITLE_OUTLINE": "0a3d44",
        },
        "city": {"GROUND": "6cc38a", "SIDEWALK": "efe3c8", "ROAD": "35535c", "PARK": "5dcf86", "POND": "57d6e8",
                 "TREE": "33a86a", "TREE_DARK": "21794b", "ROOFS": ["ff7b5c", "ffd166", "f4f1ea", "4ecdc4", "ffab91", "9be7e0"],
                 "RING": "ff7b5c"},
        "map": {"OCEAN": "1fa6c4", "OCEAN_DEEP": "178aa6", "LOCKED": "7fb3b5"},
    },
    # Тёплый закат: оранжево-коралловый фон, кремовые карточки, синий акцент.
    "sunset": {
        "main": {
            "BG_TOP": "ffb04d", "BG_BOTTOM": "ff6a5c", "TEXT": "3a2236", "MUTED": "86677a",
            "PANEL": "fff7ef", "PANEL_EDGE": "e9bfa6", "ACCENT": "2f5be6", "INK": "3a2236",
            "GOLD": "c45a00", "MONEY": "ffd23f", "PILL": "3a2236", "CHIP": "fff7ef", "DOCK": "fff7ef",
            "BUY": "2db86a", "DISABLED": "eadbd0", "INCOME": "1c9150", "DANGER": "e5384f",
            "TRICK": "ff7a1a", "SKY": "3fa9f5", "SHIFT": "8f7ee8", "TITLE": "ffffff", "TITLE_OUTLINE": "b8413e",
        },
        "city": {"GROUND": "a3d977", "SIDEWALK": "f7e6cf", "ROAD": "5c4a5e", "PARK": "86d65f", "POND": "4fb8ef",
                 "TREE": "4aaa55", "TREE_DARK": "33813e", "ROOFS": ["e85d4a", "ffb04d", "fff1dc", "2f5be6", "f28a6b", "ffd7a8"],
                 "RING": "2f5be6"},
        "map": {"OCEAN": "3f8fe8", "OCEAN_DEEP": "3477cc", "LOCKED": "d9c3b5"},
    },
}


def darker(hex_color, amount):
    r, g, b = (int(hex_color[i:i + 2], 16) for i in (0, 2, 4))
    return "%02x%02x%02x" % tuple(int(c * (1 - amount)) for c in (r, g, b))


def lighter(hex_color, amount):
    r, g, b = (int(hex_color[i:i + 2], 16) for i in (0, 2, 4))
    return "%02x%02x%02x" % tuple(int(c + (255 - c) * amount) for c in (r, g, b))


def put(path, block):
    text = open(path, encoding='utf-8').read()
    new = re.sub(r'# >>> PALETTE\n.*?# <<< PALETTE\n', '# >>> PALETTE\n' + block + '# <<< PALETTE\n', text, flags=re.S)
    assert new != text or block in text, path
    open(path, 'w', encoding='utf-8').write(new)


def main(name, root='.'):
    pal = PALETTES[name]
    m = pal["main"]
    lines = ['## Палитра «%s». Меняется целиком: все цвета экрана берутся отсюда.' % name]
    def c(token, value):
        lines.append('const COLOR_%s := Color("%s")' % (token, value))
    c("BG_TOP", m["BG_TOP"]); c("BG_BOTTOM", m["BG_BOTTOM"]); c("BG", m["BG_BOTTOM"])
    c("TEXT", m["TEXT"]); c("MUTED", m["MUTED"]); c("INK", m["INK"])
    c("PANEL", m["PANEL"]); c("PANEL_EDGE", m["PANEL_EDGE"])
    c("ACCENT", m["ACCENT"]); c("GOLD", m["GOLD"]); c("MONEY", m["MONEY"])
    c("PILL", m["PILL"]); c("CHIP", m["CHIP"]); c("DOCK", m["DOCK"])
    c("BUY", m["BUY"]); c("BUY_HOVER", lighter(m["BUY"], 0.12)); c("BUY_PRESSED", darker(m["BUY"], 0.1))
    c("DISABLED", m["DISABLED"]); c("INCOME", m["INCOME"]); c("DANGER", m["DANGER"])
    c("TRICK", m["TRICK"]); c("SKY", m["SKY"]); c("SHIFT", m["SHIFT"])
    c("TITLE", m["TITLE"]); c("TITLE_OUTLINE", m["TITLE_OUTLINE"])
    c("TAXI", "ffc107"); c("TAXI_PRESSED", "e0a800"); c("WINDOW", "26324a")
    put(root + '/scripts/main.gd', '\n'.join(lines) + '\n')

    ct = pal["city"]
    roofs = ', '.join('Color("%s")' % r for r in ct["ROOFS"])
    put(root + '/scripts/city_view.gd', '\n'.join([
        'const GROUND := Color("%s")' % ct["GROUND"], 'const SIDEWALK := Color("%s")' % ct["SIDEWALK"],
        'const ROAD := Color("%s")' % ct["ROAD"], 'const MARK := Color(1, 1, 1, 0.8)',
        'const PARK := Color("%s")' % ct["PARK"], 'const POND := Color("%s")' % ct["POND"],
        'const TREE := Color("%s")' % ct["TREE"], 'const TREE_DARK := Color("%s")' % ct["TREE_DARK"],
        'const ROOFS := [%s]' % roofs, 'const PLAYER_RING := Color("%s")' % ct["RING"],
    ]) + '\n')

    mp = pal["map"]
    put(root + '/scripts/island_map.gd', '\n'.join([
        'const OCEAN := Color("%s")' % mp["OCEAN"], 'const OCEAN_DEEP := Color("%s")' % mp["OCEAN_DEEP"],
        'const WAVE := Color(1, 1, 1, 0.2)', 'const SAND := Color("e9d8a6")', 'const LOCKED := Color("%s")' % mp["LOCKED"],
    ]) + '\n')
    print('palette', name)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else '.')
