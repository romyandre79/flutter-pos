import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/data/models/unit.dart';
import 'package:flutter_pos/logic/cubits/unit/unit_cubit.dart';

class UnitListScreen extends StatefulWidget {
  const UnitListScreen({Key? key}) : super(key: key);

  @override
  State<UnitListScreen> createState() => _UnitListScreenState();
}

class _UnitListScreenState extends State<UnitListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UnitCubit>().loadUnits();
  }

  void _showUnitDialog([Unit? unit]) {
    final TextEditingController nameController = TextEditingController(text: unit?.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(unit == null ? 'Tambah Unit' : 'Edit Unit'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Unit (kg, pcs, dll)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                if (unit == null) {
                  context.read<UnitCubit>().addUnit(nameController.text);
                } else {
                  context.read<UnitCubit>().updateUnit(unit.copyWith(name: nameController.text));
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Unit unit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Unit'),
        content: Text('Apakah Anda yakin ingin menghapus unit "${unit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<UnitCubit>().deleteUnit(unit.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Satuan (Unit)'),
      ),
      body: BlocConsumer<UnitCubit, UnitState>(
        listener: (context, state) {
          if (state is UnitOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is UnitError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is UnitLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UnitLoaded) {
            final units = state.units;
            if (units.isEmpty) {
               return const Center(child: Text('Belum ada data unit'));
            }
            return ListView.builder(
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];
                return ListTile(
                  title: Text(unit.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showUnitDialog(unit),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(unit),
                      ),
                    ],
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Something went wrong'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUnitDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
