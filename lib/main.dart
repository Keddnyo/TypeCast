import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:windows1251/windows1251.dart';

void main() => runApp(const TypeCast());

class Constants {
  static String appName = 'TypeCast';

  static int androidAppsId = 212;
  static int androidGamesId = 213;
  static int wearableAppsId = 810;
}

class TypeCast extends StatefulWidget {
  const TypeCast({super.key});

  @override
  State<TypeCast> createState() => TypeCastState();
}

class TypeCastState extends State<TypeCast> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

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

  String getDateStart() {
    return DateFormat('dd.MM.yyyy').format(dateRange.start);
  }

  String getDateEnd() {
    return DateFormat('dd.MM.yyyy').format(dateRange.end);
  }

  ForumType? currentForum;

  void setForumType(ForumType type) async {
    setState(() {
      currentForum = type;
    });

    final SharedPreferences prefs = await _prefs;
    await prefs.setInt('forum', forumParams[type]!.id);
  }

  final forumTypes = {
    Constants.androidAppsId: ForumType.androidApps,
    Constants.androidGamesId: ForumType.androidGames,
    Constants.wearableAppsId: ForumType.wearableApps,
  };

  final forumParams = {
    ForumType.androidApps: ForumParams(
      id: Constants.androidAppsId,
      name: 'Android - Программы',
      digestTopicId: '127361',
      color: Colors.indigo,
      darkColor: Colors.lightBlue,
      recursive: true,
    ),
    ForumType.androidGames: ForumParams(
      id: Constants.androidGamesId,
      name: 'Android - Игры',
      digestTopicId: '381335',
      color: Colors.red,
      darkColor: Colors.amber,
      recursive: true,
    ),
    ForumType.wearableApps: ForumParams(
      id: Constants.wearableAppsId,
      name: 'Носимые устройства',
      digestTopicId: '979689',
      color: Colors.purple,
      darkColor: Colors.pink,
      recursive: false,
    ),
  };

  @override
  void initState() {
    super.initState();
    _prefs.then((SharedPreferences prefs) {
      var id = prefs.getInt('forum') ?? Constants.androidAppsId;
      final ForumType type = forumTypes[id]!;
      setState(() {
        currentForum = type;
      });
    });
  }

  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TypeCastInheritedWidget(
        state: this,
        child: _MainContent(),
      ),
      title: Constants.appName,
      theme: FlexThemeData.light(
        primary: forumParams[currentForum]?.color,
        secondary: forumParams[currentForum]?.color,
        fontFamily: 'Comic Sans MS',
      ),
      darkTheme: FlexThemeData.dark(
        primary: forumParams[currentForum]?.darkColor,
        secondary: forumParams[currentForum]?.darkColor,
        fontFamily: 'Comic Sans MS',
        darkIsTrueBlack: true,
      ),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
      ],
    );
  }
}

class _MainContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = TypeCastInheritedWidget.of(context)!.state;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
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
                state.forumParams[state.currentForum]?.name ??
                    Constants.appName,
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
        ),
        flexibleSpace: Theme.of(context).brightness == Brightness.light
            ? AppBarBackground(state: state)
            : null,
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
      body: _DigestContent(),
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
              .replaceAll('4pda.ru', '4pda.to');

          if (snapshot.data?.statusCode == 200) {
            return Scaffold(
              body: ListView(
                controller: state.controller,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Linkify(
                      text: content.replaceAll('&#9733;', '★'),
                      onOpen: (link) {
                        launchUrl(
                          Uri.parse(link.url),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      options: const LinkifyOptions(looseUrl: true),
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                icon: const Icon(Icons.send),
                label: const Text('Отправить'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: content));
                  launchUrl(
                    Uri.parse(
                      'https://4pda.to/forum/index.php?showtopic=${state.forumParams[state.currentForum]?.digestTopicId}',
                    ),
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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Constants.appName,
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
              state.forumParams[ForumType.androidApps]!.name,
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
              state.forumParams[ForumType.androidGames]!.name,
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
              state.forumParams[ForumType.wearableApps]!.name,
            ),
            onTap: () {
              state.setForumType(ForumType.wearableApps);
              if (state.controller.hasClients) state.controller.jumpTo(0);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Keddnyo'),
            onTap: () {
              Navigator.pop(context);
              launchUrl(
                Uri.parse(
                  'https://4pda.to/forum/index.php?showuser=8096247',
                ),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('О программе'),
            onTap: () {
              Navigator.pop(context);
              launchUrl(
                Uri.parse(
                  'https://github.com/Keddnyo/TypeCast#readme',
                ),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
        ],
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
  String name;
  String digestTopicId;
  MaterialColor color;
  MaterialColor darkColor;
  bool recursive;

  ForumParams({
    required this.id,
    required this.name,
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
