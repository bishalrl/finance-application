import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/router.dart';
import '../../../../core/config/dependency_injection.dart' as di;
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';
import '../bloc/home_event.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/recent_item.dart';
import '../../../08_reminders/domain/entities/reminder.dart';
import '../../../05_documents/presentation/bloc/document_bloc.dart';
import '../../../05_documents/presentation/bloc/document_event.dart';
import '../../../05_documents/presentation/pages/documents_list_page.dart';
import '../../../06_notes/presentation/bloc/note_bloc.dart';
import '../../../06_notes/presentation/bloc/note_event.dart';
import '../../../06_notes/presentation/pages/notes_list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const _DashboardTab(),
      const _DocumentsTab(),
      const _NotesTab(),
      const _MoreTab(),
    ];

    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (previous, current) => previous.selectedIndex != current.selectedIndex,
      builder: (context, state) {
        return Scaffold(
          body: pages[state.selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.selectedIndex,
            onDestinationSelected: (index) {
              context.read<HomeBloc>().add(ChangeTab(index));
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: 'Documents',
              ),
              NavigationDestination(
                icon: Icon(Icons.note_outlined),
                selectedIcon: Icon(Icons.note),
                label: 'Notes',
              ),
              NavigationDestination(
                icon: Icon(Icons.more_horiz),
                selectedIcon: Icon(Icons.more_horiz),
                label: 'More',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (prev, curr) => prev.status != curr.status || prev.stats != curr.stats,
      builder: (context, state) {
        if (state.status == HomeStatus.loading && state.stats == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == HomeStatus.error && state.stats == null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.06),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.errorMessage ?? 'Something went wrong', textAlign: TextAlign.center, style: TextStyle(fontSize: screenWidth * 0.04)),
                    SizedBox(height: screenHeight * 0.02),
                    TextButton(
                      onPressed: () => context.read<HomeBloc>().add(const LoadDashboard()),
                      child: Text('Retry', style: TextStyle(fontSize: screenWidth * 0.04)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final stats = state.stats ?? const DashboardStats();
        return RefreshIndicator(
          onRefresh: () async {
            context.read<HomeBloc>().add(const RefreshDashboard());
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: screenHeight * 0.15,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Life Vault',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: screenWidth * 0.05,
                        ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.search, size: screenWidth * 0.06),
                    onPressed: () => Navigator.of(context).pushNamed(AppRouter.search),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, size: screenWidth * 0.06),
                    onPressed: () => Navigator.of(context).pushNamed(AppRouter.settings),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.description,
                              title: 'Documents',
                              value: '${stats.documentCount}',
                              color: const Color(0xFF6366F1),
                              onTap: () => Navigator.of(context).pushNamed(AppRouter.documents),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.note,
                              title: 'Notes',
                              value: '${stats.noteCount}',
                              color: const Color(0xFF8B5CF6),
                              onTap: () => Navigator.of(context).pushNamed(AppRouter.notes),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.lightbulb_outline,
                              title: 'Ideas',
                              value: '${stats.ideaCount}',
                              color: const Color(0xFFF59E0B),
                              onTap: () => Navigator.of(context).pushNamed(AppRouter.ideas),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.notifications_outlined,
                              title: 'Reminders',
                              value: '${stats.reminderCount}',
                              color: const Color(0xFF10B981),
                              onTap: () => Navigator.of(context).pushNamed(AppRouter.reminders),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.05),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Wrap(
                        spacing: screenWidth * 0.03,
                        runSpacing: screenHeight * 0.015,
                        children: [
                          _QuickActionButton(
                            icon: Icons.description,
                            label: 'Add Document',
                            color: const Color(0xFF6366F1),
                            onTap: () => Navigator.of(context).pushNamed(AppRouter.addDocument),
                          ),
                          _QuickActionButton(
                            icon: Icons.edit_note,
                            label: 'New Note',
                            color: const Color(0xFF8B5CF6),
                            onTap: () => Navigator.of(context).pushNamed(AppRouter.noteEditor),
                          ),
                          _QuickActionButton(
                            icon: Icons.lightbulb,
                            label: 'New Idea',
                            color: const Color(0xFFF59E0B),
                            onTap: () => Navigator.of(context).pushNamed(AppRouter.ideas),
                          ),
                          _QuickActionButton(
                            icon: Icons.alarm_add,
                            label: 'Set Reminder',
                            color: const Color(0xFF10B981),
                            onTap: () => Navigator.of(context).pushNamed(AppRouter.addReminder),
                          ),
                          _QuickActionButton(
                            icon: Icons.account_balance_wallet,
                            label: 'Finance',
                            color: const Color(0xFF06B6D4),
                            onTap: () => Navigator.of(context).pushNamed(AppRouter.finance),
                          ),
                          _QuickActionButton(
                            icon: Icons.lock_person,
                            label: 'Vault',
                            color: const Color(0xFFEF4444),
                            onTap: () => Navigator.of(context).pushNamed(AppRouter.vault),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      Text(
                        'Recent Items',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.05),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      if (state.recentItems.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.08),
                            child: Text('No recent items', style: TextStyle(fontSize: screenWidth * 0.04)),
                          ),
                        )
                      else
                        ...state.recentItems.map((item) => _RecentItemTile(item: item)),
                      if (state.upcomingReminders.isNotEmpty) ...[
                        SizedBox(height: screenHeight * 0.03),
                        Text(
                          'Upcoming Reminders',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.05),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        ...state.upcomingReminders.take(5).map((r) => _UpcomingReminderTile(reminder: r)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentItemTile extends StatelessWidget {
  final RecentItem item;

  const _RecentItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    IconData icon;
    switch (item.type) {
      case RecentItemType.document:
        icon = Icons.description;
        break;
      case RecentItemType.note:
        icon = Icons.note;
        break;
      case RecentItemType.idea:
        icon = Icons.lightbulb_outline;
        break;
    }
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        radius: screenWidth * 0.05,
        child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer, size: screenWidth * 0.06),
      ),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: screenWidth * 0.04)),
      subtitle: item.subtitle != null ? Text(item.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: screenWidth * 0.035)) : null,
      trailing: Icon(Icons.chevron_right, size: screenWidth * 0.05),
      onTap: () {
        if (item.type == RecentItemType.document) {
          Navigator.of(context).pushNamed(AppRouter.documents);
        } else if (item.type == RecentItemType.note) {
          Navigator.of(context).pushNamed(AppRouter.notes);
        } else {
          Navigator.of(context).pushNamed(AppRouter.ideas);
        }
      },
    );
  }
}

class _UpcomingReminderTile extends StatelessWidget {
  final Reminder reminder;

  const _UpcomingReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
        radius: screenWidth * 0.05,
        child: Icon(Icons.notifications_outlined, color: const Color(0xFF10B981), size: screenWidth * 0.06),
      ),
      title: Text(reminder.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: screenWidth * 0.04)),
      subtitle: Text(
        _formatDate(reminder.reminderDate),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenWidth * 0.035),
      ),
      trailing: Icon(Icons.chevron_right, size: screenWidth * 0.05),
      onTap: () => Navigator.of(context).pushNamed(AppRouter.reminders),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dDate = DateTime(d.year, d.month, d.day);
    if (dDate == today) return 'Today ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (dDate == tomorrow) return 'Tomorrow ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Icon(icon, color: color, size: screenWidth * 0.06),
              ),
              SizedBox(height: screenHeight * 0.015),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: screenWidth * 0.06,
                    ),
              ),
              SizedBox(height: screenHeight * 0.005),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenWidth * 0.035),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      width: (screenWidth - (screenWidth * 0.04 * 2) - (screenWidth * 0.03 * 2)) / 3, // screenWidth - (padding * 2) - (spacing * 2) / 3
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: Icon(icon, color: color, size: screenWidth * 0.07),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth * 0.035,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<DocumentBloc>()..add(const LoadDocuments()),
      child: const DocumentsListPage(),
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<NoteBloc>()..add(const LoadNotes()),
      child: const NotesListPage(),
    );
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text('More', style: TextStyle(fontSize: screenWidth * 0.05)),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.schedule_outlined, size: screenWidth * 0.06),
            title: Text('Planner', style: TextStyle(fontSize: screenWidth * 0.04)),
            trailing: Icon(Icons.chevron_right, size: screenWidth * 0.05),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.planner);
            },
          ),
          ListTile(
            leading: Icon(Icons.folder_special_outlined, size: screenWidth * 0.06),
            title: Text('Projects', style: TextStyle(fontSize: screenWidth * 0.04)),
            trailing: Icon(Icons.chevron_right, size: screenWidth * 0.05),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.projects);
            },
          ),
          ListTile(
            leading: Icon(Icons.lightbulb_outline, size: screenWidth * 0.06),
            title: Text('Ideas', style: TextStyle(fontSize: screenWidth * 0.04)),
            trailing: Icon(Icons.chevron_right, size: screenWidth * 0.05),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.ideas);
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications_outlined, size: screenWidth * 0.06),
            title: Text('Reminders', style: TextStyle(fontSize: screenWidth * 0.04)),
            trailing: Icon(Icons.chevron_right, size: screenWidth * 0.05),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.reminders);
            },
          ),
          ListTile(
            leading: Icon(Icons.account_balance_wallet, size: screenWidth * 0.06),
            title: Text('Finance', style: TextStyle(fontSize: screenWidth * 0.04)),
            trailing: Icon(Icons.chevron_right, size: screenWidth * 0.05),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.finance);
            },
          ),
          ListTile(
            leading: Icon(Icons.lock_person, size: screenWidth * 0.06),
            title: Text('Vault', style: TextStyle(fontSize: screenWidth * 0.04)),
            trailing: Icon(Icons.chevron_right, size: screenWidth * 0.05),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.vault);
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.search, size: screenWidth * 0.06),
            title: Text('Search', style: TextStyle(fontSize: screenWidth * 0.04)),
            trailing: Icon(Icons.chevron_right, size: screenWidth * 0.05),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.search);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings_outlined, size: screenWidth * 0.06),
            title: Text('Settings', style: TextStyle(fontSize: screenWidth * 0.04)),
            trailing: Icon(Icons.chevron_right, size: screenWidth * 0.05),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.settings);
            },
          ),
          ListTile(
            leading: Icon(Icons.workspace_premium, size: screenWidth * 0.06),
            title: Text('Subscription', style: TextStyle(fontSize: screenWidth * 0.04)),
            trailing: Icon(Icons.chevron_right, size: screenWidth * 0.05),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.subscription);
            },
          ),
        ],
      ),
    );
  }
}

