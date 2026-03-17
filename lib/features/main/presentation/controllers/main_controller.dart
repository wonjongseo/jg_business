import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/calendar/presentation/screens/calendar_screen.dart';

class MainController extends GetxController {
  final bodies = <Widget>[
    const CalendarScreen(),
    const Center(child: Text('Meet')),
    const Center(child: Text('Contact')),
    const Center(child: Text('data')),
  ];

  final _selectedIndex = 0.obs;

  int get selectedIndex => _selectedIndex.value;

  void onDestinationSelected(int value) {
    _selectedIndex.value = value;
  }
}
