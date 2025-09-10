import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';

class MissionCard extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String points;
  final Color cardColor;
  final Color iconAndTextColor;
  final Color buttonBgColor;
  final Color iconBgColor;
  final Color iconBorderColor;
  final Color pointsBorderColor;
  final Color pointsTextColor;
  final Color titleColor;

  const MissionCard({
    super.key,
    required this.iconData,
    required this.title,
    required this.points,
    required this.cardColor,
    this.iconAndTextColor = AppColors.white,
    this.buttonBgColor = AppColors.white,
    required this.iconBgColor,
    required this.iconBorderColor,
    required this.pointsBorderColor,
    required this.pointsTextColor,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconBorderColor, width: 2),
            ),
            child: Icon(iconData, color: iconAndTextColor, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: pointsBorderColor, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: pointsTextColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        points,
                        style: TextStyle(
                          color: pointsTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: iconBgColor,
              foregroundColor: iconAndTextColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: iconBorderColor, width: 2),
              elevation: 3,
            ),
            child: const Text(
              'Mulai',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
