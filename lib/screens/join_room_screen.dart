import 'package:flutter/material.dart';

import '../services/multiplayer_service.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/primary_pill_button.dart';
import 'room_flow_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({
    super.key,
    this.initialRoomCode,
  });

  final String? initialRoomCode;

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  late final TextEditingController _codeController;
  final _playerNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialRoomCode ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim();
    final playerName = _playerNameController.text.trim();

    if (code.length < 4 || playerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى إدخال كود الغرفة واسم اللاعب',
            textAlign: TextAlign.right,
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await MultiplayerService.instance.joinRoom(
        code: code,
        playerName: playerName,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const RoomFlowScreen()),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final openedFromLink = widget.initialRoomCode != null;

    return Scaffold(
      appBar: AppBar(title: const Text('انضمام لغرفة')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (openedFromLink)
                Card(
                  color: const Color(0xFFE8F1FB),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'تم فتح رابط الغرفة ${widget.initialRoomCode}. أدخل اسمك ثم اضغط انضمام.',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              if (openedFromLink) const SizedBox(height: 16),
              LabeledTextField(
                label: 'كود الغرفة',
                controller: _codeController,
                hintText: 'مثال: 2646',
              ),
              const SizedBox(height: 20),
              LabeledTextField(
                label: 'اسم اللاعب',
                controller: _playerNameController,
                hintText: 'أدخل اسمك',
                textInputAction: TextInputAction.done,
              ),
              const Spacer(),
              PrimaryPillButton(
                label: _isLoading ? 'جاري الانضمام...' : 'انضمام',
                enabled: !_isLoading,
                onPressed: _joinRoom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
