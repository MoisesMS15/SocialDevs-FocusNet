import 'package:flutter/material.dart';
import 'package:focusnet/pages/task_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:focusnet/pages/mytasks_page.dart';
import 'package:focusnet/pages/myinvitations_page.dart';

class CalendarPage extends StatefulWidget {
  static const String routeName = '/calendar';
  final int userId;

  const CalendarPage({super.key, required this.userId});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<Map<String, dynamic>> tasks = [];
  Map<int, Map<String, dynamic>> calendarData = {};
  DateTime selectedDate = DateTime.now();
  CalendarFormat calendarFormat = CalendarFormat.month;
  Set<DateTime> taskDays = {};
  Map<DateTime, int> taskCountByDay = {};

  @override
  void initState() {
    super.initState();
    fetchTasks();
    fetchCalendarData();
  }

  /// Obtiene las tareas del endpoint task/get_tasks
  Future<void> fetchTasks() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://focusnet-task-service-194080380757.southamerica-west1.run.app/task/list_user_tasks/${widget.userId}'),
        headers: {'accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        List<Map<String, dynamic>> loadedTasks =
            List<Map<String, dynamic>>.from(json.decode(response.body));
        setState(() {
          tasks = loadedTasks;
          updateTaskDays();
        });
      } else {
        throw Exception('Error al cargar las tareas');
      }
    } catch (e) {
      print('Error al obtener tareas: $e');
    }
  }

  /// Obtiene la información del calendario desde el endpoint calendar/get_calendar
  Future<void> fetchCalendarData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://focusnet-task-service-194080380757.southamerica-west1.run.app/calendar/get_calendar'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          calendarData = {for (var item in data) item['CalendarID']: item};
          updateTaskDays();
        });
      } else {
        throw Exception('Error al cargar datos del calendario');
      }
    } catch (e) {
      print('Error al obtener datos del calendario: $e');
    }
  }

  /// Actualiza los días que tienen tareas y cuántas tareas hay en cada uno
  void updateTaskDays() {
    Map<DateTime, int> tempTaskCount = {};

    for (var task in tasks) {
      int? calendarID = task['StartTimestampID'];
      if (calendarID != null && calendarData.containsKey(calendarID)) {
        DateTime taskDate = DateTime(
          calendarData[calendarID]!['Year'],
          calendarData[calendarID]!['Month'],
          calendarData[calendarID]!['Day'],
        );

        DateTime normalizedDate = DateTime(taskDate.year, taskDate.month,
            taskDate.day); // Normalizar sin horas
        tempTaskCount[normalizedDate] =
            (tempTaskCount[normalizedDate] ?? 0) + 1;
      }
    }

    setState(() {
      taskCountByDay = tempTaskCount;
    });
  }

  /// Filtra y ordena las tareas por la fecha seleccionada
  List<Map<String, dynamic>> getFilteredTasks() {
    return tasks.where((task) {
      int? calendarID = task['StartTimestampID'];
      if (calendarID != null && calendarData.containsKey(calendarID)) {
        DateTime taskDate = DateTime(
          calendarData[calendarID]!['Year'],
          calendarData[calendarID]!['Month'],
          calendarData[calendarID]!['Day'],
        );
        return isSameDay(taskDate, selectedDate);
      }
      return false;
    }).toList()
      ..sort((a, b) {
        int calendarA = a['StartTimestampID'] ?? -1;
        int calendarB = b['StartTimestampID'] ?? -1;

        int hourA = calendarData[calendarA]?['Hour'] ?? 23;
        int minuteA = calendarData[calendarA]?['Minute'] ?? 59;
        int hourB = calendarData[calendarB]?['Hour'] ?? 23;
        int minuteB = calendarData[calendarB]?['Minute'] ?? 59;

        return (hourA * 60 + minuteA).compareTo(hourB * 60 + minuteB);
      });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredTasks = getFilteredTasks();

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              color: Color(0xFF882ACB),
              child: const Center(
                child: Text(
                  "Mi Calendario",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: 180,
                height: 42,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF512DA8),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MytasksPage(userId: widget.userId),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.task,
                    color: Colors.white,
                    size: 20.0,
                  ),
                  label: Text(
                    "Actividades",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              Container(
                width: 180,
                height: 42,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF512DA8),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MyinvitationsPage(userId: widget.userId),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.mail,
                    color: Colors.white,
                    size: 20.0,
                  ),
                  label: Text(
                    "Invitaciones",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              )
            ],
          ),

          /// Calendario para seleccionar fecha
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16.0),
            child: TableCalendar(
              focusedDay: selectedDate,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              calendarFormat: calendarFormat,
              selectedDayPredicate: (day) => isSameDay(selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  selectedDate = selectedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  calendarFormat = format;
                });
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                formatButtonTextStyle: const TextStyle(color: Colors.white),
                leftChevronIcon:
                    const Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon:
                    const Icon(Icons.chevron_right, color: Colors.white),
                formatButtonDecoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: const Color.fromRGBO(183, 127, 224, 0.7),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF882ACB),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              /// Muestra un indicador en los días con tareas
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  DateTime normalizedDate =
                      DateTime(date.year, date.month, date.day);
                  if (taskCountByDay.containsKey(normalizedDate)) {
                    int taskCount = taskCountByDay[normalizedDate]!;
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 95, 207, 198),
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$taskCount', // Mostrar el número de tareas
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),

          /// Lista de tareas
          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(child: Text('No hay tareas para esta fecha'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      return buildTaskCard(filteredTasks[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Construye la tarjeta de cada tarea
  Widget buildTaskCard(Map<String, dynamic> task) {
    int calendarID = task['StartTimestampID'] ?? -1;
    int hour = calendarData[calendarID]?['Hour'] ?? 23;
    int minute = calendarData[calendarID]?['Minute'] ?? 59;

    // Definir el color según la prioridad de la tarea
    Color containerColor;
    switch (task['Priority']) {
      case 0:
        containerColor = Colors.amber.shade700; // Prioridad 0 -> Amarillo
        break;
      case 1:
        containerColor = Colors.deepOrange; // Prioridad 1 -> Naranja
        break;
      case 2:
        containerColor = Colors.red.shade800; // Prioridad 2 -> Rojo
        break;
      default:
        containerColor = const Color.fromARGB(
            255, 66, 148, 241); // Si no tiene prioridad, blanco
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskPage(task: task),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color:
                containerColor, // Establecer el color de fondo según la prioridad
            borderRadius: BorderRadius.circular(
                12), // Bordes redondeados con un radio de 16
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.event, color: Colors.white), // Ícono de actividad
                Text(
                  task['Title'] ?? 'Sin título',
                  style: TextStyle(
                      fontSize: 18, color: Colors.white), // Texto blanco
                ),
                Text(
                  "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white), // Texto blanco
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
