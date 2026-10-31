# Localization (en and tr)

1. Every player facing string is a key, never a literal. Keys are UPPER_SNAKE with prefixes UI_, MONO_, FACT_, CHOICE_, END_.
2. Add en and tr together in translations/strings.csv in the same task. Format: keys,en,tr.
3. Fonts must support Turkish glyphs: ı İ ş Ş ğ Ğ ç Ç ö Ö ü Ü.
4. Never call to_upper() or to_lower() on player facing text. Turkish i breaks. Store final casing in the translation.
5. Layouts must survive Turkish being about 20 percent longer: autowrap and containers, no fixed widths.
6. Switch language only with Settings.set_language(code). It saves to user://settings.cfg and emits language_changed.
7. Texts must follow the same no dash rule as chat. Use commas or periods.
8. Check with: python tools/check_project.py text
