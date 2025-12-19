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
  int _hungerRating = 3;
  DateTime _selectedTime = DateTime.now();

  // --- THEME COLOR ---
  final Color _themeColor = Colors.deepPurple;

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

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
        _selectedTime = DateTime(picked.year, picked.month, picked.day,
            _selectedTime.hour, _selectedTime.minute);
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
    final newMeal = Meal(
      id: DateTime.now().toIso8601String(),
      timestamp: _selectedTime,
      type: _selectedType,
      items: _itemsController.text.trim(),
      hungerRating: _hungerRating,
    );
    await DatabaseService().insertMeal(newMeal);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal Logged!'),
          duration: Duration(seconds: 1),
        ),
      );
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

                // (Optional) Ensure checkmark is also white
                checkmarkColor: Colors.white,

                onSelected: (selected) {
                  if (selected) setState(() => _selectedType = type);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
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
          const Text("Hunger Level (Before Eating)",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const Text("1 = Starving, 5 = Stuffed",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          Slider(
            value: _hungerRating.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: _themeColor,
            label: "$_hungerRating/5",
            onChanged: (val) => setState(() => _hungerRating = val.toInt()),
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
