import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  TodoTask({required this.id, required this.title, this.isCompleted = false});

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
  };

  factory TodoTask.fromJson(Map<String, dynamic> json) => TodoTask(
    id: json['id'],
    title: json['title'],
    isCompleted: json['isCompleted'] ?? false,
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
  final GlobalKey<AnimatedListState> _groupsListKey = GlobalKey();
  final GlobalKey<AnimatedListState> _tasksListKey = GlobalKey();

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
        }
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
        title: Text('Edit Group', style: TextStyle(fontFamily: 'DM Sans')),
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
            child: Text('Cancel', style: TextStyle(fontFamily: 'DM Sans')),
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
            child: Text('Save', style: TextStyle(fontFamily: 'DM Sans')),
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

  void addTask(String title) {
    if (title.trim().isEmpty || selectedGroup == null) return;
    final newTask = TodoTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );
    setState(() {
      selectedGroup!.tasks.add(newTask);
    });
    saveData();
    taskController.clear();
  }

  void editTask(TodoTask task) {
    final controller = TextEditingController(text: task.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Task', style: TextStyle(fontFamily: 'DM Sans')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Task title',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontFamily: 'DM Sans')),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  task.title = controller.text.trim();
                });
                saveData();
                Navigator.pop(context);
              }
            },
            child: Text('Save', style: TextStyle(fontFamily: 'DM Sans')),
          ),
        ],
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
    final index = groups.indexOf(group);
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

  @override
  Widget build(BuildContext context) {
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
                                fontFamily: 'DM Sans',
                              ),
                            ),
                            Text(
                              'Organize your tasks by groups',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontFamily: 'DM Sans',
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
                            style: TextStyle(fontFamily: 'DM Sans'),
                            decoration: InputDecoration(
                              hintText: 'Add a new group...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.black26,
                                fontFamily: 'DM Sans',
                              ),
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
                                  fontFamily: 'DM Sans',
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
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final isSelected = selectedGroup?.id == group.id;
                      final completedTasks = group.tasks
                          .where((t) => t.isCompleted)
                          .length;

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => selectGroup(group),
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
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
                                        borderRadius: BorderRadius.circular(12),
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
                                              fontFamily: 'DM Sans',
                                            ),
                                          ),
                                          Text(
                                            '$completedTasks of ${group.tasks.length} tasks',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                              fontFamily: 'DM Sans',
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
                              fontFamily: 'DM Sans',
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
                                        fontFamily: 'DM Sans',
                                      ),
                                    ),
                                    Text(
                                      'Manage your tasks',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                        fontFamily: 'DM Sans',
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
                                    style: TextStyle(fontFamily: 'DM Sans'),
                                    decoration: InputDecoration(
                                      hintText: 'Add a new task...',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(
                                        color: Colors.black26,
                                        fontFamily: 'DM Sans',
                                      ),
                                    ),
                                    onSubmitted: addTask,
                                  ),
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
                                          fontFamily: 'DM Sans',
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
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            itemCount: selectedGroup!.tasks.length,
                            itemBuilder: (context, index) {
                              final task = selectedGroup!.tasks[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(50 * (1 - value), 0),
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 12),
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
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => toggleTask(task),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              AnimatedContainer(
                                                duration: Duration(
                                                  milliseconds: 200,
                                                ),
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
                                                child: AnimatedDefaultTextStyle(
                                                  duration: Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: task.isCompleted
                                                        ? Colors.black38
                                                        : Colors.black87,
                                                    decoration: task.isCompleted
                                                        ? TextDecoration
                                                              .lineThrough
                                                        : null,
                                                    fontFamily: 'DM Sans',
                                                  ),
                                                  child: Text(task.title),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit_outlined,
                                                  color: Colors.blue
                                                      .withOpacity(0.7),
                                                ),
                                                onPressed: () => editTask(task),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red.withOpacity(
                                                    0.7,
                                                  ),
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
}
