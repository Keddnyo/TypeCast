import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:typecast/domain/enum/forum_type.dart';

import '../../main.dart';

class TypeCastNavigationDrawer extends StatelessWidget {
  const TypeCastNavigationDrawer({
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
