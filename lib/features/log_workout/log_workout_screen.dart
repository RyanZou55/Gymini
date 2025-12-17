import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';

class LogWorkoutScreen extends StatefulWidget {
  const LogWorkoutScreen({super.key});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();

  // Storage for the form
  List<Map<String, TextEditingController>> _exerciseControllers = [];

  // Storage for history
  List<Workout> _existingWorkouts = [];

  // NEW: Track if we are editing an existing workout
  String? _editingWorkoutId;

  @override
  void initState() {
    super.initState();
    _addExerciseField();
    _loadExistingWorkouts();
  }

  Future<void> _loadExistingWorkouts() async {
    List<Workout> data =
        await DatabaseService().getWorkoutsForDay(_selectedDate);
    setState(() {
      _existingWorkouts = data;
    });
  }

  void _addExerciseField() {
    setState(() {
      _exerciseControllers.add({
        'name': TextEditingController(),
        'weight': TextEditingController(),
        'reps': TextEditingController(),
        'sets': TextEditingController(),
      });
    });
  }

  void _removeExerciseField(int index) {
    setState(() {
      _exerciseControllers.removeAt(index);
    });
  }

  // --- NEW: Logic to load a workout into the form ---
  void _editWorkout(Workout workout) {
    setState(() {
      // 1. Clear current form
      _exerciseControllers.clear();
      _editingWorkoutId = workout.id; // Mark that we are editing this ID

      // 2. Load data from the workout into controllers
      for (var ex in workout.exercises) {
        _exerciseControllers.add({
          'name': TextEditingController(text: ex.name),
          'weight': TextEditingController(text: ex.weight.toString()),
          'reps': TextEditingController(text: ex.reps.toString()),
          'sets': TextEditingController(text: ex.sets.toString()),
        });
      }
    });
  }

  // --- NEW: Logic to delete ---
  Future<void> _deleteWorkout(String workoutId) async {
    await DatabaseService().deleteWorkout(workoutId);
    await _loadExistingWorkouts(); // Refresh list
    _showSmallSnackBar("Workout deleted", isError: false);
  }

  Future<void> _saveWorkout() async {
    if (_exerciseControllers.isEmpty) {
      _showSmallSnackBar("Add at least one exercise!", isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showSmallSnackBar("Please check your inputs.", isError: true);
      return;
    }

    // If we are "Editing", we technically delete the old one and save the new one
    // This is safer than trying to update nested SQL tables individually
    if (_editingWorkoutId != null) {
      await DatabaseService().deleteWorkout(_editingWorkoutId!);
    }

    final workoutId = _editingWorkoutId ?? const Uuid().v4();
    final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    List<Exercise> exercises = _exerciseControllers.map((controllers) {
      return Exercise(
        id: const Uuid().v4(),
        workoutId: workoutId,
        name: controllers['name']!.text,
        weight: double.tryParse(controllers['weight']!.text) ?? 0.0,
        reps: int.tryParse(controllers['reps']!.text) ?? 0,
        sets: int.tryParse(controllers['sets']!.text) ?? 0,
      );
    }).toList();

    final workout = Workout(
      id: workoutId,
      date: dateStr,
      duration: 60,
      exercises: exercises,
    );

    await DatabaseService().insertWorkout(workout);

    setState(() {
      _exerciseControllers.clear();
      _addExerciseField();
      _editingWorkoutId = null; // Reset edit mode
    });

    await _loadExistingWorkouts();
    _showSmallSnackBar("Success! Saved.", isError: false);
  }

  // --- NEW: Custom Helper for Smaller Alerts ---
  void _showSmallSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Close others first
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating, // Makes it float
        width: 250, // Makes it small
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = _editingWorkoutId != null;

    return Scaffold(
      appBar:
          AppBar(title: Text(isEditing ? 'Editing Workout...' : 'Log Workout')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. DATE PICKER
            ListTile(
              tileColor: Colors.grey[200],
              title: Text(
                "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now());
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    _editingWorkoutId = null; // Cancel edit if changing dates
                  });
                  _loadExistingWorkouts();
                }
              },
            ),

            // 2. EXISTING LOGS
            if (_existingWorkouts.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Completed on this day:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue))),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _existingWorkouts.length,
                itemBuilder: (context, index) {
                  final w = _existingWorkouts[index];
                  final summary = w.exercises
                      .map((e) => "${e.name}: ${e.weight}kg x ${e.reps}")
                      .join('\n');

                  return Card(
                    color: Colors.blue[50],
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(summary,
                                  style: const TextStyle(fontSize: 14))),
                          // EDIT BUTTON
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.orange, size: 20),
                            onPressed: () => _editWorkout(w),
                            tooltip: "Edit this session",
                          ),
                          // DELETE BUTTON
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red, size: 20),
                            onPressed: () => _deleteWorkout(w.id),
                            tooltip: "Delete",
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 30, thickness: 2),
            ] else ...[
              // Only show "No logs" if NOT editing. If editing, we hide this to focus on the form.
              if (!isEditing)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No logs for this date yet.",
                      style: TextStyle(color: Colors.grey)),
                ),
            ],

            // 3. INPUT FORM
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      isEditing
                          ? "Editing Session (Make changes below):"
                          : "Add New Session:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isEditing ? Colors.orange : Colors.black))),
            ),

            Form(
              key: _formKey,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exerciseControllers.length,
                itemBuilder: (context, index) {
                  final ctrls = _exerciseControllers[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    // Highlight the card if we are in edit mode
                    shape: isEditing
                        ? RoundedRectangleBorder(
                            side: const BorderSide(
                                color: Colors.orange, width: 2),
                            borderRadius: BorderRadius.circular(12))
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: ctrls['name'],
                            decoration: const InputDecoration(
                                labelText: 'Exercise Name'),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          Row(
                            children: [
                              Expanded(
                                  child: TextFormField(
                                controller: ctrls['weight'],
                                decoration:
                                    const InputDecoration(labelText: 'Kg'),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Req' : null,
                              )),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: TextFormField(
                                controller: ctrls['reps'],
                                decoration:
                                    const InputDecoration(labelText: 'Reps'),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Req' : null,
                              )),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: TextFormField(
                                controller: ctrls['sets'],
                                decoration:
                                    const InputDecoration(labelText: 'Sets'),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Req' : null,
                              )),
                            ],
                          ),
                          if (_exerciseControllers.length > 1)
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeExerciseField(index),
                              ),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. BUTTONS
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                      onPressed: _addExerciseField,
                      child: const Text("Add Another Exercise")),
                  ElevatedButton(
                    onPressed: _saveWorkout,
                    style: ElevatedButton.styleFrom(
                      // Change color to Orange if editing, Blue if new
                      backgroundColor: isEditing ? Colors.orange : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isEditing ? "Update Log" : "Save Session"),
                  ),
                ],
              ),
            ),

            // Cancel Edit Button (Only visible when editing)
            if (isEditing)
              TextButton(
                onPressed: () {
                  setState(() {
                    _editingWorkoutId = null;
                    _exerciseControllers.clear();
                    _addExerciseField();
                  });
                },
                child: const Text("Cancel Editing",
                    style: TextStyle(color: Colors.grey)),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
