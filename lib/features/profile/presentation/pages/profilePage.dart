import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellmate/core/providers/journeyProvider.dart';

import '../../../../core/enums/journeys.dart';
import '../../../../core/localization/localeProvider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/provider/authProvider.dart';
import '../../../shell/presentation/navigationProvider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
        );
      }

      ref.read(scrollProfileToBottomProvider.notifier).state = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      scrollProfileToBottomProvider,
          (previous, next) {
        if (next == true) {
          _scrollToBottom();
        }
      },
    );

    final loc = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final selectedJourney = context.watch<JourneyProvider>().selectedJourney;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              const CircleAvatar(
                radius: 45,
                backgroundColor: AppColors.selectedCard,
                child: Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Profile",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Customize your language and journey",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.appGray,
                ),
              ),

              const SizedBox(height: 30),

              _SectionCard(
                title: "Language",
                icon: Icons.language_rounded,
                children: [
                  _OptionTile(
                    title: "English",
                    subtitle: "Use the app in English",
                    icon: Icons.translate_rounded,
                    onTap: () {
                      context.read<LocaleProvider>().changeLocale('en');
                    },
                  ),
                  _OptionTile(
                    title: "Dari",
                    subtitle: "استفاده از برنامه به زبان دری",
                    icon: Icons.translate_rounded,
                    onTap: () {
                      context.read<LocaleProvider>().changeLocale('fa');
                    },
                  ),
                  _OptionTile(
                    title: "Pashto",
                    subtitle: "اپلیکیشن په پښتو ژبه وکاروئ",
                    icon: Icons.translate_rounded,
                    onTap: () {
                      context.read<LocaleProvider>().changeLocale('ps');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _SectionCard(
                title: "Choose Journey",
                icon: Icons.route_rounded,
                children: [
                  _JourneyTile(
                    title: "Carpet Journey",
                    emoji: "🧵",
                    isSelected: selectedJourney == Journeys.carpet,
                    onTap: () => _changeJourney(Journeys.carpet),
                  ),
                  _JourneyTile(
                    title: "Minarets Journey",
                    emoji: "🕌",
                    isSelected: selectedJourney == Journeys.minarets,
                    onTap: () => _changeJourney(Journeys.minarets),
                  ),
                  // _JourneyTile(
                  //   title: "Women Dress",
                  //   emoji: "👗",
                  //   isSelected: selectedJourney == Journeys.womenDress,
                  //   onTap: () => _changeJourney(Journeys.womenDress),
                  // ),
                  // _JourneyTile(
                  //   title: "Ghara",
                  //   emoji: "🥻",
                  //   isSelected: selectedJourney == Journeys.menDress,
                  //   onTap: () => _changeJourney(Journeys.menDress),
                  // ),
                  // _JourneyTile(
                  //   title: "Pomegranate",
                  //   emoji: "🌳",
                  //   isSelected: selectedJourney == Journeys.pomegranateTree,
                  //   onTap: () => _changeJourney(Journeys.pomegranateTree),
                  // ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/journeys');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add Journey"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.selectedCard,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              if (authProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  onPressed: () {
                    authProvider.logout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeJourney(Journeys journey) {
    context.read<JourneyProvider>().changeJourney(journey);
    ref.read(navigationIndexProvider.notifier).state = 0;
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.appGray.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.selectedCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.appGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.appGray,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyTile extends StatelessWidget {
  final String title;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _JourneyTile({
    required this.title,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.selectedCard
              : AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.textPrimary.withOpacity(0.35)
                : AppColors.appGray.withOpacity(0.12),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.textPrimary,
                  )
                else
                  const Icon(
                    Icons.circle_outlined,
                    color: AppColors.appGray,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}