/// 홈 섹션 제목과 우측 액션 라벨을 그리는 공용 헤더다.
import 'package:flutter/material.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.actionLabel,
  });

  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
        TextButton(onPressed: () {}, child: Text(actionLabel)),
      ],
    );
  }
}
