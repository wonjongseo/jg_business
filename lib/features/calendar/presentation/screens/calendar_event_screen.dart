import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_event_controler.dart';
import 'package:jg_business/shared/utils/date_time_picker_helper.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditMode ? '予定を編集' : '予定を追加')),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isSaving.value ? null : controller.submit,
              child: Text(
                controller.isEditMode ? '保存' : '追加',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        label: 'タイトル',
                        hintText: 'タイトルを入力してください。',
                        controller: controller.teCtrls.summary,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        label: '説明',
                        hintText: '説明を入力してください。',
                        controller: controller.teCtrls.description,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        label: '場所',
                        hintText: '場所を入力してください。',
                        controller: controller.teCtrls.location,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: CustomTextFormField(
                              label: '参加者',
                              hintText: 'メールアドレスを入力してください。',
                              controller: controller.teCtrls.attendeeEmail,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => controller.addAttendee(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: controller.addAttendee,
                            child: const Text('追加'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                                      maxWidth: 220,
                                    ),
                                    child: Text(
                                      email,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  onDeleted: () =>
                                      controller.removeAttendee(email),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Obx(
                        () => controller.isAllDay.value
                            ? Row(
                                children: [
                                  Expanded(
                                    child: CustomTextFormField(
                                      readOnly: true,
                                      label: '開始日',
                                      hintText: '開始日を入力してください。',
                                      onTap: () => _pickAllDayDate(
                                        context,
                                        isStartDate: true,
                                      ),
                                      controller: controller.teCtrls.start,
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomTextFormField(
                                      readOnly: true,
                                      label: '終了日',
                                      hintText: '終了日を入力してください。',
                                      onTap: () => _pickAllDayDate(
                                        context,
                                        isStartDate: false,
                                      ),
                                      controller: controller.teCtrls.end,
                                      textInputAction: TextInputAction.next,
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
                                      hintText: '日付を入力してください。',
                                      onTap: () => _pickDate(context),
                                      controller: controller.teCtrls.date,
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomTextFormField(
                                      readOnly: true,
                                      label: '開始',
                                      hintText: '開始時間を入力してください。',
                                      onTap: () => _pickTime(
                                        context,
                                        isStartTime: true,
                                      ),
                                      controller: controller.teCtrls.start,
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomTextFormField(
                                      readOnly: true,
                                      label: '終了',
                                      hintText: '終了時間を入力してください。',
                                      onTap: () => _pickTime(
                                        context,
                                        isStartTime: false,
                                      ),
                                      controller: controller.teCtrls.end,
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            '終日',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          value: controller.isAllDay.value,
                          onChanged: controller.toggleAllDay,
                        ),
                      ),
                      const Spacer(),
                      Obx(() {
                        if (!controller.isEditMode) {
                          return const SizedBox.shrink();
                        }
                        return SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: controller.isSaving.value
                                ? null
                                : controller.deleteEvent,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                            ),
                            child: const Text('予定を削除'),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
