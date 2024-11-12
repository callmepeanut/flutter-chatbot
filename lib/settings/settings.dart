// This file is part of ChatBot.
//
// ChatBot is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ChatBot is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ChatBot. If not, see <https://www.gnu.org/licenses/>.

import "bot.dart";
import "api.dart";
import "../gen/l10n.dart";

import "package:flutter/material.dart";

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).settings),
          bottom: TabBar(
            tabs: [
              Tab(text: S.of(context).bot),
              Tab(text: S.of(context).apis),
              Tab(text: S.of(context).other),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const BotTab(),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: const ApisTab(),
            ),
            Center(child: Text(S.of(context).other)),
          ],
        ),
      ),
    );
  }
}
