import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MedicineProvider(),
      child: MaterialApp(
        title: 'Medicine Reminder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

/* ===================== MODEL ===================== */

class Medicine {
  final String name;
  final String dose;
  final DateTime time;

  Medicine({
    required this.name,
    required this.dose,
    required this.time,
  });
}

/* ===================== PROVIDER ===================== */

class MedicineProvider extends ChangeNotifier {
  final List<Medicine> _medicines = [];

  List<Medicine> get medicines {
    final sorted = List<Medicine>.from(_medicines);
    sorted.sort((a, b) => a.time.compareTo(b.time));
    return sorted;
  }

  void addMedicine(Medicine medicine) {
    _medicines.add(medicine);

    NotificationService.scheduleNotification(
      medicine.hashCode,
      medicine.name,
      medicine.time,
    );

    notifyListeners();
  }

  void deleteMedicine(Medicine medicine) {
    _medicines.remove(medicine);
    notifyListeners();
  }
}

/* ===================== HOME SCREEN ===================== */

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminder'),
        backgroundColor: Colors.teal,
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, _) {
          final medicines = provider.medicines;

          if (medicines.isEmpty) {
            return const Center(
              child: Text(
                'No medicines added',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Text(
                      DateFormat('HH:mm').format(medicine.time),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(medicine.name),
                  subtitle: Text(
                    '${medicine.dose} • ${DateFormat.jm().format(medicine.time)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        provider.deleteMedicine(medicine),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddMedicineScreen(),
            ),
          );
        },
      ),
    );
  }
}

/* ===================== ADD MEDICINE SCREEN ===================== */

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medicine'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _doseController,
                decoration: const InputDecoration(
                  labelText: 'Dose',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _selectedTime == null
                      ? 'Select Time'
                      : _selectedTime!.format(context),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedTime = picked);
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      _selectedTime != null) {
                    final now = DateTime.now();
                    final scheduledTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      _selectedTime!.hour,
                      _selectedTime!.minute,
                    );

                    Provider.of<MedicineProvider>(
                      context,
                      listen: false,
                    ).addMedicine(
                      Medicine(
                        name: _nameController.text,
                        dose: _doseController.text,
                        time: scheduledTime,
                      ),
                    );

                    Navigator.pop(context);
                  }
                },
                child: const Text('SAVE MEDICINE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    super.dispose();
  }
}
