// lib/features/log_meal/log_meal_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/meal.dart';
import '../../services/database_service.dart';

class LogMealScreen extends StatefulWidget {
  const LogMealScreen({super.key});

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  final _itemsController = TextEditingController();

  String _selectedType = 'Breakfast';
  DateTime _selectedTime = DateTime.now();

  // Track if we are editing an existing meal so we can update it instead of creating a new one
  String? _existingId;

  int _hungerBefore = 3;
  int _hungerAfter = 4;

  final Color _themeColor = Colors.deepPurple;
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    // Load data immediately when screen opens
    _loadExistingMeal();
  }

  /// Checks the database for a meal matching the selected Date and Type.
  Future<void> _loadExistingMeal() async {
    // 1. Get all meals for the selected date
    // Note: Assuming your DatabaseService has a method to get meals by date.
    // If not, you might need to fetch all and filter, or add a query method.
    final mealsOnDate = await DatabaseService().getMealsByDate(_selectedTime);

    // 2. Find if there is a meal of the selected TYPE (e.g., "Breakfast")
    try {
      final existingMeal = mealsOnDate.firstWhere(
        (meal) => meal.type == _selectedType,
      );

      // 3. Populate UI with existing data
      if (mounted) {
        setState(() {
          _itemsController.text = existingMeal.items;
          _hungerBefore = existingMeal.hungerRatingBefore;
          _hungerAfter = existingMeal.hungerRatingAfter;
          _selectedTime =
              existingMeal.timestamp; // Restore the original saved time
          _existingId = existingMeal.id; // Store ID for updating
        });
      }
    } catch (e) {
      // 4. No existing meal found for this type? Reset form to defaults.
      if (mounted) {
        setState(() {
          _itemsController.clear();
          _hungerBefore = 3;
          _hungerAfter = 4;
          _existingId = null; // We are creating a NEW entry

          // Optional: Reset time to 'now' if you prefer, or keep selected date
          // _selectedTime = DateTime(...)
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
        // Keep the current time (hours/min) but change the date
        _selectedTime = DateTime(picked.year, picked.month, picked.day,
            _selectedTime.hour, _selectedTime.minute);
      });
      // RELOAD data for the new date
      await _loadExistingMeal();
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
                  initialDateTime: _selectedTime,
                  use24hFormat: false,
                  onDateTimeChanged: (DateTime newTime) {
                    setState(() {
                      _selectedTime = DateTime(
                        _selectedTime.year,
                        _selectedTime.month,
                        _selectedTime.day,
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

  Future<void> _saveMeal() async {
    if (_itemsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter what you ate.')),
      );
      return;
    }

    // Use existing ID if updating, otherwise create new ID
    final mealToSave = Meal(
      id: _existingId ?? DateTime.now().toIso8601String(),
      timestamp: _selectedTime,
      type: _selectedType,
      items: _itemsController.text.trim(),
      hungerRatingBefore: _hungerBefore,
      hungerRatingAfter: _hungerAfter,
    );

    // If _existingId is not null, this logically updates (depending on your DB implementation).
    // Usually insertMeal with ConflictAlgorithm.replace handles both.
    await DatabaseService().insertMeal(mealToSave);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Meal Logged!'),
        duration: Duration(seconds: 1),
      ));

      // Navigate back to Home
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Meal")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // DATE & TIME
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
                    child:
                        Text(DateFormat('MMM d, yyyy').format(_selectedTime)),
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
                      prefixIcon: Icon(Icons.access_time, color: _themeColor),
                    ),
                    child: Text(DateFormat('h:mm a').format(_selectedTime)),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 30),

          // MEAL TYPE
          const Text("Meal Type",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: _mealTypes.map((type) {
              final isSelected = _selectedType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                selectedColor: _themeColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                checkmarkColor: Colors.white,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedType = type);
                    // RELOAD data when switching types (e.g. from Breakfast to Lunch)
                    _loadExistingMeal();
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // FOOD ITEMS
          TextField(
            controller: _itemsController,
            decoration: const InputDecoration(
              labelText: "What did you eat?",
              hintText: "e.g., Oatmeal, 2 Eggs...",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.restaurant),
            ),
          ),
          const SizedBox(height: 20),

          // --- HUNGER SLIDERS ---

          // 1. BEFORE
          const Text("Hunger BEFORE Eating",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              const Text("Starving",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Expanded(
                child: Slider(
                  value: _hungerBefore.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: _themeColor,
                  label: "$_hungerBefore/5",
                  onChanged: (val) =>
                      setState(() => _hungerBefore = val.toInt()),
                ),
              ),
              const Text("Full",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),

          const SizedBox(height: 10),

          // 2. AFTER
          const Text("Satiety AFTER Eating",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              const Text("Still Hungry",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Expanded(
                child: Slider(
                  value: _hungerAfter.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: _themeColor,
                  label: "$_hungerAfter/5",
                  onChanged: (val) =>
                      setState(() => _hungerAfter = val.toInt()),
                ),
              ),
              const Text("Stuffed",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _saveMeal,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: _themeColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save Meal Log",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
