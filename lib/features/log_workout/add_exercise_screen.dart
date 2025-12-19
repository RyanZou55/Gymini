// lib/features/log_workout/add_exercise_screen.dart
import 'package:flutter/material.dart';
import '../../models/exercise.dart';

class AddExerciseScreen extends StatefulWidget {
  final Exercise? exercise; // If provided, we are editing

  const AddExerciseScreen({super.key, this.exercise});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _setsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If editing, populate the fields
    if (widget.exercise != null) {
      _nameController.text = widget.exercise!.name;
      _weightController.text = widget.exercise!.weight.toString();
      _repsController.text = widget.exercise!.reps.toString();
      _setsController.text = widget.exercise!.sets.toString();
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Create the Exercise Object
      // Note: We use a temp ID or keep the existing one.
      // The Workout ID is handled by the parent screen when saving the whole workout.
      final newExercise = Exercise(
        id: widget.exercise?.id ??
            DateTime.now().toIso8601String(), // New ID if creating
        workoutId:
            widget.exercise?.workoutId ?? '', // Placeholder, parent sets this
        name: _nameController.text.trim(),
        weight: double.parse(_weightController.text),
        reps: int.parse(_repsController.text),
        sets: int.parse(_setsController.text),
      );

      // Return the object to the previous screen
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
              // --- NAME ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Exercise Name",
                  hintText: "e.g. Bench Press",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Please enter a name" : null,
              ),
              const SizedBox(height: 15),

              // --- WEIGHT ---
              TextFormField(
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Weight (kg)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Enter weight";
                  if (double.tryParse(val) == null) return "Must be a number";
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // --- ROW FOR SETS & REPS ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _setsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Sets",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Enter sets";
                        if (int.tryParse(val) == null) return "Integer only";
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Reps",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Enter reps";
                        if (int.tryParse(val) == null) return "Integer only";
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- SAVE BUTTON ---
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Add to Workout",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
