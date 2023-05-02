import 'dart:ui';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:windows1251/windows1251.dart';

void main() => runApp(const TypeCast());

class TypeCast extends StatefulWidget {
  const TypeCast({super.key});

  static String appName = 'TypeCast';

  static bool darkMode = false;
  static bool softWrap = true;
  static bool openLastPost = false;

  static int androidAppsId = 212;
  static int androidGamesId = 213;
  static int wearableAppsId = 810;

  @override
  State<TypeCast> createState() => TypeCastState();
}

class TypeCastState extends State<TypeCast> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  bool isDarkMode = TypeCast.darkMode;
  bool isSoftWrap = TypeCast.softWrap;
  bool isOpenLastPost = TypeCast.openLastPost;

  changeTheme(bool darkMode) async {
    setState(() => isDarkMode = darkMode);
    await _prefs.then(
      (prefs) => prefs.setBool('theme', isDarkMode),
    );
  }

  setSoftWrap(bool newValue) async {
    setState(() => isSoftWrap = newValue);
    await _prefs.then(
      (prefs) => prefs.setBool('use-soft-wrap', isOpenLastPost),
    );
  }

  setOpenLastPost(bool condition) async {
    setState(() => isOpenLastPost = condition);
    await _prefs.then(
      (prefs) => prefs.setBool('open-last-post', isOpenLastPost),
    );
  }

  var dateRange = DateTimeRange(
    start: DateTime.now().subtract(
      const Duration(days: 6),
    ),
    end: DateTime.now(),
  );

  void setDateRange(DateTimeRange range) {
    setState(() {
      dateRange = range;
    });
  }

  String getDateStart() => DateFormat('dd.MM.yyyy').format(dateRange.start);
  String getDateEnd() => DateFormat('dd.MM.yyyy').format(dateRange.end);

  ForumType? currentForum;

  void setForumType(ForumType type) async {
    setState(() {
      currentForum = type;
    });

    final SharedPreferences prefs = await _prefs;
    await prefs.setInt('forum', forumParams[type]!.id);
  }

  final forumTypes = {
    TypeCast.androidAppsId: ForumType.androidApps,
    TypeCast.androidGamesId: ForumType.androidGames,
    TypeCast.wearableAppsId: ForumType.wearableApps,
  };

  final forumParams = {
    ForumType.androidApps: ForumParams(
      id: TypeCast.androidAppsId,
      digestTopicId: '127361',
      color: Colors.indigo,
      darkColor: Colors.lightBlue,
      recursive: 1,
    ),
    ForumType.androidGames: ForumParams(
      id: TypeCast.androidGamesId,
      digestTopicId: '381335',
      color: Colors.red,
      darkColor: Colors.amber,
      recursive: 1,
    ),
    ForumType.wearableApps: ForumParams(
      id: TypeCast.wearableAppsId,
      digestTopicId: '979689',
      color: Colors.purple,
      darkColor: Colors.pink,
      recursive: 0,
    ),
  };

  @override
  void initState() {
    super.initState();
    _prefs.then((SharedPreferences prefs) {
      var darkMode = prefs.getBool('theme') ?? false;

      var forumId = prefs.getInt('forum');
      final ForumType type = forumTypes[forumId]!;

      var useSoftWrap = prefs.getBool('use-soft-wrap') ?? TypeCast.softWrap;
      var openLastPost =
          prefs.getBool('open-last-post') ?? TypeCast.openLastPost;

      setState(() {
        isDarkMode = darkMode;
        currentForum = type;
        isSoftWrap = useSoftWrap;
        isOpenLastPost = openLastPost;
      });
    });
  }

  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return TypeCastInheritedWidget(
      state: this,
      child: MaterialApp(
        title: TypeCast.appName,
        theme: FlexThemeData.light(
          primary: forumParams[currentForum]?.color,
          secondary: forumParams[currentForum]?.color,
        ),
        darkTheme: FlexThemeData.dark(
          primary: forumParams[currentForum]?.darkColor,
          secondary: forumParams[currentForum]?.darkColor,
          darkIsTrueBlack: true,
        ),
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: '/',
        routes: {
          '/': (context) => _MainScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
        scrollBehavior: AppScrollBehavior(),
      ),
    );
  }
}

