import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
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
        theme: ThemeData(
          primarySwatch: Colors.teal,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class Medicine {
  final String name;
  final String dose;
  final TimeOfDay time;
  Medicine({required this.name, required this.dose, required this.time});
}

class MedicineProvider extends ChangeNotifier {
  final List<Medicine> _medicines = [];
  
  List<Medicine> get medicines {
    final sorted = List<Medicine>.from(_medicines);
    sorted.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });
    return sorted;
  }

  void addMedicine(Medicine medicine) {
    _medicines.add(medicine);
    notifyListeners();
  }

  void deleteMedicine(Medicine medicine) {
    _medicines.removeWhere((m) => m.name == medicine.name && m.time == medicine.time);
    notifyListeners();
  }
}

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
        builder: (context, provider, child) {
          final medicines = provider.medicines;
          if (medicines.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medication, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No medicines added', 
                         style: TextStyle(fontSize: 20, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Tap + to add your first medicine', 
                         style: TextStyle(color: Colors.grey)),
                  ],
                ),
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
                      '${medicine.time.hour.toString().padLeft(2, '0')}:${medicine.time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(medicine.name),
                  subtitle: Text('${medicine.dose} • ${medicine.time.format(context)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => provider.deleteMedicine(medicine),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddMedicineScreen()),
        ),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  _AddMedicineScreenState createState() => _AddMedicineScreenState();
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
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter medicine name';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _doseController,
                decoration: const InputDecoration(
                  labelText: 'Dose (e.g., 1 tablet) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_pharmacy),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter dose';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_selectedTime?.format(context) ?? 'Select Time'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) setState(() => _selectedTime = picked);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _selectedTime != null) {
                      Provider.of<MedicineProvider>(context, listen: false).addMedicine(
                        Medicine(
                          name: _nameController.text,
                          dose: _doseController.text,
                          time: _selectedTime!,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('SAVE MEDICINE'),
                ),
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
