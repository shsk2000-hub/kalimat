import 'package:flutter/material.dart';

import '../models/game_settings.dart';
import '../services/multiplayer_service.dart';
import '../widgets/labeled_dropdown.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/selected_game_card.dart';
import 'join_room_screen.dart';
import 'lobby_screen.dart';
import 'room_flow_screen.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final _playerNameController = TextEditingController();
  final _roundTitleController = TextEditingController();

  static const _durationOptions = [15, 30, 45, 60];
  static const _roundCountOptions = [1, 3, 5, 10];

  int _selectedDuration = 30;
  int _selectedRoundCount = 3;
  bool _isLoading = false;

  @override
  void dispose() {
    _playerNameController.dispose();
    _roundTitleController.dispose();
    super.dispose();
  }

  String _durationLabel(int seconds) => '$seconds ثانية';

  String _roundCountLabel(int count) => '$count';

  GameSettings? _buildSettings(String playerName) {
    final roundTitle = _roundTitleController.text.trim();
    if (playerName.isEmpty || roundTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى إدخال اسم اللاعب وعنوان الجولة',
            textAlign: TextAlign.right,
          ),
        ),
      );
      return null;
    }

    return GameSettings(
      playerName: playerName,
      roundTitle: roundTitle,
      roundDurationSeconds: _selectedDuration,
      numberOfRounds: _selectedRoundCount,
    );
  }

  Future<void> _createRoom() async {
    final playerName = _playerNameController.text.trim();
    final settings = _buildSettings(playerName);
    if (settings == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await MultiplayerService.instance.createRoom(
        settings: settings,
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

  void _startSoloGame() {
    final playerName = _playerNameController.text.trim();
    final settings = _buildSettings(playerName);
    if (settings == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LobbyScreen(
          settings: settings,
          roundIndex: 0,
        ),
      ),
    );
  }

  void _openJoinRoom() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const JoinRoomScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'بيانات اللعبة',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 24),
              LabeledTextField(
                label: 'اسم اللاعب',
                controller: _playerNameController,
              ),
              const SizedBox(height: 20),
              SelectedGameCard(
                gameLabel: 'اللعبة: ${GameSettings.gameName}',
              ),
              const SizedBox(height: 20),
              LabeledTextField(
                label: 'عنوان الجولة',
                controller: _roundTitleController,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              LabeledDropdown<int>(
                label: 'مدة الجولة',
                value: _selectedDuration,
                items: _durationOptions,
                itemLabelBuilder: _durationLabel,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _selectedDuration = value);
                },
              ),
              const SizedBox(height: 20),
              LabeledDropdown<int>(
                label: 'عدد الجولات',
                value: _selectedRoundCount,
                items: _roundCountOptions,
                itemLabelBuilder: _roundCountLabel,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _selectedRoundCount = value);
                },
              ),
              const SizedBox(height: 32),
              PrimaryPillButton(
                label: _isLoading ? 'جاري إنشاء الغرفة...' : 'إنشاء الغرفة',
                enabled: !_isLoading,
                onPressed: _createRoom,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isLoading ? null : _openJoinRoom,
                child: const Text('انضمام لغرفة'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading ? null : _startSoloGame,
                child: const Text('لعب فردي على هذا الجهاز'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
