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

import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";

import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:flutter_riverpod/flutter_riverpod.dart";

final apisProvider =
    NotifierProvider.autoDispose<ApisNotifier, void>(ApisNotifier.new);

class ApisNotifier extends AutoDisposeNotifier<void> {
  @override
  void build() {}
  void notify() => ref.notifyListeners();
}

class ApisTab extends ConsumerWidget {
  const ApisTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(apisProvider);
    final apis = Config.apis.entries.toList();

    return Stack(
      children: [
        ListView.builder(
          padding:
              const EdgeInsets.only(top: 4, left: 16, right: 16, bottom: 16),
          itemCount: apis.length,
          itemBuilder: (context, index) {
            return Card.filled(
              margin: const EdgeInsets.only(top: 12),
              child: ListTile(
                title: Text(
                  apis[index].key,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: const Icon(Icons.api),
                contentPadding: const EdgeInsets.only(left: 16, right: 8),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async => await showDialog(
                    context: context,
                    builder: (context) => ApiSettings(apiPair: apis[index]),
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            icon: const Icon(Icons.api),
            label: Text(S.of(context).new_api),
            onPressed: () async => await showDialog<bool>(
              context: context,
              builder: (context) => ApiSettings(),
            ),
          ),
        ),
      ],
    );
  }
}

class ApiSettings extends ConsumerStatefulWidget {
  final MapEntry<String, ApiConfig>? apiPair;

  const ApiSettings({
    super.key,
    this.apiPair,
  });

  @override
  ConsumerState<ApiSettings> createState() => ApiSettingsState();
}

class ApiSettingsState extends ConsumerState<ApiSettings> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _modelsCtrl = TextEditingController();
  final TextEditingController _apiUrlCtrl = TextEditingController();
  final TextEditingController _apiKeyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    final apiPair = widget.apiPair;

    if (apiPair != null) {
      _nameCtrl.text = apiPair.key;
      _apiUrlCtrl.text = apiPair.value.url;
      _apiKeyCtrl.text = apiPair.value.key;
      _modelsCtrl.text = apiPair.value.models.join(", ");
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _apiUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiPair = widget.apiPair;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(S.of(context).api),
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: S.of(context).name,
                      border: OutlineInputBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _apiUrlCtrl,
                    decoration: InputDecoration(
                      labelText: S.of(context).api_url,
                      border: OutlineInputBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyCtrl,
              decoration: InputDecoration(
                labelText: S.of(context).api_key,
                border: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    maxLines: 4,
                    controller: _modelsCtrl,
                    decoration: InputDecoration(
                      labelText: S.of(context).model_list,
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton.outlined(
                      onPressed: () async => _fetchModels(context),
                      icon: const Icon(Icons.sync),
                    ),
                    const SizedBox(height: 8),
                    IconButton.outlined(
                      onPressed: () async => _editModels(context),
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: FilledButton.tonal(
                    child: Text(S.of(context).cancel),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 8),
                if (apiPair != null)
                  Expanded(
                    flex: 1,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      child: Text(S.of(context).delete),
                      onPressed: () async {
                        Config.apis.remove(apiPair.key);
                        ref.read(apisProvider.notifier).notify();
                        Navigator.of(context).pop(true);
                        await Config.save();
                      },
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: FilledButton(
                    child: Text(S.of(context).save),
                    onPressed: () async {
                      if (!_save(context)) return;
                      Navigator.of(context).pop(true);
                      await Config.save();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchModels(BuildContext context) async {
    final url = _apiUrlCtrl.text;
    final key = _apiKeyCtrl.text;

    if (url.isEmpty || key.isEmpty) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).complete_all_fields),
      );
      return;
    }

    final modelsEndpoint = "$url/models";

    try {
      final response = await http.get(
        Uri.parse(modelsEndpoint),
        headers: {"Authorization": "Bearer $key"},
      );

      if (response.statusCode != 200) {
        throw "${response.statusCode} ${response.body}";
      }

      final json = jsonDecode(response.body);
      final models = <String>[for (final cell in json["data"]) cell["id"]];

      _modelsCtrl.text = models.join(", ");
    } catch (e) {
      if (!context.mounted) return;
      await Util.handleError(context: context, error: e);
    }
  }

  Future<void> _editModels(BuildContext context) async {
    final models = _modelsCtrl.text;
    if (models.isEmpty) return;

    final chosen = {for (final model in models.split(",")) model.trim(): true};
    if (chosen.isEmpty) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(S.of(context).select_models),
              content: SingleChildScrollView(
                child: ListBody(
                  children: chosen.keys.map((model) {
                    return CheckboxListTile(
                      title: Text(model),
                      value: chosen[model],
                      onChanged: (value) =>
                          setState(() => chosen[model] = value ?? false),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: Text(S.of(context).cancel),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text(S.of(context).clear),
                  onPressed: () => setState(() =>
                      chosen.forEach((model, _) => chosen[model] = false)),
                ),
                TextButton(
                  child: Text(S.of(context).save),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !result) return;

    _modelsCtrl.text = [
      for (final pair in chosen.entries)
        if (pair.value) pair.key
    ].join(", ");
  }

  bool _save(BuildContext context) {
    final name = _nameCtrl.text;
    final models = _modelsCtrl.text;
    final apiUrl = _apiUrlCtrl.text;
    final apiKey = _apiKeyCtrl.text;

    if (name.isEmpty || models.isEmpty || apiUrl.isEmpty || apiKey.isEmpty) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).complete_all_fields),
      );
      return false;
    }

    final apiPair = widget.apiPair;
    if (Config.apis.containsKey(name) &&
        (apiPair == null || name != apiPair.key)) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).duplicate_api_name),
      );
      return false;
    }

    if (apiPair != null) Config.apis.remove(apiPair.key);

    final modelList = models.split(",").map((e) => e.trim()).toList();
    Config.apis[name] = ApiConfig(
      url: apiUrl,
      key: apiKey,
      models: modelList,
    );

    ref.read(apisProvider.notifier).notify();
    return true;
  }
}
