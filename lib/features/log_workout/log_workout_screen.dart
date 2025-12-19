// lib/features/log_workout/log_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../../services/database_service.dart';
import 'add_exercise_screen.dart';

class LogWorkoutScreen extends StatefulWidget {
  final Workout? workout;

  const LogWorkoutScreen({super.key, this.workout});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  late DateTime _selectedDate;
  final TextEditingController _durationController = TextEditingController();
  List<Exercise> _exercises = [];
  String? _editingWorkoutId;

  // --- FIX IS HERE: Change 'Color' to 'MaterialColor' ---
  final MaterialColor _themeColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    if (widget.workout != null) {
      _editingWorkoutId = widget.workout!.id;
      _selectedDate = DateTime.parse(widget.workout!.date);
      _durationController.text = widget.workout!.duration.toString();
      _exercises = List.from(widget.workout!.exercises);
    } else {
      _selectedDate = DateTime.now();
      _durationController.text = '';
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _themeColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day,
            _selectedDate.hour, _selectedDate.minute);
      });
    }
  }

  void _showTimePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: _selectedDate,
                  use24hFormat: false,
                  onDateTimeChanged: (DateTime newTime) {
                    setState(() {
                      _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        newTime.hour,
                        newTime.minute,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addOrEditExercise({Exercise? exercise, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddExerciseScreen(exercise: exercise)),
    );
    if (result != null && result is Exercise) {
      setState(() {
        if (index != null) {
          _exercises[index] = result;
        } else {
          _exercises.add(result);
        }
      });
    }
  }

  void _removeExercise(int index) => setState(() => _exercises.removeAt(index));

  Future<void> _saveWorkout() async {
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one exercise.')));
      return;
    }
    int duration = int.tryParse(_durationController.text) ?? 0;
    final workoutId = _editingWorkoutId ?? DateTime.now().toIso8601String();

    final newWorkout = Workout(
      id: workoutId,
      date: _selectedDate.toIso8601String(),
      duration: duration,
      exercises: _exercises,
    );
    await DatabaseService().insertWorkout(newWorkout);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Workout Saved!')));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout != null ? "Edit Workout" : "Log Workout"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: "Date",
                            border: const OutlineInputBorder(),
                            prefixIcon:
                                Icon(Icons.calendar_today, color: _themeColor),
                          ),
                          child: Text(
                            DateFormat('MMM d, yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: _showTimePicker,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: "Time",
                            border: const OutlineInputBorder(),
                            prefixIcon:
                                Icon(Icons.access_time, color: _themeColor),
                          ),
                          child: Text(
                            DateFormat('h:mm a').format(_selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: "Duration (minutes)",
                    hintText: "e.g. 60",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timer),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Exercises",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () => _addOrEditExercise(),
                      icon:
                          Icon(Icons.add_circle, color: _themeColor, size: 30),
                    )
                  ],
                ),
                if (_exercises.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text("No exercises added yet.",
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  ..._exercises.asMap().entries.map((entry) {
                    int idx = entry.key;
                    Exercise ex = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _themeColor.shade100, // Now valid
                          child: Text("${idx + 1}",
                              style: TextStyle(color: _themeColor)),
                        ),
                        title: Text(ex.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "${ex.sets} sets x ${ex.reps} reps @ ${ex.weight}kg"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeExercise(idx),
                        ),
                        onTap: () =>
                            _addOrEditExercise(exercise: ex, index: idx),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Save Workout",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
