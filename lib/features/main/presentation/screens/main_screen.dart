import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/main/presentation/controllers/main_controller.dart';
import 'package:jg_business/shared/layout/app_responsive.dart';

class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final useRailNavigation = AppResponsive.useRailNavigation(context);

    return Obx(
      () => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F1DE), Color(0xFFF5F2EA)],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Row(
              children: [
                if (useRailNavigation)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: NavigationRail(
                        selectedIndex: controller.selectedIndex,
                        onDestinationSelected: controller.onDestinationSelected,
                        labelType: NavigationRailLabelType.all,
                        groupAlignment: -0.8,
                        leading: Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 24),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF173C3A),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'JG',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        destinations: [
                          for (final destination in controller.destinations)
                            NavigationRailDestination(
                              icon: Icon(destination.icon),
                              selectedIcon: Icon(destination.selectedIcon),
                              label: Text(destination.label),
                            ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: IndexedStack(
                    index: controller.selectedIndex,
                    children: controller.bodies,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar:
              useRailNavigation
                  ? null
                  : NavigationBar(
                    selectedIndex: controller.selectedIndex,
                    onDestinationSelected: controller.onDestinationSelected,
                    destinations: [
                      for (final destination in controller.destinations)
                        NavigationDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: destination.label,
                        ),
                    ],
                  ),
        ),
      ),
    );
  }
}
