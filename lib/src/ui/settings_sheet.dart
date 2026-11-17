import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../save/save_store.dart';
import 'style/style_a.dart';

/// `PRIVACY.md` as served on the Pages site (ADR 0007, deploy-web.yml).
final privacyUri = Uri.parse('https://flaszki.pages.dev/PRIVACY.md');

/// Opens a URL outside the app (default: `url_launcher`'s `launchUrl`).
typedef UrlOpener = Future<bool> Function(Uri url);

/// Settings sheet (PRD §4.6). Back/Esc close it (modal route). Every toggle
/// goes straight to [settings] (the app persists it). Strings: #30.
Future<void> showSettingsSheet(
  BuildContext context, {
  required ValueNotifier<Settings> settings,
  required UrlOpener openUrl,
  String? version,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: StyleA.skyTop,
  showDragHandle: true,
  builder: (context) =>
      SettingsSheet(settings: settings, openUrl: openUrl, version: version),
);

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({
    super.key,
    required this.settings,
    required this.openUrl,
    this.version,
  });

  final ValueNotifier<Settings> settings;
  final UrlOpener openUrl;
  final String? version;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: settings,
    builder: (context, s, _) => SafeArea(
      child: Column(
        key: const ValueKey('settings-sheet'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            key: const ValueKey('settings-patterns'),
            title: const Text('Colorblind patterns'),
            value: s.colorblindPatterns,
            onChanged: (v) => settings.value = Settings(
              colorblindPatterns: v,
              sound: s.sound,
              music: s.music,
              haptics: s.haptics,
            ),
          ),
          SwitchListTile(
            key: const ValueKey('settings-sound'),
            title: const Text('Sound'),
            value: s.sound,
            onChanged: (v) => settings.value = Settings(
              colorblindPatterns: s.colorblindPatterns,
              sound: v,
              music: s.music,
              haptics: s.haptics,
            ),
          ),
          ListTile(
            key: const ValueKey('settings-credits'),
            title: const Text('Credits and licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CreditsPage(version: version),
              ),
            ),
          ),
          ListTile(
            key: const ValueKey('settings-privacy'),
            title: const Text('Privacy'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => openUrl(privacyUri),
          ),
          if (version != null)
            ListTile(
              key: const ValueKey('settings-version'),
              title: const Text('Version'),
              trailing: Text(version!),
            ),
        ],
      ),
    ),
  );
}

/// `CREDITS.md` (bundled asset) + Flutter's license page.
class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key, this.version});

  final String? version;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Credits and licenses')),
    body: FutureBuilder(
      future: rootBundle.loadString('CREDITS.md'),
      builder: (context, snap) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              key: const ValueKey('credits-licenses'),
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Flaszki',
                applicationVersion: version,
              ),
              child: const Text('Open-source licenses'),
            ),
          ),
          const SizedBox(height: 16),
          SelectableText(snap.data ?? ''),
        ],
      ),
    ),
  );
}
