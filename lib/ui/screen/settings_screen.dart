import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:typecast/domain/inherited_widget/type_cast_inherited_widget.dart';
import 'package:typecast/main.dart';
import 'package:url_launcher/url_launcher.dart';

import '../component/app_bar_components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  String? appVersion;

  @override
  void initState() {
    super.initState();
    _packageInfo.then((info) => appVersion = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final state = TypeCastInheritedWidget.of(context)!.state;
    final textRes = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(textRes.settings),
        centerTitle: true,
        flexibleSpace: AppBarBackground(state: state),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text(textRes.appearance),
            tiles: [
              SettingsTile.switchTile(
                initialValue: state.isDarkMode,
                onToggle: (value) => state.changeTheme(value),
                activeSwitchColor: Theme.of(context).colorScheme.primary,
                leading: const Icon(Icons.wrap_text),
                title: Text(textRes.darkMode),
                description: Text(textRes.darkModeSummary),
              ),
            ],
          ),
          SettingsSection(
            title: Text(textRes.behavior),
            tiles: [
              SettingsTile.switchTile(
                initialValue: state.isSoftWrap,
                onToggle: (value) => state.setSoftWrap(value),
                activeSwitchColor: Theme.of(context).colorScheme.primary,
                leading: const Icon(Icons.wrap_text),
                title: Text(textRes.softWrap),
                description: Text(textRes.softWrapSummary),
              ),
              SettingsTile.switchTile(
                initialValue: state.isOpenLastPost,
                onToggle: (value) => state.setOpenLastPost(value),
                activeSwitchColor: Theme.of(context).colorScheme.primary,
                leading: const Icon(Icons.fast_forward),
                title: Text(textRes.openLastPost),
                description: Text(textRes.openLastPostSummary),
              ),
            ],
          ),
          SettingsSection(
            title: Text(textRes.about),
            tiles: [
              SettingsTile(
                leading: const Icon(Icons.info),
                title: Text('${TypeCast.appName} ${appVersion ?? ''}'),
                description: Text(textRes.aboutSummary),
                onPressed: (context) {
                  launchUrl(
                    Uri.parse(
                      'https://github.com/Keddnyo/TypeCast',
                    ),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              SettingsTile(
                leading: const Icon(Icons.account_circle),
                title: const Text('Keddnyo'),
                description: Text(textRes.developer),
                onPressed: (context) {
                  launchUrl(
                    Uri.parse(
                      'https://4pda.to/forum/index.php?showuser=8096247',
                    ),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ],
          ),
        ],
        platform: DevicePlatform.iOS,
        lightTheme: SettingsThemeData(
          titleTextColor: Theme.of(context).colorScheme.primary,
          leadingIconsColor: Theme.of(context).colorScheme.primary,
        ),
        darkTheme: SettingsThemeData(
          settingsListBackground: Theme.of(context).colorScheme.background,
          leadingIconsColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
