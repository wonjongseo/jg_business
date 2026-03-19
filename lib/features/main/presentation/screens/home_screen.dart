/// 오늘의 영업 흐름을 요약해서 보여주는 홈 화면이다.
import 'package:flutter/material.dart';
import 'package:jg_business/features/main/presentation/screens/widgets/home_hero_summary_card.dart';
import 'package:jg_business/features/main/presentation/screens/widgets/home_next_meeting_card.dart';
import 'package:jg_business/features/main/presentation/screens/widgets/home_pending_records_card.dart';
import 'package:jg_business/features/main/presentation/screens/widgets/home_recent_records_card.dart';
import 'package:jg_business/features/main/presentation/screens/widgets/home_section_header.dart';

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
                    const HomeSectionHeader(title: '次の面談'),
                    const SizedBox(height: 10),
                    const HomeNextMeetingCard(),
                    const SizedBox(height: 28),
                    const HomeSectionHeader(title: '記録待ち'),
                    const SizedBox(height: 10),
                    const HomePendingRecordsCard(),
                    const SizedBox(height: 28),
                    const HomeSectionHeader(title: '最近の記録'),
                    const SizedBox(height: 10),
                    const HomeRecentRecordsCard(),
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
