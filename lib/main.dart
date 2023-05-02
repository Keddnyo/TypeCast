import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'domain/enum/forum_type.dart';
import 'domain/inherited_widget/type_cast_inherited_widget.dart';
import 'domain/model/forum_params.dart';
import 'ui/screen/main_screen.dart';
import 'ui/screen/settings_screen.dart';

void main() => runApp(const TypeCast());

class TypeCast extends StatefulWidget {
  const TypeCast({super.key});

  static String appName = 'TypeCast';

  static bool softWrap = true;
  static bool openLastPost = true;

  static int androidAppsId = 212;
  static int androidGamesId = 213;
  static int wearableAppsId = 810;

  @override
  State<TypeCast> createState() => TypeCastState();
}

class TypeCastState extends State<TypeCast> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  bool isDarkMode = false;
  bool isSoftWrap = TypeCast.softWrap;
  bool isOpenLastPost = false;

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
          '/': (context) => const MainScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
