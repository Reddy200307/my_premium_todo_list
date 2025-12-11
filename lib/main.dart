import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Windows 10 acrylic transparency
  await Window.initialize();
  await Window.setEffect(
    effect: WindowEffect.acrylic,
    color: Color(0x00000000),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Rememberings',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'DM Sans',
      ),
      home: TodoApp(),
    );
  }
}

class TodoGroup {
  String id;
  String name;
  List<TodoTask> tasks;

  TodoGroup({required this.id, required this.name, List<TodoTask>? tasks})
    : tasks = tasks ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tasks': tasks.map((t) => t.toJson()).toList(),
  };

  factory TodoGroup.fromJson(Map<String, dynamic> json) => TodoGroup(
    id: json['id'],
    name: json['name'],
    tasks:
        (json['tasks'] as List?)?.map((t) => TodoTask.fromJson(t)).toList() ??
        [],
  );
}

class TodoTask {
  String id;
  String title;
  bool isCompleted;
  DateTime? dueDate;

  TodoTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'dueDate': dueDate?.toIso8601String(),
  };

  factory TodoTask.fromJson(Map<String, dynamic> json) => TodoTask(
    id: json['id'],
    title: json['title'],
    isCompleted: json['isCompleted'] ?? false,
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
  );
}

class TodoApp extends StatefulWidget {
  @override
  _TodoAppState createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  List<TodoGroup> groups = [];
  TodoGroup? selectedGroup;
  TextEditingController groupController = TextEditingController();
  TextEditingController taskController = TextEditingController();
  DateTime? selectedDueDate;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? groupsJson = prefs.getString('groups');
    final String? selectedGroupId = prefs.getString('selectedGroupId');

    if (groupsJson != null) {
      final List<dynamic> decoded = json.decode(groupsJson);
      setState(() {
        groups = decoded.map((g) => TodoGroup.fromJson(g)).toList();
        if (selectedGroupId != null) {
          selectedGroup = groups.firstWhere(
            (g) => g.id == selectedGroupId,
            orElse: () =>
                groups.isNotEmpty ? groups[0] : TodoGroup(id: '', name: ''),
          );
          if (selectedGroup?.id == '') selectedGroup = null;
        }
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String groupsJson = json.encode(
      groups.map((g) => g.toJson()).toList(),
    );
    await prefs.setString('groups', groupsJson);
    if (selectedGroup != null) {
      await prefs.setString('selectedGroupId', selectedGroup!.id);
    }
  }

  void addGroup(String name) {
    if (name.trim().isEmpty) return;
    final newGroup = TodoGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
    setState(() {
      groups.add(newGroup);
    });
    saveData();
    groupController.clear();
  }

  void editGroup(TodoGroup group) {
    final controller = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Group'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Group name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  group.name = controller.text.trim();
                });
                saveData();
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void selectGroup(TodoGroup group) {
    setState(() {
      selectedGroup = group;
    });
    saveData();
  }

  Future<void> pickDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  void clearDueDate() {
    setState(() {
      selectedDueDate = null;
    });
  }

  void addTask(String title) {
    if (title.trim().isEmpty || selectedGroup == null) return;
    final newTask = TodoTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      dueDate: selectedDueDate,
    );
    setState(() {
      selectedGroup!.tasks.add(newTask);
      selectedDueDate = null;
    });
    saveData();
    taskController.clear();
  }

