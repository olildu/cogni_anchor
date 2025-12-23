import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:cogni_anchor/data/models/reminder_model.dart';
import 'package:cogni_anchor/data/services/notification_service.dart';
import 'package:cogni_anchor/data/services/reminder_supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'reminder_event.dart';
part 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  static const String _nameTag = 'ReminderBloc';

  final ReminderSupabaseService _supabaseService = ReminderSupabaseService();
  final SupabaseClient _client = Supabase.instance.client;

  ReminderBloc() : super(ReminderInitial()) {
    on<LoadReminders>(_onLoadReminders);
    on<AddReminder>(_onAddReminder);
    on<DeleteReminder>(_onDeleteReminder);
  }

  Future<String?> _getPairId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final patient = await _client
        .from('pairs')
        .select('id')
        .eq('patient_user_id', user.id)
        .maybeSingle();

    if (patient != null) return patient['id'].toString();

    final caretaker = await _client
        .from('pairs')
        .select('id')
        .eq('caretaker_user_id', user.id)
        .maybeSingle();

    return caretaker?['id']?.toString();
  }

  Future<void> _onLoadReminders(
    LoadReminders event,
    Emitter<ReminderState> emit,
  ) async {
    emit(ReminderLoading());

    try {
      final pairId = await _getPairId();
      if (pairId == null) {
        emit(const ReminderError("No patient connected"));
        return;
      }

      final reminders = await _supabaseService.getReminders(pairId);
      final now = DateTime.now();
      final format = DateFormat("dd MMM yyyy hh:mm a");

      final List<Reminder> upcoming = [];
      final List<Reminder> expired = [];

      for (final r in reminders) {
        final dt = format.parse("${r.date} ${r.time}");
        if (dt.isBefore(now)) {
          expired.add(r);
        } else {
          upcoming.add(r);
        }
      }

      for (final r in expired) {
        await _supabaseService.deleteReminder(r.id);
      }

      upcoming.sort((a, b) {
        final aDate = format.parse("${a.date} ${a.time}");
        final bDate = format.parse("${b.date} ${b.time}");
        return aDate.compareTo(bDate);
      });

      final next = upcoming.isNotEmpty ? upcoming.first : null;
      final rest = upcoming.where((r) => r != next).toList();

      emit(RemindersLoaded(rest, next));
    } catch (e, st) {
      log("Load error: $e", name: _nameTag);
      log("Stacktrace: $st", name: _nameTag);
      emit(const ReminderError("Failed to load reminders"));
    }
  }

  Future<void> _onAddReminder(
    AddReminder event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      final pairId = await _getPairId();
      if (pairId == null) {
        emit(const ReminderError("No patient connected"));
        return;
      }

      final scheduledDate =
          _parseDate(event.reminder.date, event.reminder.time);

      if (!scheduledDate.isAfter(DateTime.now())) {
        emit(const ReminderError("Cannot set reminder in the past"));
        return;
      }

      await _supabaseService.createReminder(
        reminder: event.reminder,
        pairId: pairId,
      );

      final delay = scheduledDate.difference(DateTime.now());
      final notificationId =
          scheduledDate.millisecondsSinceEpoch.remainder(100000);

      await NotificationService().scheduleAfterDuration(
        id: notificationId,
        title: "Reminder",
        body: event.reminder.title,
        delay: delay,
      );

      add(LoadReminders());
    } catch (e, st) {
      log("Add error: $e", name: _nameTag);
      log("Stacktrace: $st", name: _nameTag);
      emit(const ReminderError("Failed to add reminder"));
    }
  }

  Future<void> _onDeleteReminder(
    DeleteReminder event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      await _supabaseService.deleteReminder(event.reminder.id);

      final notificationId =
          _parseDate(event.reminder.date, event.reminder.time)
              .millisecondsSinceEpoch
              .remainder(100000);

      await NotificationService().cancel(notificationId);

      add(LoadReminders());
    } catch (e, st) {
      log("Delete error: $e", name: _nameTag);
      log("Stacktrace: $st", name: _nameTag);
      emit(const ReminderError("Failed to delete reminder"));
    }
  }

  DateTime _parseDate(String date, String time) {
    final format = DateFormat("dd MMM yyyy hh:mm a");
    return format.parse("$date $time");
  }
}
