import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:typecast/domain/enum/forum_type.dart';
import 'package:typecast/domain/inherited_widget/type_cast_inherited_widget.dart';
import 'package:typecast/main.dart';
import 'package:typecast/ui/component/app_bar_components.dart';
import 'package:typecast/ui/component/navigation_drawer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:windows1251/windows1251.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

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
        ),
        flexibleSpace: state.isDarkMode ? null : AppBarBackground(state: state),
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
          ? _DigestScreen()
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
      drawer: TypeCastNavigationDrawer(state: state),
    );
  }
}

class _DigestScreen extends StatefulWidget {
  @override
  State<_DigestScreen> createState() => _DigestScreenState();
}

class _DigestScreenState extends State<_DigestScreen> {
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
