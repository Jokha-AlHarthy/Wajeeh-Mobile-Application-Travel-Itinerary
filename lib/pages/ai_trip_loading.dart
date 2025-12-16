import 'dart:ui';
import 'package:flutter/material.dart';
import 'ai_trip_overview_list.dart';

class TripLoadingDialog extends StatefulWidget {
  const TripLoadingDialog({super.key});
  @override
  State<TripLoadingDialog> createState() => _TripLoadingDialogState();
}
class _TripLoadingDialogState extends State<TripLoadingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TripOverviewScreen()),
        );
      }
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Center(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset("images/traveler.png", height: 140),
                const SizedBox(height: 10),
                const Text(
                  "Currently making\ntravel plans",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1A2B49),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Wait a moment and we will\nprovide the best plan for you",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xff1A2B49)),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _controller.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xff1A2B49),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