class _MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = TypeCastInheritedWidget.of(context)!.state;
    final textRes = AppLocalizations.of(context)!;

    String forumTitle;

    switch (state.currentForum) {
      case ForumType.androidApps:
        forumTitle = textRes.androidApps;
        break;
      case ForumType.androidGames:
        forumTitle = textRes.androidGames;
        break;
      case ForumType.wearableApps:
        forumTitle = textRes.wearableApps;
        break;
      default:
        forumTitle = TypeCast.appName;
    }

    return Scaffold(
      appBar: AppBar(
        title: state.currentForum != null
            ? GestureDetector(
                onTap: () {
                  state.controller.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.decelerate,
                  );
                },
                child: Column(
                  children: [
                    Text(
                      forumTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${state.getDateStart()} - ${state.getDateEnd()}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              )
            : Text(TypeCast.appName),
        flexibleSpace: AppBarBackground(state: state),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar),
            onPressed: () async {
              await showDateRangePicker(
                context: context,
                initialDateRange: state.dateRange,
                initialEntryMode: DatePickerEntryMode.calendarOnly,
                firstDate: DateTime.now().subtract(const Duration(days: 90)),
                lastDate: DateTime.now(),
              ).then(
                (range) => state.setDateRange(range ?? state.dateRange),
              );
              state.controller.jumpTo(0);
            },
          ),
        ],
      ),
      body: state.currentForum != null
          ? _DigestContent()
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu),
                    Text(
                      textRes.openForumHint,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
      drawer: NavigationDrawer(state: state),
    );
  }
}

class AppBarBackground extends StatelessWidget {
  const AppBarBackground({
    super.key,
    required this.state,
  });

  final TypeCastState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            state.forumParams[state.currentForum]?.color ?? Colors.blue,
            state.forumParams[state.currentForum]?.darkColor.darken() ??
                Colors.blue,
          ],
        ),
      ),
    );
  }
}

class _DigestContent extends StatefulWidget {
  @override
  State<_DigestContent> createState() => _DigestContentState();
}

