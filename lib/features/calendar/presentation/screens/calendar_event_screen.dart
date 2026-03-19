/// 홈 화면 톤에 맞춘 Google Calendar 일정 생성/수정 화면이다.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_event_controler.dart';
import 'package:jg_business/shared/layout/app_responsive.dart';
import 'package:jg_business/shared/theme/app_tokens.dart';
import 'package:jg_business/shared/utils/date_time_picker_helper.dart';
import 'package:jg_business/shared/widgets/app_panel.dart';
import 'package:jg_business/shared/widgets/custom_text_form_field.dart';

class CalendarEventScreen extends GetView<CalendarEventControler> {
  static String name = '/calendar_event';

  const CalendarEventScreen({super.key});

  Future<void> _pickDate(BuildContext context) async {
    final picked = await DateTimePickerHelper.pickDate(
      context,
      initialDate: controller.startDt.value,
    );

    if (picked == null) return;
    controller.updateDate(picked);
  }

  Future<void> _pickAllDayDate(
    BuildContext context, {
    required bool isStartDate,
  }) async {
    final initialDate =
        isStartDate ? controller.startDt.value : controller.endDt.value;
    final picked = await DateTimePickerHelper.pickDate(
      context,
      initialDate: initialDate,
    );

    if (picked == null) return;

    if (isStartDate) {
      controller.updateAllDayStartDate(picked);
      return;
    }

    controller.updateAllDayEndDate(picked);
  }

  Future<void> _pickTime(
    BuildContext context, {
    required bool isStartTime,
  }) async {
    final current =
        isStartTime ? controller.startDt.value : controller.endDt.value;
    final picked = await DateTimePickerHelper.pickTime(
      context,
      initialTime: TimeOfDay.fromDateTime(current),
    );

    if (picked == null) return;

    if (isStartTime) {
      controller.updateStartTime(picked);
      return;
    }

    controller.updateEndTime(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = AppResponsive.isDesktopWidth(context);
    final contentWidth = isDesktop
        ? 760.0
        : AppResponsive.mediumContentMaxWidth;

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
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back<void>(),
                          icon: const Icon(Icons.arrow_back_ios_new),
                        ),
                        Expanded(
                          child: Obx(
                            () => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.isEditMode ? '予定を編集' : '予定を追加',
                                  style: theme.textTheme.titleLarge,
                                ),
                                Text(
                                  controller.isEditMode
                                      ? 'Google Calendar の予定内容を更新します。'
                                      : 'Google Calendar に新しい予定を登録します。',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroCard(controller: controller),
                          const SizedBox(height: 18),
                          _FormPanel(
                            title: '基本情報',
                            description: '予定タイトル、場所、説明を整理して入力します。',
                            child: Column(
                              children: [
                                CustomTextFormField(
                                  label: 'タイトル',
                                  hintText: 'タイトルを入力してください。',
                                  controller: controller.teCtrls.summary,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 16),
                                CustomTextFormField(
                                  label: '説明',
                                  hintText: '説明を入力してください。',
                                  controller: controller.teCtrls.description,
                                  textInputAction: TextInputAction.next,
                                  maxLines: 4,
                                  minLines: 4,
                                ),
                                const SizedBox(height: 16),
                                CustomTextFormField(
                                  label: '場所',
                                  hintText: '場所を入力してください。',
                                  controller: controller.teCtrls.location,
                                  textInputAction: TextInputAction.next,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _FormPanel(
                            title: '参加者',
                            description: '招待メールを送る参加者を追加します。',
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: CustomTextFormField(
                                        label: 'メールアドレス',
                                        hintText: '参加者のメールアドレスを入力してください。',
                                        controller:
                                            controller.teCtrls.attendeeEmail,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted:
                                            (_) => controller.addAttendee(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      onPressed: controller.addAttendee,
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 15,
                                        ),
                                      ),
                                      child: const Text('追加'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Obx(
                                  () => Align(
                                    alignment: Alignment.centerLeft,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final email in controller.attendees)
                                          InputChip(
                                            label: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: AppResponsive
                                                    .attendeeChipMaxWidth,
                                              ),
                                              child: Text(
                                                email,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            onDeleted: () => controller
                                                .removeAttendee(email),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _FormPanel(
                            title: '日時',
                            description: '開始・終了時刻と終日予定を設定します。',
                            child: Column(
                              children: [
                                Obx(
                                  () => SwitchListTile.adaptive(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text(
                                      '終日',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: const Text('時間指定なしの予定として扱います。'),
                                    value: controller.isAllDay.value,
                                    onChanged: controller.toggleAllDay,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Obx(
                                  () => controller.isAllDay.value
                                      ? Row(
                                          children: [
                                            Expanded(
                                              child: CustomTextFormField(
                                                readOnly: true,
                                                label: '開始日',
                                                hintText: '開始日を選択してください。',
                                                onTap: () => _pickAllDayDate(
                                                  context,
                                                  isStartDate: true,
                                                ),
                                                controller:
                                                    controller.teCtrls.start,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: CustomTextFormField(
                                                readOnly: true,
                                                label: '終了日',
                                                hintText: '終了日を選択してください。',
                                                onTap: () => _pickAllDayDate(
                                                  context,
                                                  isStartDate: false,
                                                ),
                                                controller:
                                                    controller.teCtrls.end,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: CustomTextFormField(
                                                readOnly: true,
                                                label: '日付',
                                                hintText: '日付を選択してください。',
                                                onTap: () => _pickDate(context),
                                                controller:
                                                    controller.teCtrls.date,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: CustomTextFormField(
                                                readOnly: true,
                                                label: '開始',
                                                hintText:
                                                    '開始時間を選択してください。',
                                                onTap: () => _pickTime(
                                                  context,
                                                  isStartTime: true,
                                                ),
                                                controller:
                                                    controller.teCtrls.start,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: CustomTextFormField(
                                                readOnly: true,
                                                label: '終了',
                                                hintText:
                                                    '終了時間を選択してください。',
                                                onTap: () => _pickTime(
                                                  context,
                                                  isStartTime: false,
                                                ),
                                                controller:
                                                    controller.teCtrls.end,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _ActionPanel(controller: controller),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.controller});

  final CalendarEventControler controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173C3A), Color(0xFF0F766E)],
        ),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller.teCtrls.summary,
        builder:
            (_, summaryValue, __) => Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.isEditMode
                        ? 'Google Calendar の予定を更新'
                        : 'Google Calendar に予定を追加',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    summaryValue.text.trim().isEmpty
                        ? 'タイトル未入力'
                        : summaryValue.text.trim(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.isAllDay.value
                        ? '${controller.teCtrls.start.text} - ${controller.teCtrls.end.text}'
                        : '${controller.teCtrls.date.text}  ${controller.teCtrls.start.text} - ${controller.teCtrls.end.text}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.84),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.title,
    required this.child,
    this.description,
  });

  final String title;
  final Widget child;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(
              description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.controller});

  final CalendarEventControler controller;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.isSaving.value ? null : controller.submit,
                icon: controller.isSaving.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        controller.isEditMode
                            ? Icons.save_outlined
                            : Icons.add_circle_outline,
                      ),
                label: Text(
                  controller.isSaving.value
                      ? '保存中...'
                      : controller.isEditMode
                      ? '予定を保存'
                      : '予定を追加',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          Obx(() {
            if (!controller.isEditMode) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      controller.isSaving.value ? null : controller.deleteEvent,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('この予定を削除'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
