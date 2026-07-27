import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';
import '../providers/navigation_provider.dart';
import '../widgets/add_transaction_bottom_sheet.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key});

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const AnalyticsScreen(),
    const NotesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddTransactionBottomSheet(),
            );
          },
          shape: const CircleBorder(),
          elevation: 3,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outline, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            ref.read(navigationIndexProvider.notifier).state = index;
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_rounded),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_note_rounded),
              selectedIcon: Icon(Icons.edit_note_rounded),
              label: 'Notes',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
