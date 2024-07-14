import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TaskPriorityScreen(),
    );
  }
}

class TaskPriorityScreen extends StatefulWidget {
  @override
  _TaskPriorityScreenState createState() => _TaskPriorityScreenState();
}

class _TaskPriorityScreenState extends State<TaskPriorityScreen> {
  final List<Task> tasks = [];
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _typeController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _selectedDateTime;
  int _importance = 1;
  final _estimatedTimeController = TextEditingController();
  String? _selectedCategory;
  TaskType _selectedTaskType = TaskType.schedule; // Default to "予定"
  TaskType _displayedTaskType = TaskType.schedule; // Default to displaying "予定"
  final List<String> _categories = ['野球', '国語', '数学', '理科', '社会', '英語', 'その他'];

  void _addTask() {
    if (_formKey.currentState!.validate() &&
        _selectedDateTime != null &&
        _selectedCategory != null) {
      setState(() {
        tasks.add(Task(
          category: _selectedCategory!,
          type: _typeController.text,
          title: _titleController.text,
          note: _noteController.text,
          deadline: _selectedDateTime!,
          importance: _importance,
          estimatedTime: int.parse(_estimatedTimeController.text),
          taskType: _selectedTaskType, // Add task type
        ));
      });
      _clearForm();
    }
  }

  void _clearForm() {
    _categoryController.clear();
    _typeController.clear();
    _titleController.clear();
    _noteController.clear();
    _selectedDateTime = null;
    _importance = 1;
    _estimatedTimeController.clear();
    _selectedCategory = null;
    _selectedTaskType = TaskType.schedule; // Reset to default
  }

  void _editTask(Task task) {
    setState(() {
      _selectedCategory = task.category;
      _typeController.text = task.type;
      _titleController.text = task.title;
      _noteController.text = task.note;
      _selectedDateTime = task.deadline;
      _importance = task.importance;
      _estimatedTimeController.text = task.estimatedTime.toString();
      _selectedTaskType = task.taskType; // Set the task type
      tasks.remove(task);
    });
  }

  void _toggleComplete(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
  }

  void _deleteTask(Task task) {
    setState(() {
      tasks.remove(task);
    });
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _calculateTimeDifference(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return '期限切れ';
    }

    final days = difference.inDays;
    final hours = difference.inHours.remainder(24);
    final minutes = difference.inMinutes.remainder(60);

    return '$days日$hours時間$minutes分';
  }

  int _calculateTimeDifferenceInHours(DateTime deadline) {
    return deadline.difference(DateTime.now()).inHours;
  }

  int _calculateTotalScore(Task task) {
    final timeDifferenceInHours =
        _calculateTimeDifferenceInHours(task.deadline);
    return task.importance * task.estimatedTime ~/ timeDifferenceInHours;
  }

