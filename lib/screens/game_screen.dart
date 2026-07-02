import 'package:flutter/material.dart';

import '../data/questions.dart';
import '../models/question.dart';
import '../widgets/answer_button.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<Question> _questions = List<Question>.from(sampleQuestions);
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _answered = false;

  Question get _currentQuestion => _questions[_currentIndex];

  void _selectAnswer(int index) {
    if (_answered) {
      return;
    }

    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (index == _currentQuestion.correctIndex) {
        _score++;
      }
    });
  }

  void _goToNextQuestion() {
    if (_currentIndex == _questions.length - 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            score: _score,
            totalQuestions: _questions.length,
          ),
        ),
      );
      return;
    }

    setState(() {
      _currentIndex++;
      _selectedIndex = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} of ${_questions.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
            ),
            const SizedBox(height: 24),
            Text(
              _currentQuestion.prompt,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: _currentQuestion.options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  bool? isCorrect;
                  if (_answered) {
                    if (index == _currentQuestion.correctIndex) {
                      isCorrect = true;
                    } else if (index == _selectedIndex) {
                      isCorrect = false;
                    }
                  }

                  return AnswerButton(
                    label: _currentQuestion.options[index],
                    isSelected: _selectedIndex == index,
                    isCorrect: isCorrect,
                    onPressed: () => _selectAnswer(index),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _answered ? _goToNextQuestion : null,
              child: Text(
                _currentIndex == _questions.length - 1 ? 'See Results' : 'Next',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