  void editTask(TodoTask task) {
    final controller = TextEditingController(text: task.title);
    DateTime? editDueDate = task.dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Task title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autofocus: true,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: editDueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365 * 2)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            editDueDate = picked;
                          });
                        }
                      },
                      icon: Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        editDueDate != null
                            ? DateFormat('MMM dd, yyyy').format(editDueDate!)
                            : 'Set Due Date',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  if (editDueDate != null) ...[
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setDialogState(() {
                          editDueDate = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    task.title = controller.text.trim();
                    task.dueDate = editDueDate;
                  });
                  saveData();
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void toggleTask(TodoTask task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
    saveData();
  }

  void deleteGroup(TodoGroup group) {
    setState(() {
      groups.remove(group);
      if (selectedGroup?.id == group.id) {
        selectedGroup = null;
      }
    });
    saveData();
  }

  void deleteTask(TodoTask task) {
    setState(() {
      selectedGroup?.tasks.remove(task);
    });
    saveData();
  }

  String formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow';
    } else if (taskDate.isBefore(today)) {
      return 'Overdue';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  Color getDueDateColor(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate.isBefore(today)) {
      return Colors.red;
    } else if (taskDate == today) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Row(
        children: [
          // Left sidebar - Groups
          Container(
            width: 320,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE8D6), Color(0xFFD4E8F0)],
              ),
              border: Border(
                right: BorderSide(color: Colors.black12, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.orange,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Groups',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Organize your tasks by groups',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Add Group
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 16),
                        Icon(Icons.add_circle, color: Colors.blue, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: groupController,
                            decoration: InputDecoration(
                              hintText: 'Add a new group...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.black26),
                            ),
                            onSubmitted: addGroup,
                          ),
                        ),
                        Material(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => addGroup(groupController.text),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: Text(
                                'Add',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Groups List
                Expanded(
                  child: groups.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Create your first group to get started!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: groups.length,
                          itemBuilder: (context, index) {
                            final group = groups[index];
                            final isSelected = selectedGroup?.id == group.id;
                            final completedTasks = group.tasks
                                .where((t) => t.isCompleted)
                                .length;

                            return Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: isSelected
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: () => selectGroup(group),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.blue.withOpacity(0.3)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.folder,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                group.name,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                '$completedTasks of ${group.tasks.length} tasks',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit_outlined,
                                            color: Colors.blue.withOpacity(0.7),
                                          ),
                                          onPressed: () => editGroup(group),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red.withOpacity(0.7),
                                          ),
                                          onPressed: () => deleteGroup(group),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Right side - Tasks
          Expanded(
            child: selectedGroup == null
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFE8D6), Color(0xFFD4F0E8)],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 80,
                            color: Colors.black12,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Select a group to view tasks',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFE8D6), Color(0xFFD4F0E8)],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.orange,
                                  size: 32,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedGroup!.name,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Manage your tasks',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Add Task
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(width: 16),
                                Icon(
                                  Icons.add_circle,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: taskController,
                                    decoration: InputDecoration(
                                      hintText: 'Add a new task...',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(
                                        color: Colors.black26,
                                      ),
                                    ),
                                    onSubmitted: addTask,
                                  ),
                                ),
                                if (selectedDueDate != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.blue,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          DateFormat(
                                            'MMM dd',
                                          ).format(selectedDueDate!),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        InkWell(
                                          onTap: clearDueDate,
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                IconButton(
                                  icon: Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: selectedDueDate != null
                                        ? Colors.blue
                                        : Colors.black38,
                                  ),
                                  onPressed: pickDueDate,
                                ),
                                Material(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () => addTask(taskController.text),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        'Add',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 24),

                        // Tasks List
                        Expanded(
                          child: selectedGroup!.tasks.isEmpty
                              ? Center(
                                  child: Text(
                                    'No tasks yet. Add one above!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black38,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.symmetric(horizontal: 24),
                                  itemCount: selectedGroup!.tasks.length,
                                  itemBuilder: (context, index) {
                                    final task = selectedGroup!.tasks[index];
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => toggleTask(task),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: task.isCompleted
                                                            ? Colors.green
                                                            : Colors.blue,
                                                        width: 2.5,
                                                      ),
                                                      color: task.isCompleted
                                                          ? Colors.green
                                                          : Colors.transparent,
                                                    ),
                                                    child: task.isCompleted
                                                        ? Icon(
                                                            Icons.check,
                                                            color: Colors.white,
                                                            size: 18,
                                                          )
                                                        : null,
                                                  ),
                                                  SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          task.title,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            color:
                                                                task.isCompleted
                                                                ? Colors.black38
                                                                : Colors
                                                                      .black87,
                                                            decoration:
                                                                task.isCompleted
                                                                ? TextDecoration
                                                                      .lineThrough
                                                                : null,
                                                          ),
                                                        ),
                                                        if (task.dueDate !=
                                                            null) ...[
                                                          SizedBox(height: 4),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .calendar_today,
                                                                size: 12,
                                                                color: getDueDateColor(
                                                                  task.dueDate!,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                formatDueDate(
                                                                  task.dueDate!,
                                                                ),
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: getDueDateColor(
                                                                    task.dueDate!,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.edit_outlined,
                                                      color: Colors.blue
                                                          .withOpacity(0.7),
                                                    ),
                                                    onPressed: () =>
                                                        editTask(task),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red
                                                          .withOpacity(0.7),
                                                    ),
                                                    onPressed: () =>
                                                        deleteTask(task),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    groupController.dispose();
    taskController.dispose();
    super.dispose();
  }
}
