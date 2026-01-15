import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';

class LanguagesScreen extends StatefulWidget {
  @override
  LanguagesScreenState createState() => LanguagesScreenState();
}

class LanguagesScreenState extends State<LanguagesScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.language,
      child: LanguageListWidget(
        widgetType: WidgetType.LIST,
        onLanguageChange: (v) async {
          // Save language and wait for it to complete
          await appStore.setLanguage(v.languageCode!);
          // Ensure the language is persisted before restarting (setLanguage already saves it, but double-check)
          await setValue('selected_language_code', v.languageCode!);
          setState(() {});
          finish(context, true);
          // Small delay to ensure language is fully saved
          await Future.delayed(Duration(milliseconds: 200));
          // Restart app to apply language changes
          if (mounted) {
            RestartAppWidget.init(context);
          }
        },
      ),
    );
  }
}
