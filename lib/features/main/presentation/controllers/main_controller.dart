import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_remote_data_source.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/features/main/presentation/screens/home_screen.dart';
import 'package:jg_business/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:jg_business/shared/services/notification_service.dart';

class MainController extends GetxController {
  MainController({
    required GoogleAuthRemoteDataSource googleAuthRemoteDataSource,
    required CalendarController calendarController,
    required NotificationService notificationService,
  }) : _googleAuthRemoteDataSource = googleAuthRemoteDataSource,
       _calendarController = calendarController,
       _notificationService = notificationService;

  final GoogleAuthRemoteDataSource _googleAuthRemoteDataSource;
  final CalendarController _calendarController;
  final NotificationService _notificationService;

  late final bodies = <Widget>[
    const HomeScreen(),
    const CalendarScreen(),
    const _PlaceholderScreen(
      title: '顧客',
      subtitle: '顧客一覧、企業詳細、担当者、名刺スキャン確認をここに集約します。',
      icon: Icons.contact_page_outlined,
    ),
    const _PlaceholderScreen(
      title: 'アクティビティ',
      subtitle: '面談記録、通話要約、通知履歴、同期失敗項目をここで確認します。',
      icon: Icons.local_activity_outlined,
    ),
    const _MoreScreen(),
  ];

  final destinations = const <({String label, IconData icon, IconData selectedIcon})>[
    (
      label: 'ホーム',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    (
      label: 'カレンダー',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    (
      label: '顧客',
      icon: Icons.contact_page_outlined,
      selectedIcon: Icons.contact_page,
    ),
    (
      label: '活動',
      icon: Icons.local_activity_outlined,
      selectedIcon: Icons.local_activity,
    ),
    (
      label: 'その他',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
    ),
  ];

  final _selectedIndex = 0.obs;
  final _isSigningOut = false.obs;
  final _areNotificationsAllowed = false.obs;
  final _pendingReminderCount = 0.obs;
  final _isRefreshingNotificationStatus = false.obs;

  int get selectedIndex => _selectedIndex.value;
  bool get isSigningOut => _isSigningOut.value;
  bool get areNotificationsAllowed => _areNotificationsAllowed.value;
  int get pendingReminderCount => _pendingReminderCount.value;
  bool get isRefreshingNotificationStatus => _isRefreshingNotificationStatus.value;

  @override
  void onInit() {
    super.onInit();
    refreshNotificationStatus();
  }

  void onDestinationSelected(int value) {
    _selectedIndex.value = value;

    if (value == 4) {
      refreshNotificationStatus();
    }
  }

  Future<void> refreshNotificationStatus() async {
    try {
      _isRefreshingNotificationStatus.value = true;
      _areNotificationsAllowed.value =
          await _notificationService.areNotificationsAllowed();
      _pendingReminderCount.value =
          await _notificationService.pendingCalendarReminderCount();
    } finally {
      _isRefreshingNotificationStatus.value = false;
    }
  }

  Future<void> reconnectCalendar() async {
    await _calendarController.connectCalendar();
    await refreshNotificationStatus();
  }

  Future<void> requestNotificationPermission() async {
    await _notificationService.requestPermissions();
    await refreshNotificationStatus();
  }

  Future<void> signOutGoogle() async {
    if (_isSigningOut.value) return;

    try {
      _isSigningOut.value = true;
      await _googleAuthRemoteDataSource.signOut();
      await _calendarController.fetchCalendar(interactive: false);
      await refreshNotificationStatus();
      Get.snackbar(
        'ログアウト完了',
        'Google アカウントからサインアウトしました。',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        'ログアウト失敗',
        'Google アカウントのサインアウトに失敗しました。',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isSigningOut.value = false;
    }
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 42),
                    const SizedBox(height: 16),
                    Text(title, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF556070),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreScreen extends GetView<MainController> {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calendarController = Get.find<CalendarController>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune_outlined, size: 42),
                    const SizedBox(height: 16),
                    Text('その他', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Okta SSO、Google 連携、権限設定、録音ポリシーをここで管理します。',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF556070),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(
                      () => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Google 連携状態',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              calendarController.isConnected
                                  ? '接続中: Google Calendar の予定を取得できます。'
                                  : '未連携: カレンダー取得には Google 連携が必要です。',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF556070),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonalIcon(
                                onPressed: controller.reconnectCalendar,
                                icon: const Icon(Icons.link_outlined),
                                label: Text(
                                  calendarController.isConnected
                                      ? 'Google Calendar を再連携'
                                      : 'Google Calendar を連携',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(
                      () => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '通知状態',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              controller.isRefreshingNotificationStatus
                                  ? '通知状態を確認しています...'
                                  : controller.areNotificationsAllowed
                                  ? '通知許可: 有効 / 予約済みリマインダー ${controller.pendingReminderCount} 件'
                                  : '通知許可: 無効 / リマインダーを受け取るには通知を許可してください。',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF556070),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: controller.requestNotificationPermission,
                                  icon: const Icon(Icons.notifications_active_outlined),
                                  label: const Text('通知権限を確認'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: controller.refreshNotificationStatus,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('状態を更新'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => OutlinedButton.icon(
                          onPressed: controller.isSigningOut
                              ? null
                              : controller.signOutGoogle,
                          icon: controller.isSigningOut
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.logout),
                          label: Text(
                            controller.isSigningOut
                                ? 'ログアウト中...'
                                : 'Google ログアウト',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
