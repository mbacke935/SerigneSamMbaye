import 'package:flutter/material.dart';
import '../../../core/models/local_notification_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<LocalNotificationModel> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await NotificationService.instance.getHistory();
    if (mounted) {
      setState(() {
        _notifications = history;
        _loading = false;
      });
    }
  }

  Future<void> _clear() async {
    await NotificationService.instance.clearHistory();
    if (mounted) setState(() => _notifications = []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Tout effacer',
              onPressed: _clear,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmpty(context)
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72, endIndent: 16),
                    itemBuilder: (_, i) =>
                        _NotifTile(notif: _notifications[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none_rounded,
              size: 72, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Les nouveaux audios, vidéos et citations\napparaîtront ici.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Tile ──────────────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final LocalNotificationModel notif;
  const _NotifTile({required this.notif});

  IconData get _icon {
    switch (notif.type) {
      case 'audio':
        return Icons.headphones_rounded;
      case 'video':
        return Icons.videocam_rounded;
      case 'citation':
        return Icons.format_quote_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _color {
    switch (notif.type) {
      case 'audio':
        return AppTheme.primary;
      case 'video':
        return const Color(0xFF1565C0);
      case 'citation':
        return AppTheme.gold;
      default:
        return AppTheme.textSecondary;
    }
  }

  String get _timeLabel {
    final diff = DateTime.now().difference(notif.receivedAt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_icon, color: _color, size: 22),
      ),
      title: Text(
        notif.title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notif.body.isNotEmpty)
            Text(
              notif.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          const SizedBox(height: 2),
          Text(
            _timeLabel,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
      isThreeLine: notif.body.isNotEmpty,
    );
  }
}
