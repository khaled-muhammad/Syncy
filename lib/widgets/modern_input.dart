import 'dart:ui';

import 'package:flutter/material.dart';

class ModernInput extends StatefulWidget {
  final TextEditingController controller;
  final void Function()? onCancelPressed;
  final void Function(String)? onChanged;
  final String? hintText;
  final IconData icon;

  const ModernInput({super.key, required this.controller, this.onCancelPressed, this.onChanged, this.hintText, required this.icon});

  @override
  State<ModernInput> createState() => _ModernInputState();
}

class _ModernInputState extends State<ModernInput> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.purpleAccent.withValues(
                alpha: 0.3,
              ),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.purpleAccent,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.6,
                ),
              ),
              border: InputBorder.none,
              icon: Icon(
                widget.icon,
                color: Colors.white70,
              ),
              suffixIcon:
                  widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          widget.controller.clear();
                          if (widget.onCancelPressed != null) {
                            widget.onCancelPressed!();
                          }
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (newText) {
              setState(() {
                if (widget.onChanged != null) {
                  widget.onChanged!(newText);
                }
              });
            },
          ),
        ),
      ),
    );
  }
}