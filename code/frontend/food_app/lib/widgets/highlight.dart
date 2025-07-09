import 'package:flutter/material.dart';

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material( 
      child: InkWell(
        onTap: onTap,
        // Splash effect
        highlightColor: Theme.of(
          context,
        ).primaryColor.withOpacity(0.1), // Highlight effect when touched
        borderRadius: BorderRadius.circular(
          10,
        ), // Optional: adds rounded corners to the touch effect
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ListTile(
            leading: Icon(
              icon,
              color:
                  isSelected ? Theme.of(context).primaryColor : Colors.black87,
              size: 24,
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color:
                    isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            minLeadingWidth: 24,
          ),
        ),
      ),
    );
  }
}
