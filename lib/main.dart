import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:windows1251/windows1251.dart';

void main() => runApp(const TypeCast());

class Constants {
  static String appName = 'TypeCast';
}

class TypeCast extends StatefulWidget {
  const TypeCast({super.key});

  @override
  State<TypeCast> createState() => TypeCastState();
}

class TypeCastState extends State<TypeCast> {
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

  var currentForum = ForumType.androidApps;

  void setCurrentForum(ForumType type) {
    setState(() {
      currentForum = type;
    });
  }

  final forumParams = {
    ForumType.androidApps: ForumParams(
      id: 212,
      name: 'Android - Программы',
      digestTopicId: '127361',
      color: Colors.indigo,
    ),
    ForumType.androidGames: ForumParams(
      id: 213,
      name: 'Android - Игры',
      digestTopicId: '381335',
      color: Colors.green,
    ),
    ForumType.wearableApps: ForumParams(
      id: 810,
      name: 'Носимые устройства',
      digestTopicId: '979689',
      color: Colors.purple,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TypeCastInheritedWidget(
        state: this,
        child: _MainContent(),
      ),
      title: Constants.appName,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: forumParams[currentForum]!.color,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
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
        title: Text(
          state.forumParams[state.currentForum]!.name,
        ),
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
            },
          )
        ],
      ),
      body: _DigestContent(),
      drawer: NavigationDrawer(state: state),
    );
  }
}

class _DigestContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = TypeCastInheritedWidget.of(context)!.state;

    var startDate = DateFormat('dd.MM.yyyy').format(state.dateRange.start);
    var endDate = DateFormat('dd.MM.yyyy').format(state.dateRange.end);

    var digestResponse = () async {
      try {
        return await http.get(
          Uri.parse(
            'https://4pda.to/forum/dig_an_prog.php?act=nocache&f=${state.forumParams[state.currentForum]!.id}&date_from=$startDate&date_to=$endDate&recursive=true',
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
          var content = windows1251.decode(snapshot.data!.bodyBytes);
          return Scaffold(
            body: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              child: const Icon(Icons.send),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: content));
                launchUrl(
                  Uri.parse(
                    'https://4pda.to/forum/index.php?showtopic=${state.forumParams[state.currentForum]!.digestTopicId}',
                  ),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          );
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
              child: Text(
                Constants.appName,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
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
              state.setCurrentForum(ForumType.androidApps);
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
              state.setCurrentForum(ForumType.androidGames);
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
              state.setCurrentForum(ForumType.wearableApps);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('GitHub'),
            onTap: () {
              Navigator.pop(context);
              launchUrl(
                Uri.parse(
                  'https://github.com/Keddnyo/TypeCast',
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

  ForumParams({
    required this.id,
    required this.name,
    required this.digestTopicId,
    required this.color,
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
