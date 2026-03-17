import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/main/presentation/controllers/main_controller.dart';

class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: controller.selectedIndex,
            children: controller.bodies,
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: controller.selectedIndex,
          onDestinationSelected: controller.onDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Calendar',
            ),
            NavigationDestination(
              icon: Icon(Icons.meeting_room),
              label: 'Meet',
            ),
            NavigationDestination(
              icon: Icon(Icons.contact_page),
              label: 'Contact',
            ),
            NavigationDestination(icon: Icon(Icons.settings), label: 'Setting'),
          ],
        ),
      ),
    );
  }
}
