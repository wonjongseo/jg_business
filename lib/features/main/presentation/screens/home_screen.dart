import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/features/main/presentation/screens/widgets/home_hero_summary_card.dart';
import 'package:jg_business/features/main/presentation/screens/widgets/home_next_meeting_card.dart';
import 'package:jg_business/features/main/presentation/screens/widgets/home_section_header.dart';
import 'package:jg_business/shared/theme/app_tokens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const HomeHeroSummaryCard(),
                    const SizedBox(height: 18),
                    const _MeetingSectionHeader(),
                    const SizedBox(height: 10),
                    const HomeNextMeetingCard(),
                    const SizedBox(height: 28),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingSectionHeader extends StatelessWidget {
  const _MeetingSectionHeader();

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CalendarController>()
        ? Get.find<CalendarController>()
        : null;

    if (controller == null) {
      return const HomeSectionHeader(
        title: '次の面談',
        actionLabel: 'カレンダーを開く',
      );
    }

    return Obx(() {
      final event = controller.currentOrNextEvent;
      final title = event != null && controller.isOngoing(event)
          ? '進行中の面談'
          : '次の面談';

      return HomeSectionHeader(
        title: title,
        actionLabel: 'カレンダーを開く',
      );
    });
  }
}
