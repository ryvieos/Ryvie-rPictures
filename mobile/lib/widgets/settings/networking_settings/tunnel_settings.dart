import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/providers/auth.provider.dart';
import 'package:immich_mobile/widgets/common/immich_toast.dart';

/// Widget pour configurer les informations du tunnel Ryvie
/// Permet de sauvegarder l'adresse du tunnel et l'URL publique
/// pour la sélection intelligente de l'URL du serveur
class TunnelSettings extends HookConsumerWidget {
  const TunnelSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunnelHostController = useTextEditingController();
    final publicUrlController = useTextEditingController();
    final isSaving = useState(false);
    final isAutoConfigured = useState(false);

    // Charger les informations sauvegardées au démarrage
    useEffect(() {
      final tunnelInfo = ref.read(authProvider.notifier).getTunnelInfo();
      if (tunnelInfo.tunnelHost != null) {
        tunnelHostController.text = tunnelInfo.tunnelHost!;
        isAutoConfigured.value = true;
      }
      if (tunnelInfo.publicUrl != null) {
        publicUrlController.text = tunnelInfo.publicUrl!;
        isAutoConfigured.value = true;
      }
      return null;
    }, []);

    Future<void> saveTunnelInfo() async {
      isSaving.value = true;
      try {
        await ref
            .read(authProvider.notifier)
            .saveTunnelInfo(
              tunnelHost: tunnelHostController.text.trim().isEmpty ? null : tunnelHostController.text.trim(),
              publicUrl: publicUrlController.text.trim().isEmpty ? null : publicUrlController.text.trim(),
            );

        if (context.mounted) {
          ImmichToast.show(context: context, msg: 'tunnel_info_saved'.tr(), toastType: ToastType.success);
        }
      } catch (e) {
        if (context.mounted) {
          ImmichToast.show(context: context, msg: 'tunnel_info_save_error'.tr(), toastType: ToastType.error);
        }
      } finally {
        isSaving.value = false;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: context.colorScheme.surfaceContainerHighest, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'tunnel_settings_title'.tr(),
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'tunnel_settings_description'.tr(),
                style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface.withAlpha(180)),
              ),
              if (isAutoConfigured.value) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withAlpha(100), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'tunnel_auto_configured'.tr(),
                          style: context.textTheme.bodySmall?.copyWith(color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: tunnelHostController,
                decoration: InputDecoration(
                  labelText: 'tunnel_host_label'.tr(),
                  hintText: 'tunnel_host_hint'.tr(),
                  helperText: 'tunnel_host_helper'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.dns_outlined),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: publicUrlController,
                decoration: InputDecoration(
                  labelText: 'public_url_label'.tr(),
                  hintText: 'public_url_hint'.tr(),
                  helperText: 'public_url_helper'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.public_outlined),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSaving.value ? null : saveTunnelInfo,
                  icon: isSaving.value
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text('save_button'.tr()),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
