# Localization check script

## Purpose

`check_localization.dart` scans all Dart files under `lib/` to find **hardcoded user-facing strings** that may need to be moved into the app’s localization system (`lib/locale/`).

## How to run

From the project root:

```bash
dart scripts/check_localization.dart
```

- Prints a report to the console.
- Writes the same report to `scripts/localization_report.txt`.

## What it looks for

- `Text('...')` / `Text("...")`
- `toast('...')`
- `title: '...'`
- `hintText: '...'`
- `labelText: '...'`
- `appBarTitle: '...'`
- `subTitle:` / `subtitle:`
- `hint: Text('...')`
- `return '...';` (e.g. validation messages)
- `buttonText: '...'`
- `positiveText` / `negativeText`

It **skips**:

- Lines that already use `language.xxx`
- Very short strings (< 4 chars)
- Asset paths, URLs, keys, format patterns (e.g. `HH:mm:ss`, `h:mm a`)
- Comments and obvious non–user-facing strings

## After running

1. Open `scripts/localization_report.txt` (or the console output).
2. For each reported string, decide if it is user-facing.
3. If yes:
   - Add a getter in `lib/locale/languages.dart` (BaseLanguage).
   - Implement it in `language_en.dart`, `language_no.dart`, and other locale files.
   - Replace the hardcoded string in code with `language.newKey`.

## Cross-check

- The script does **not** verify that every `language.xxx` getter is implemented in all locale files; that is enforced by the Dart analyzer when you build.
- To double-check usage: search for `language.` in `lib/` and confirm each getter exists in `languages.dart` and in each locale file you support.
