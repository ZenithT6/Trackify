import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class SetGoalsScreen extends StatefulWidget {
  const SetGoalsScreen({super.key});

  @override
  State<SetGoalsScreen> createState() => _SetGoalsScreenState();
}

class _SetGoalsScreenState extends State<SetGoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stepsController = TextEditingController();
  final _sleepController = TextEditingController();
  final _caloriesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final box = await Hive.openBox('goalBox');
    setState(() {
      _stepsController.text = (box.get('stepsGoal') ?? 8000).toString();
      _sleepController.text = (box.get('sleepGoal') ?? 8).toString();
      _caloriesController.text = (box.get('calorieGoal') ?? 2200).toString();
    });
  }

  Future<void> _saveGoals() async {
    if (_formKey.currentState!.validate()) {
      final box = await Hive.openBox('goalBox');
      await box.put('stepsGoal', int.parse(_stepsController.text));
      await box.put('sleepGoal', double.parse(_sleepController.text));
      await box.put('calorieGoal', int.parse(_caloriesController.text));

      if (!mounted) return;

      // ✅ Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎯 Goals saved successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );

      // ✅ Auto pop after delay
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _sleepController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Goals'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTextField("Steps Goal", _stepsController, "e.g. 8000", max: 100000),
            const SizedBox(height: 20),
            _buildTextField("Sleep Goal (hrs)", _sleepController, "e.g. 8.0", isDecimal: true, max: 24),
            const SizedBox(height: 20),
            _buildTextField("Calories Goal", _caloriesController, "e.g. 2200", max: 10000),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveGoals,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                "Save Goals",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isDecimal = false,
    num? max,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a value';
        }
        final parsed = isDecimal ? double.tryParse(value) : int.tryParse(value);
        if (parsed == null || parsed <= 0) {
          return 'Enter a valid ${isDecimal ? "decimal" : "number"} > 0';
        }
        if (max != null && parsed > max) {
          return 'Must be less than or equal to $max';
        }
        return null;
      },
    );
  }
}