class _DigestContentState extends State<_DigestContent> {
  @override
  Widget build(BuildContext context) {
    final state = TypeCastInheritedWidget.of(context)!.state;

    var startDate = state.getDateStart();
    var endDate = state.getDateEnd();

    var digestResponse = () async {
      try {
        return await http.get(
          Uri.parse(
            'https://4pda.to/forum/dig_an_prog.php?act=nocache&f=${state.forumParams[state.currentForum]?.id}&date_from=$startDate&date_to=$endDate&recursive=${state.forumParams[state.currentForum]?.recursive}',
          ),
        );
      } catch (e) {
        return http.Response(e.toString(), 503);
      }
    }();

    return FutureBuilder(
      future: digestResponse,
      builder: ((context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        } else {
          var content = windows1251
              .decode(snapshot.data!.bodyBytes)
              .replaceAll('4pda.ru', '4pda.to')
              .replaceAll('&#9733;', '★');

          if (snapshot.data?.statusCode == 200) {
            String digest = content;

            switch (state.currentForum) {
              case ForumType.androidGames:
                digest =
                    '${digest.replaceAll('[/list]\n[CENTER][b]', '[/list]\n[/spoiler]\n[CENTER][b]').replaceAll('[CENTER][b]', '[spoiler=').replaceAll('[/b][/CENTER]', ']')}\n[/spoiler]'
                        .replaceAll(
                            '[/spoiler]\n[spoiler', '[/spoiler][spoiler');
                break;
              case ForumType.wearableApps:
                break;
              default:
                digest =
                    '${digest.replaceAll('[/CENTER]', '[/CENTER]\n[spoiler]').replaceAll('[/list]\n[CENTER]', '[/list]\n[/spoiler]\n[CENTER]')}\n[/spoiler]';
            }

            showLinkifyText(bool softWrap) {
              return Linkify(
                softWrap: state.isSoftWrap,
                text: digest,
                onOpen: (link) {
                  launchUrl(
                    Uri.parse(link.url),
                    mode: LaunchMode.externalApplication,
                  );
                },
                options: const LinkifyOptions(
                  humanize: false,
                  looseUrl: true,
                ),
                style: const TextStyle(
                  fontSize: 16,
                ),
                linkStyle: !state.isDarkMode
                    ? TextStyle(color: Theme.of(context).colorScheme.primary)
                    : null,
              );
            }

            return Scaffold(
              body: ListView(
                controller: state.controller,
                children: [
                  SingleChildScrollView(
                    scrollDirection:
                        state.isSoftWrap ? Axis.vertical : Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: showLinkifyText(state.isSoftWrap),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                icon: const Icon(Icons.send),
                label: Text(AppLocalizations.of(context)!.send),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: digest));

                  var digestTopicLink =
                      'https://4pda.to/forum/index.php?showtopic=${state.forumParams[state.currentForum]?.digestTopicId}';
                  if (state.isOpenLastPost) {
                    digestTopicLink = '$digestTopicLink&view=getlastpost';
                  }

                  launchUrl(
                    Uri.parse(digestTopicLink),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            );
          } else {
            return Scaffold(
              body: Center(
                child: Text(
                  snapshot.data!.body,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  state.setDateRange(state.dateRange);
                },
                child: const Icon(Icons.refresh),
              ),
            );
          }
        }
      }),
    );
  }
}

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({
    super.key,
    required this.state,
  });

  final TypeCastState state;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: state.isDarkMode ? Colors.black : null,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  state.forumParams[state.currentForum]?.color ?? Colors.blue,
                  state.forumParams[state.currentForum]?.darkColor ??
                      Colors.blue,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    TypeCast.appName,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    'Created by Keddnyo',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            selected: state.currentForum == ForumType.androidApps,
            leading: const Icon(Icons.android),
            title: Text(
              AppLocalizations.of(context)!.androidApps,
            ),
            onTap: () {
              state.setForumType(ForumType.androidApps);
              if (state.controller.hasClients) state.controller.jumpTo(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            selected: state.currentForum == ForumType.androidGames,
            leading: const Icon(Icons.catching_pokemon),
            title: Text(
              AppLocalizations.of(context)!.androidGames,
            ),
            onTap: () {
              state.setForumType(ForumType.androidGames);
              if (state.controller.hasClients) state.controller.jumpTo(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            selected: state.currentForum == ForumType.wearableApps,
            leading: const Icon(Icons.watch),
            title: Text(
              AppLocalizations.of(context)!.wearableApps,
            ),
            onTap: () {
              state.setForumType(ForumType.wearableApps);
              if (state.controller.hasClients) state.controller.jumpTo(0);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(AppLocalizations.of(context)!.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
    );
  }
}

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
    _packageInfo.then((info) => setState(() => appVersion = info.version));
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

enum ForumType {
  androidApps,
  androidGames,
  wearableApps,
}

class ForumParams {
  int id;
  String digestTopicId;
  MaterialColor color;
  MaterialColor darkColor;
  int recursive;

  ForumParams({
    required this.id,
    required this.digestTopicId,
    required this.color,
    required this.darkColor,
    required this.recursive,
  });
}

class TypeCastInheritedWidget extends InheritedWidget {
  final TypeCastState state;

  const TypeCastInheritedWidget(
      {super.key, required super.child, required this.state});

  @override
  bool updateShouldNotify(covariant TypeCastInheritedWidget oldWidget) {
    return state.currentForum != oldWidget.state.currentForum;
  }

  static TypeCastInheritedWidget? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TypeCastInheritedWidget>();
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
