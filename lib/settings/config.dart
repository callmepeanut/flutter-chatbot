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

import "dart:io";

import "bot.dart";
import "api.dart";
import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";
import "../chat/chat.dart";

import "package:flutter/services.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class ConfigTab extends ConsumerStatefulWidget {
  const ConfigTab({super.key});

  @override
  ConsumerState<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends ConsumerState<ConfigTab> {
  String? _bot = Config.core.bot;
  String? _chatApi = Config.core.api;
  String? _chatModel = Config.core.model;

  String? _ttsApi = Config.tts.api;
  String? _ttsModel = Config.tts.model;
  final TextEditingController _ttsVoice =
      TextEditingController(text: Config.tts.voice);

  @override
  void dispose() {
    _ttsVoice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(botsProvider);
    ref.watch(apisProvider);

    final bots = Config.bots.keys;
    final apis = Config.apis.keys;
    final ttsModels = Config.apis[_ttsApi]?.models ?? [];
    final chatModels = Config.apis[_chatApi]?.models ?? [];

    if (!bots.contains(_bot)) _bot = null;
    if (!apis.contains(_ttsApi)) _ttsApi = null;
    if (!apis.contains(_chatApi)) _chatApi = null;
    if (!ttsModels.contains(_ttsModel)) _ttsModel = null;
    if (!chatModels.contains(_chatModel)) _chatModel = null;

    final botList = <DropdownMenuItem<String>>[];
    final apiList = <DropdownMenuItem<String>>[];
    final ttsModelList = <DropdownMenuItem<String>>[];
    final chatModelList = <DropdownMenuItem<String>>[];

    for (final bot in bots) {
      botList.add(DropdownMenuItem(
        value: bot,
        child: Text(bot, overflow: TextOverflow.ellipsis),
      ));
    }
    for (final api in apis) {
      apiList.add(DropdownMenuItem(
        value: api,
        child: Text(api, overflow: TextOverflow.ellipsis),
      ));
    }

    for (final model in ttsModels) {
      ttsModelList.add(DropdownMenuItem(
        value: model,
        child: Text(model, overflow: TextOverflow.ellipsis),
      ));
    }
    for (final model in chatModels) {
      chatModelList.add(DropdownMenuItem(
        value: model,
        child: Text(model, overflow: TextOverflow.ellipsis),
      ));
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(" ${S.of(context).default_config}"),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _bot,
                    items: botList,
                    isExpanded: true,
                    hint: Text(S.of(context).bot),
                    onChanged: (it) => setState(() => _bot = it),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _chatApi,
                    items: apiList,
                    isExpanded: true,
                    hint: Text(S.of(context).api),
                    onChanged: (it) => setState(() {
                      _chatModel = null;
                      _chatApi = it;
                    }),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _chatModel,
              items: chatModelList,
              isExpanded: true,
              menuMaxHeight: 480,
              hint: Text(S.of(context).model),
              onChanged: (it) => setState(() => _chatModel = it),
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(" ${S.of(context).text_to_speech}"),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ttsVoice,
                    decoration: InputDecoration(
                      hintText: S.of(context).voice,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _ttsApi,
                    items: apiList,
                    isExpanded: true,
                    hint: Text(S.of(context).api),
                    onChanged: (it) => setState(() {
                      _ttsModel = null;
                      _ttsApi = it;
                    }),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _ttsModel,
              items: ttsModelList,
              isExpanded: true,
              menuMaxHeight: 480,
              hint: Text(S.of(context).model),
              onChanged: (it) => setState(() => _ttsModel = it),
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: FilledButton.tonal(
                    child: Text(S.of(context).export_config),
                    onPressed: () async {
                      try {
                        final result = await Backup.exportConfig();
                        if (!result || !context.mounted) return;

                        Util.showSnackBar(
                          context: context,
                          content: Text(S.of(context).exported_successfully),
                        );
                      } on PathAccessException {
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(S.of(context).error),
                            content: Text(S.of(context).failed_to_export),
                            actions: [
                              TextButton(
                                child: Text(S.of(context).ok),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        await Util.handleError(context: context, error: e);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: FilledButton(
                    child: Text(S.of(context).import_config),
                    onPressed: () async {
                      try {
                        final result = await Backup.importConfig();
                        if (!result || !context.mounted) return;

                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(S.of(context).imported_successfully),
                            content: Text(S.of(context).restart_app),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(S.of(context).ok),
                              )
                            ],
                          ),
                        );

                        await SystemNavigator.pop();
                      } catch (e) {
                        if (!context.mounted) return;
                        await Util.handleError(context: context, error: e);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            icon: const Icon(Icons.save),
            label: Text(S.of(context).save),
            onPressed: () async {
              Config.core.bot = _bot;
              Config.core.api = _chatApi;
              Config.core.model = _chatModel;

              Config.tts.api = _ttsApi;
              Config.tts.model = _ttsModel;
              final voice = _ttsVoice.text;
              Config.tts.voice = voice.isEmpty ? null : voice;

              Util.showSnackBar(
                context: context,
                content: Text(S.of(context).saved_successfully),
              );

              ref.read(chatProvider.notifier).notify();
              await Config.save();
            },
          ),
        ),
      ],
    );
  }
}
