/// 고객 목록과 기본 상세 정보를 보여주는 화면이다.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/app/routes/app_routes.dart';
import 'package:intl/intl.dart';
import 'package:jg_business/features/client/presentation/controllers/client_controller.dart';
import 'package:jg_business/shared/theme/app_tokens.dart';
import 'package:jg_business/shared/widgets/app_panel.dart';

class ClientScreen extends GetView<ClientController> {
  const ClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: isWide
                ? Row(
                    children: [
                      SizedBox(width: 360, child: _ClientListPane()),
                      const SizedBox(width: 20),
                      const Expanded(child: _ClientDetailPane()),
                    ],
                  )
                : Column(
                    children: [
                      const _ClientListHeader(),
                      const SizedBox(height: 16),
                      const Expanded(child: _ClientListPane()),
                      const SizedBox(height: 16),
                      const Expanded(child: _ClientDetailPane()),
                    ],
                  ),
          );
        }),
      ),
    );
  }
}

class _ClientListHeader extends GetView<ClientController> {
  const _ClientListHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('顧客', style: theme.textTheme.headlineSmall)),
            FilledButton.tonalIcon(
              onPressed: () => Get.toNamed(AppRoutes.businessCard),
              icon: const Icon(Icons.badge_outlined),
              label: const Text('名刺登録'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.searchCtrl,
          decoration: const InputDecoration(
            hintText: '会社名または担当者名で検索',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ],
    );
  }
}

class _ClientListPane extends GetView<ClientController> {
  const _ClientListPane();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = controller.filteredClients;

    return AppPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (MediaQuery.sizeOf(context).width >= 900) const _ClientListHeader(),
          if (MediaQuery.sizeOf(context).width >= 900) const SizedBox(height: 16),
          Text(
            '登録済み顧客 ${items.length}件',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'まだ登録された顧客がありません。\n面談記録または名刺登録から顧客が作成されます。',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final client = items[index];
                  final selected = controller.selectedClientId == client.id;
                  return InkWell(
                    onTap: () => controller.selectClient(client.id),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accentSoft : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(client.companyName, style: theme.textTheme.titleMedium),
                          if (client.contactName?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: 6),
                            Text(
                              client.contactName!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            '連携面談 ${client.linkedGoogleEventIds.length}件',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ClientDetailPane extends GetView<ClientController> {
  const _ClientDetailPane();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = controller.selectedClient;

    return AppPanel(
      padding: const EdgeInsets.all(24),
      child: client == null
          ? Center(
              child: Text(
                '顧客を選択してください。',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.companyName, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 12),
                _DetailRow(label: '担当者', value: client.contactName ?? '未設定'),
                _DetailRow(label: '電話番号', value: client.phoneNumber ?? '未設定'),
                _DetailRow(label: 'メール', value: client.email ?? '未設定'),
                _DetailRow(
                  label: '最終面談',
                  value: client.lastMeetingAt == null
                      ? '未設定'
                      : DateFormat('yyyy/MM/dd HH:mm').format(client.lastMeetingAt!),
                ),
                _DetailRow(
                  label: '連携面談数',
                  value: '${client.linkedGoogleEventIds.length}件',
                ),
                const SizedBox(height: 20),
                Text('メモ', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  client.notes?.trim().isNotEmpty == true
                      ? client.notes!
                      : '名刺 OCR, 통화 요약, 후속 메모는 다음 단계에서 여기에 연결됩니다.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
