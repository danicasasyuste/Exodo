import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import '../models/calendar_event.dart';
import '../services/weather_service.dart';
import '../services/notification_service.dart';
import '../models/weather.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  final List<Event> _events = [];
  final WeatherService _weatherService = WeatherService();
  final String _city = 'Madrid';
  final Logger _logger = Logger();
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;
  late bool isNight;
  late Color fondo;
  late Color card;
  late Color texto;
  late Color icono;
  late Color sombra;

  @override
  void initState() {
    super.initState();

    _loadEvents();

    isNight = DateTime.now().hour >= 20 || DateTime.now().hour < 6;
    fondo = isNight ? const Color(0xFF0D1B2A) : const Color(0xFFE6F0FA);
    card = isNight ? const Color(0xFF1B263B) : Colors.white;
    texto = isNight ? const Color(0xFFE0E1DD) : Colors.black87;
    icono = isNight ? const Color(0xFFA5B3C5) : Colors.black87;
    sombra = isNight ? const Color.fromARGB(30, 65, 90, 119) : Colors.black12;

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }
    });
  }
  

void _loadEvents() async {
  final prefs = await SharedPreferences.getInstance();
  final String? storedData = prefs.getString('eventos');
  if (storedData != null) {
    final List decoded = json.decode(storedData);
    setState(() {
      _events.addAll(decoded.map((e) => Event(
        id: e['id'],
        date: DateTime.parse(e['date']),
        title: e['title'],
        description: e['description'],
      )));
    });
  }
}

void _saveEvents() async {
  final prefs = await SharedPreferences.getInstance();
  final List<Map<String, dynamic>> data = _events.map((e) => {
    'id': e.id,
    'date': e.date.toIso8601String(),
    'title': e.title,
    'description': e.description,
  }).toList();
  await prefs.setString('eventos', json.encode(data));
}

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  void _addEvent(DateTime date, String title, String description) {
    setState(() {
      final newEvent = Event(
        id: DateTime.now().toString(),
        date: date,
        title: title,
        description: description,
      );
      _events.add(newEvent);
      _saveEvents();
      _checkAndSendWeatherNotification(newEvent);
    });
  }

  void _removeEvent(Event event) {
    setState(() {
      _events.remove(event);
      _saveEvents();
    });
  }

  void _checkAndSendWeatherNotification(Event event) async {
    try {
      final forecast = await _weatherService.getForecast(_city);
      final targetDate = DateFormat('yyyy-MM-dd').format(event.date);
      for (final weather in forecast) {
        if (DateFormat('yyyy-MM-dd').format(weather.date) == targetDate) {
          if (weather.willRain || weather.isThunderstorm) {
            _sendWeatherNotification(event, weather);
          }
          break;
        }
      }
    } catch (e) {
      _logger.e('Error checking weather: $e');
    }
  }

  void _sendWeatherNotification(Event event, Weather weather) {
    final mensaje =
        'Habrá ${weather.willRain ? 'lluvia' : weather.isThunderstorm ? 'tormenta' : ''} el día ${DateFormat('dd/MM/yyyy').format(event.date)}. ¿Deseas mantener el evento?';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    NotificationService.notificarClimaEvento(event.id, _city, mensaje);
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events.where((event) => isSameDay(event.date, day)).toList();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        backgroundColor: fondo,
        foregroundColor: texto,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: icono),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month, size: 26, color: icono),
            const SizedBox(width: 8),
            Text(
              'CALENDARIO',
              style: TextStyle(
                color: texto,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TableCalendar<Event>(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay ?? DateTime.now(), day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) => setState(() => _calendarFormat = format),
                eventLoader: (day) => _getEventsForDay(day),
                calendarStyle: CalendarStyle(
                  isTodayHighlighted: true,
                  todayDecoration: BoxDecoration(
                    color: texto.withAlpha(350),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: isNight
                        ? const Color.fromARGB(255, 90, 130, 190)
                        : const Color.fromARGB(255, 116, 162, 241),
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: TextStyle(color: texto),
                  weekendTextStyle: TextStyle(color: texto.withAlpha(253)),
                  outsideTextStyle: TextStyle(color: texto.withAlpha(180)),
                  markerDecoration: const BoxDecoration(
                    color: Color.fromARGB(255, 170, 210, 139),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: texto,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  formatButtonVisible: false,
                  leftChevronIcon: Icon(Icons.chevron_left, color: texto),
                  rightChevronIcon: Icon(Icons.chevron_right, color: texto),
                ),
              ),
            ),
          ),
          if (_selectedDay != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Center(
                  child: Text(
                    DateFormat('EEEE, d MMMM', 'es_ES')
                        .format(_selectedDay!)
                        .toUpperCase(),
                    style: TextStyle(
                      color: texto,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          if (_selectedDay != null)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final event = _getEventsForDay(_selectedDay!)[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: sombra,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: TextStyle(
                                    color: texto,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  event.description,
                                  style: TextStyle(
                                    color: texto.withAlpha(130),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _removeEvent(event),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _getEventsForDay(_selectedDay!).length,
              ),
            ),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        offset: _isFabVisible ? Offset.zero : const Offset(0, 1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          opacity: _isFabVisible ? 1 : 0,
          child: Padding(
            padding: const EdgeInsets.only(left: 32.0, bottom: 16.0),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: FloatingActionButton(
                onPressed: _showAddEventDialog,
                backgroundColor: const Color.fromARGB(255, 116, 162, 241),
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddEventDialog() {
    String? title;
    String? description;

    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: isNight
                ? const ColorScheme.dark(
                    primary: Color.fromARGB(255, 116, 162, 241),
                    surface: Color(0xFF1B263B),
                    onSurface: Color(0xFFE0E1DD),
                  )
                : const ColorScheme.light(
                    primary: Color.fromARGB(255, 116, 162, 241),
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
            dialogTheme: DialogThemeData(
              backgroundColor: isNight ? const Color(0xFF1B263B) : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    ).then((pickedDate) {
      if (!mounted || pickedDate == null) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Agregar Evento', style: TextStyle(color: texto)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: TextStyle(color: texto),
                  decoration: InputDecoration(
                    labelText: 'Título',
                    labelStyle: TextStyle(color: texto.withAlpha(153)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: texto.withAlpha(100)),
                    ),
                  ),
                  onChanged: (value) => title = value,
                ),
                TextField(
                  style: TextStyle(color: texto),
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: TextStyle(color: texto.withAlpha(129)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: texto.withAlpha(120)),
                    ),
                  ),
                  onChanged: (value) => description = value,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (title != null && description != null) {
                    _addEvent(_selectedDay ?? pickedDate, title!, description!);
                    Navigator.pop(context);
                  }
                },
                child: Text('Agregar', style: TextStyle(color: const Color.fromARGB(255, 116, 162, 241))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar', style: TextStyle(color: texto)),
              ),
            ],
          );
        },
      );
    });
  }
}