  @override
  Widget build(BuildContext context) {
    // タスク一覧をtimeDifferenceInHoursが小さい順にソートする
    tasks.sort((a, b) => _calculateTimeDifferenceInHours(a.deadline)
        .compareTo(_calculateTimeDifferenceInHours(b.deadline)));

    return Scaffold(
      appBar: AppBar(
        title: Text('タスク登録'),
      ),
      body: SingleChildScrollView(
        // SingleChildScrollViewでラップする
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    ToggleButtons(
                      isSelected: [
                        _selectedTaskType == TaskType.schedule,
                        _selectedTaskType == TaskType.homework,
                      ],
                      onPressed: (int index) {
                        setState(() {
                          _selectedTaskType = index == 0
                              ? TaskType.schedule
                              : TaskType.homework;
                        });
                      },
                      children: [
                        SizedBox(
                          width: 150,
                          height: 30,
                          child: Center(
                            child: Text('予定'),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          height: 30,
                          child: Center(
                            child: Text('宿題'),
                          ),
                        ),
                      ],
                      renderBorder: false,
                      selectedBorderColor: Colors.black,
                      selectedColor: Colors.white,
                      fillColor: Colors.black,
                      hoverColor: Colors.black.withOpacity(0.1),
                      splashColor: Colors.black.withOpacity(0.2),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(labelText: 'カテゴリ'),
                            items: _categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) return 'カテゴリを選択してください';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _typeController,
                            decoration: InputDecoration(labelText: '種別'),
                            validator: (value) {
                              if (value!.isEmpty) return '種別を入力してください';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'タイトル'),
                      validator: (value) {
                        if (value!.isEmpty) return 'タイトルを入力してください';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(labelText: 'メモ'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDateTime(context),
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: _selectedDateTime == null
                                      ? '期限'
                                      : '期限: ${DateFormat('yyyy/MM/dd HH:mm').format(_selectedDateTime!)}\n'
                                          '残り時間: ${_calculateTimeDifference(_selectedDateTime!)}',
                                ),
                                validator: (value) {
                                  if (_selectedDateTime == null)
                                    return '期限を選択してください';
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('重要度'),
                        ...List.generate(5, (index) {
                          return Row(
                            children: [
                              Radio<int>(
                                value: index + 1,
                                groupValue: _importance,
                                onChanged: (value) {
                                  setState(() {
                                    _importance = value!;
                                  });
                                },
                              ),
                              Text('${index + 1}'),
                            ],
                          );
                        }),
                      ],
                    ),
                    TextFormField(
                      controller: _estimatedTimeController,
                      decoration: const InputDecoration(labelText: '所要時間（分）'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value!.isEmpty) return '所要時間を入力してください';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addTask,
                      child: const Text('登録'),
                    ),
                  ],
                ),
              ),
              ToggleButtons(
                isSelected: [
                  _displayedTaskType == TaskType.schedule,
                  _displayedTaskType == TaskType.homework,
                ],
                onPressed: (int index) {
                  setState(() {
                    _displayedTaskType =
                        index == 0 ? TaskType.schedule : TaskType.homework;
                  });
                },
                children: [
                  SizedBox(
                    width: 150,
                    height: 30,
                    child: Center(
                      child: Text('予定'),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    height: 30,
                    child: Center(
                      child: Text('宿題'),
                    ),
                  ),
                ],
                renderBorder: false,
                selectedBorderColor: Colors.black,
                selectedColor: Colors.white,
                fillColor: Colors.black,
                hoverColor: Colors.black.withOpacity(0.1),
                splashColor: Colors.black.withOpacity(0.2),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  if (task.taskType != _displayedTaskType)
                    return SizedBox.shrink();

                  final timeDifferenceInHours =
                      _calculateTimeDifferenceInHours(task.deadline);

                  DateTime notificationTime;

                  // 条件に基づいて通知時刻を設定
                  if (timeDifferenceInHours / task.estimatedTime <= 1 / 30) {
                    notificationTime = task.deadline
                        .subtract(Duration(minutes: task.estimatedTime));
                  } else if (task.deadline.difference(DateTime.now()).inDays <
                      1) {
                    // 重要度に応じて通知時刻を変更
                    notificationTime = task.deadline.subtract(Duration(
                        minutes: task.estimatedTime * (task.importance + 1)));
                  } else {
                    // 重要度に応じて通知時刻を変更
                    if (task.estimatedTime >= 60)
                      notificationTime = task.deadline
                          .subtract(Duration(days: task.importance));
                    else
                      notificationTime = task.deadline
                          .subtract(Duration(days: (task.importance * task.estimatedTime) ~/ 30));
                  }

                  Widget notificationWidget = SizedBox.shrink();
                  if (notificationTime.isBefore(task.deadline)) {
                    notificationWidget = Text(
                      '通知: ${DateFormat('yyyy/MM/dd HH:mm').format(notificationTime)}',
                      style: TextStyle(
                          color: const Color.fromRGBO(120, 120, 120, 1)),
                    );
                  }

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${task.category} - ${task.type}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _editTask(task),
                              ),
                            ],
                          ),
                          Text(
                            'タイトル: ${task.title}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('メモ: ${task.note}'),
                          Text(
                            '期限: ${DateFormat('yyyy/MM/dd HH:mm').format(task.deadline)}',
                            style: TextStyle(
                              color: timeDifferenceInHours <= 1
                                  ? Colors.red
                                  : null,
                            ),
                          ),
                          Text(
                              '残り時間: ${_calculateTimeDifference(task.deadline)}'),
                          Text('所要時間: ${task.estimatedTime}分'), // 所要時間を追加
                          Row(
                            children: [
                              Text('重要度: '),
                              ...List.generate(
                                task.importance,
                                (index) =>
                                    Icon(Icons.star, color: Colors.black),
                              ),
                            ],
                          ),
                          notificationWidget,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Checkbox(
                                value: task.isCompleted,
                                onChanged: (value) => _toggleComplete(task),
                              ),
                              ElevatedButton(
                                onPressed: () => _deleteTask(task),
                                child: const Text('削除'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum TaskType {
  schedule,
  homework,
}

class Task {
  final String category;
  final String type;
  final String title;
  final String note;
  final DateTime deadline;
  final int importance;
  final int estimatedTime;
  TaskType taskType;
  bool isCompleted;

  Task({
    required this.category,
    required this.type,
    required this.title,
    required this.note,
    required this.deadline,
    required this.importance,
    required this.estimatedTime,
    required this.taskType,
    this.isCompleted = false,
  });
}
