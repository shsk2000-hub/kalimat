import '../models/question.dart';

const List<Question> sampleQuestions = [
  Question(
    prompt: 'Which word is a synonym for "happy"?',
    options: ['Joyful', 'Heavy', 'Silent', 'Broken'],
    correctIndex: 0,
  ),
  Question(
    prompt: 'What is the opposite of "ancient"?',
    options: ['Old', 'Modern', 'Rusty', 'Quiet'],
    correctIndex: 1,
  ),
  Question(
    prompt: 'Which word means "to make something better"?',
    options: ['Ignore', 'Improve', 'Shrink', 'Delay'],
    correctIndex: 1,
  ),
  Question(
    prompt: 'Which word describes something very small?',
    options: ['Tiny', 'Giant', 'Loud', 'Bright'],
    correctIndex: 0,
  ),
  Question(
    prompt: 'Which word is a type of story?',
    options: ['Hammer', 'Novel', 'River', 'Cloud'],
    correctIndex: 1,
  ),
];
