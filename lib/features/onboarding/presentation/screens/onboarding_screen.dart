import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/app/routes/app_routes.dart';
import 'package:jg_business/shared/services/app_launch_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final RxInt _pageIndex = 0.obs;

  final _pages = const [
    (
      title: '営業の今日をすぐ見える化',
      description: 'Google Calendar の予定をもとに、今日の動きを整理して確認できます。',
      icon: Icons.calendar_month_outlined,
    ),
    (
      title: '予定を営業アクションにつなげる',
      description: '面談詳細、移動、記録、次の対応までを一つの流れで扱える設計にしていきます。',
      icon: Icons.timeline_outlined,
    ),
    (
      title: 'まずはカレンダー連携から始める',
      description: '初回は Google Calendar 連携だけに絞り、必要な機能から段階的に広げます。',
      icon: Icons.link_outlined,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _pageIndex.close();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (_pageIndex.value == _pages.length - 1) {
      await Get.find<AppLaunchService>().completeOnboarding();
      if (!mounted) return;
      Get.offAllNamed(AppRoutes.calendarConnectIntro);
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  Future<void> _skip() async {
    await Get.find<AppLaunchService>().completeOnboarding();
    if (!mounted) return;
    Get.offAllNamed(AppRoutes.calendarConnectIntro);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4E7C9), Color(0xFFF8F5EE), Color(0xFFD9ECE5)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _skip,
                    child: const Text('スキップ'),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => _pageIndex.value = index,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.88),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD7EFE6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(page.icon, size: 32),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  page.title,
                                  style: theme.textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  page.description,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: const Color(0xFF556070),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < _pages.length; index++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: _pageIndex.value == index ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: _pageIndex.value == index
                                ? const Color(0xFF0F766E)
                                : const Color(0xFFD0D5DD),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: Obx(
                    () => FilledButton(
                      onPressed: _goNext,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _pageIndex.value == _pages.length - 1 ? 'はじめる' : '次へ',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
