import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/app/routes/app_routes.dart';

class CalendarConnectIntroScreen extends StatelessWidget {
  const CalendarConnectIntroScreen({super.key});

  void _goMain() {
    Get.offAllNamed(AppRoutes.main);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7EFE6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.calendar_month_outlined, size: 32),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Google Calendar 連携について',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '最初に Google ログインを強制はしません。まずはアプリの中を見てから、必要になったタイミングで連携できます。',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF556070),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _BenefitRow(
                      title: '連携するとできること',
                      body: '今日の予定取得、次の面談表示、カレンダー画面での予定確認。',
                    ),
                    const SizedBox(height: 14),
                    const _BenefitRow(
                      title: '今はまだ行わないこと',
                      body: '名刺 OCR、通話、面談記録同期などは後から段階的に追加します。',
                    ),
                    const SizedBox(height: 14),
                    const _BenefitRow(
                      title: 'おすすめの進め方',
                      body: '今回はホームに入ってから、必要なタイミングで連携する流れにします。',
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _goMain,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('あとで連携する'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _goMain,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('ホームから連携する'),
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

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: Color(0xFF0F766E),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF556070),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
