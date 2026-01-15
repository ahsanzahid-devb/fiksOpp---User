# Language Source Tracking

## Summary
**Languages are stored in FRONTEND, NOT from backend API.**

## Evidence

### 1. Language Files Location (Frontend)
All language files are stored locally in the `lib/locale/` directory:
- `lib/locale/language_en.dart` - English translations
- `lib/locale/language_ar.dart` - Arabic translations  
- `lib/locale/language_hi.dart` - Hindi translations
- `lib/locale/languages_fr.dart` - French translations
- `lib/locale/languages_de.dart` - German translations

### 2. Language Loading Mechanism
**File:** `lib/locale/app_localizations.dart`

Languages are loaded from local files using the `AppLocalizations.load()` method:
```dart
Future<BaseLanguage> load(Locale locale) async {
  switch (locale.languageCode) {
    case 'en':
      return LanguageEn();
    case 'ar':
      return LanguageAr();
    case 'hi':
      return LanguageHi();
    case 'fr':
      return LanguageFr();
    case 'de':
      return LanguageDe();
    default:
      return LanguageEn();
  }
}
```

### 3. Language Storage in App Store
**File:** `lib/store/app_store.dart`

The language selection is stored locally:
```dart
@observable
String selectedLanguageCode = getStringAsync('selected_language_code', defaultValue: DEFAULT_LANGUAGE);

@action
Future<void> setLanguage(String val) async {
  selectedLanguageCode = val;
  selectedLanguageDataModel = getSelectedLanguageModel();
  await setValue('selected_language_code', selectedLanguageCode);
  language = await AppLocalizations().load(Locale(selectedLanguageCode));
  // ...
}
```

### 4. No Backend API Calls
**File:** `lib/network/rest_apis.dart`

✅ **Confirmed:** No API endpoints exist for fetching languages or translations from the backend.

### 5. Language Structure
All language classes extend `BaseLanguage` abstract class which defines all translatable strings as getters. Each language file (e.g., `LanguageEn`, `LanguageAr`) implements these getters with hardcoded string values.

## Conclusion
- ✅ **Source:** Frontend (hardcoded in Dart files)
- ❌ **Not from:** Backend API
- 📁 **Location:** `lib/locale/` directory
- 🔄 **Update Method:** Requires app update to change translations
- 💾 **Storage:** Local storage for selected language preference only

## Supported Languages
1. English (en) - Default
2. Arabic (ar)
3. Hindi (hi)
4. French (fr)
5. German (de)
6. Norwegian (no) - Currently uses English strings

## Notes
- To add a new language, create a new file in `lib/locale/` implementing `BaseLanguage`
- To update translations, edit the respective language file directly
- Language selection is persisted locally using `setValue('selected_language_code', ...)`
- No network calls are made for language data

## Admin Panel Control
❌ **NO - Languages CANNOT be shown/hidden from admin panel**

### Evidence:
1. **Language List is Hardcoded**: The `languageList()` function in `lib/utils/common.dart` returns a hardcoded list:
   ```dart
   List<LanguageDataModel> languageList() {
     return [
       LanguageDataModel(id: 1, name: 'Norsk', languageCode: 'no', ...),
       LanguageDataModel(id: 2, name: 'English', languageCode: 'en', ...),
     ];
   }
   ```

2. **No Admin Configuration**: The `AppConfigurationModel` and `AppConfigurationStore` do NOT contain any language visibility settings. All admin panel configurations are for:
   - Payment methods
   - Service types (slot, digital, package, etc.)
   - Social login options
   - Chat, blog, wallet features
   - Dashboard types
   - But **NO language visibility controls**

3. **No Filtering Logic**: There's no code that filters languages based on admin panel settings. All languages in `languageList()` are always shown to users.

### Conclusion:
- Languages are **always visible** - all languages defined in `languageList()` are shown
- Admin panel **cannot control** which languages appear in the app
- To hide a language, you must **remove it from the hardcoded list** in the frontend code
- To show/hide languages dynamically, you would need to:
  1. Add language visibility settings to the backend API
  2. Add corresponding fields to `AppConfigurationModel`
  3. Modify `languageList()` to filter based on admin settings

