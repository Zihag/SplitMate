import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitmate/features/data/models/user_info_model.dart';
import 'package:splitmate/features/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:splitmate/features/presentation/bloc/expense_bloc/expense_bloc.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final User currentUser = FirebaseAuth.instance.currentUser!;

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _runningTotal = 0;

  List<UserInfoModel> allUsers = [];
  List<String> selectedUsers = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchUsers();
    selectedUsers.add(currentUser.displayName!);
  }

  Future<void> _fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      allUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        return UserInfoModel.fromMap(data);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm chi tiêu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocConsumer<ExpenseBloc, ExpenseState>(
          listener: (context, state) {
            if (state is ExpenseAddedSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã thêm chi tiêu')),
              );
              context.read<ExpenseBloc>().add(GetExpensesEvent());
              Navigator.pop(context);
            } else if (state is ExpenseAddError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is ExpenseAdding;
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số tiền',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final input =
                            int.tryParse(_amountController.text.trim());
                        if (input != null && input > 0) {
                          setState(() {
                            _runningTotal += input;
                            _amountController.clear();
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Nhập đúng số tiền')),
                          );
                        }
                      },
                      child: const Icon(Icons.add),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _runningTotal = 0;
                          });
                        },
                        child: Icon(Icons.delete))
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  'Tổng: ₫$_runningTotal',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                SizedBox(
                  height: 40,
                ),
                Text('Người tham gia'),
                Expanded(
                    child: ListView.builder(
                  itemCount: allUsers.length,
                  itemBuilder: (context, index) {
                    final user = allUsers[index];
                    final isSelected = selectedUsers.contains(user.displayName);

                    return CheckboxListTile(
                      title: currentUser.uid == user.uid
                          ? Text('Bạn')
                          : Text(user.displayName),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedUsers.add(user.displayName);
                          } else {
                            selectedUsers.remove(user.displayName);
                          }
                        });
                      },
                    );
                  },
                )),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          final total = _runningTotal;
                          final description =
                              _descriptionController.text.trim();

                          // 🔴 Kiểm tra điều kiện trước khi tạo
                          if (total == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Vui lòng nhập số tiền hợp lệ')),
                            );
                            return;
                          }

                          if (selectedUsers.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Chọn ít nhất một người tham gia')),
                            );
                            return;
                          }

                          context.read<ExpenseBloc>().add(AddExpenseEvent(
                                amount: total,
                                description: description,
                                participants: selectedUsers,
                              ));
                        },
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Thêm chi tiêu'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
