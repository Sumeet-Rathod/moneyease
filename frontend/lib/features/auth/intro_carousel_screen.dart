import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../core/widgets/custom_button.dart';

class IntroCarouselScreen extends StatefulWidget {
  const IntroCarouselScreen({super.key});

  @override
  State<IntroCarouselScreen> createState() => _IntroCarouselScreenState();
}

class _IntroCarouselScreenState extends State<IntroCarouselScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      "icon": Icons.lightbulb_outline_rounded,
      "title": "Understand Your Money",
      "subtitle": "Clear, friendly answers to all your mutual fund and investment doubts without confusing financial jargon.",
      "color": const Color(0xFF028090),
    },
    {
      "icon": Icons.track_changes_rounded,
      "title": "Plan Your Financial Goals",
      "subtitle": "Visualize your future with inflation-adjusted projections for buying a bike, higher education, or early retirement.",
      "color": const Color(0xFF00A896),
    },
    {
      "icon": Icons.support_agent_rounded,
      "title": "Talk to a Certified Expert",
      "subtitle": "Your detailed profile is analyzed by an AMFI-registered advisor who reaches out to design your personal blueprint.",
      "color": const Color(0xFF0F4C81),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentIndex < _slides.length - 1)
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text(
                "Skip",
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: (slide["color"] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide["icon"] as IconData,
                            size: 64,
                            color: slide["color"] as Color,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          slide["title"] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          slide["subtitle"] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? AppTheme.primaryTeal
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              if (_currentIndex == _slides.length - 1)
                CustomButton(
                  text: "Get Started",
                  onPressed: () => context.go('/login'),
                )
              else
                CustomButton(
                  text: "Continue",
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
