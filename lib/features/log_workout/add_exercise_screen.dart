// lib/features/log_workout/add_exercise_screen.dart
import 'package:flutter/material.dart';
import '../../models/exercise.dart';

class AddExerciseScreen extends StatefulWidget {
  final Exercise? exercise;

  const AddExerciseScreen({super.key, this.exercise});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();

  // Type State
  String _selectedType = 'strength';

  // Controllers
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _setsController = TextEditingController();

  // New Cardio Controllers
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();

  final Color _themeColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    if (widget.exercise != null) {
      _selectedType = widget.exercise!.type;
      _nameController.text = widget.exercise!.name;

      if (_selectedType == 'strength') {
        _weightController.text = widget.exercise!.weight.toString();
        _repsController.text = widget.exercise!.reps.toString();
        _setsController.text = widget.exercise!.sets.toString();
      } else {
        _distanceController.text = widget.exercise!.distance?.toString() ?? "";
        _durationController.text = widget.exercise!.duration?.toString() ?? "";
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newExercise = Exercise(
        id: widget.exercise?.id ?? DateTime.now().toIso8601String(),
        name: _nameController.text.trim(),
        type: _selectedType,
        // Strength data (default to 0 if cardio)
        weight: _selectedType == 'strength'
            ? double.parse(_weightController.text)
            : 0.0,
        reps: _selectedType == 'strength' ? int.parse(_repsController.text) : 0,
        sets: _selectedType == 'strength' ? int.parse(_setsController.text) : 0,
        // Cardio data (null if strength)
        distance: _selectedType == 'cardio'
            ? double.tryParse(_distanceController.text)
            : null,
        duration: _selectedType == 'cardio'
            ? int.tryParse(_durationController.text)
            : null,
      );

      Navigator.pop(context, newExercise);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise == null ? "Add Exercise" : "Edit Exercise"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- TYPE TOGGLE ---
              Center(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'strength',
                        label: Text('Strength'),
                        icon: Icon(Icons.fitness_center)),
                    ButtonSegment(
                        value: 'cardio',
                        label: Text('Cardio'),
                        icon: Icon(Icons.directions_run)),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              // --- NAME (Shared) ---
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Exercise Name",
                  hintText: _selectedType == 'strength'
                      ? "e.g. Bench Press"
                      : "e.g. Treadmill Run",
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                      _selectedType == 'strength'
                          ? Icons.fitness_center
                          : Icons.directions_run,
                      color: _themeColor),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Please enter a name" : null,
              ),
              const SizedBox(height: 15),

              // --- CONDITIONAL FIELDS ---
              if (_selectedType == 'strength') ...[
                // WEIGHT
                TextFormField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Weight (kg)",
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_weight, color: _themeColor),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Enter weight";
                    if (double.tryParse(val) == null) return "Must be a number";
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                // SETS & REPS
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _setsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Sets",
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.repeat, color: _themeColor),
                        ),
                        validator: (val) =>
                            (val == null || int.tryParse(val) == null)
                                ? "Enter sets"
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _repsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Reps",
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers, color: _themeColor),
                        ),
                        validator: (val) =>
                            (val == null || int.tryParse(val) == null)
                                ? "Enter reps"
                                : null,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // DISTANCE
                TextFormField(
                  controller: _distanceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Distance (km)",
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map, color: _themeColor),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Enter distance";
                    if (double.tryParse(val) == null) return "Must be a number";
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                // DURATION
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Duration (minutes)",
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timer, color: _themeColor),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Enter minutes";
                    if (int.tryParse(val) == null) return "Integer only";
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 30),

              // --- SAVE BUTTON ---
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                  ),
                  child: Text(
                    widget.exercise == null
                        ? "Add to Workout"
                        : "Update Exercise",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
