import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:realm/realm.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/models/user.dart';
import 'package:syncy/widgets/modern_input.dart';

class CreateRoomBottomSheet extends StatefulWidget {
  final Media media;

  const CreateRoomBottomSheet({
    super.key,
    required this.media,
  });

  @override
  State<CreateRoomBottomSheet> createState() => _CreateRoomBottomSheetState();
}

class _CreateRoomBottomSheetState extends State<CreateRoomBottomSheet> {
  final _nameController     = TextEditingController();
  final _roomNameController = TextEditingController();
  final realm = Get.find<Realm>();
  late User user;
  @override
  void initState() {
    super.initState();
    
    final res = realm.all<User>();
    if (res.isNotEmpty) {
      user = res.first;
    } else {
      user = realm.write(() {
        return realm.add<User>(User(ObjectId(), ''));
      });
    }

    _nameController.text = user.name;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.purple.withAlpha(100),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(26),
              topRight: Radius.circular(26),
            )
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Create Room", style: Get.textTheme.headlineSmall,),
                const SizedBox(height: 20),
                ModernInput(
                  controller: _nameController,
                  icon: Icons.person_2_rounded,
                  hintText: "Enter your name",
                  onChanged: (newUserName) {
                    realm.write(() {
                      user.name = newUserName;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ModernInput(
                  controller: _roomNameController,
                  icon: Icons.door_front_door_rounded,
                  hintText: "Enter room name here",
                  onChanged: (newRoomName) {
                    setState(() {
                      
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _roomNameController.text.trim().isEmpty
                      ? null
                      : () {
                          Get.find<RoomController>().createRoom(
                              _roomNameController.text.trim(), mediaItem: widget.media);
                        },
                  icon: const Icon(Icons.start_rounded, color: Colors.white),
                  label: const Text(
                    "Create",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white38,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    backgroundColor: Colors.purpleAccent.withValues(alpha: 0.3),
                    shadowColor: Colors.purpleAccent.withValues(alpha: 0.5),
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) {
                        if (states.contains(WidgetState.pressed)) {
                          return Colors.deepPurpleAccent.withValues(alpha: 0.2);
                        }
                        return null;
                      },
                    ),
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