import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_service.dart';

class TaskService extends ChangeNotifier {
  List<UserMissionModel> _dailyTasks = [];
  List<UserMissionModel> _weeklyTasks = [];
  List<UserMissionModel> _milestones = [];

  List<UserMissionModel> get dailyTasks => _dailyTasks;
  List<UserMissionModel> get weeklyTasks => _weeklyTasks;
  List<UserMissionModel> get milestones => _milestones;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> refreshMissions(ApiService apiService) async {
    _isLoading = true;
    notifyListeners();
    try {
      final dailyJson = await apiService.getDailyMissions();
      final weeklyJson = await apiService.getWeeklyMissions();
      final milestoneJson = await apiService.getMilestones();

      _dailyTasks = dailyJson.map((j) => UserMissionModel.fromJson(j)).toList();
      _weeklyTasks = weeklyJson.map((j) => UserMissionModel.fromJson(j)).toList();
      _milestones = milestoneJson.map((j) => UserMissionModel.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error refreshing missions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeMission(ApiService apiService, int userMissionId) async {
    try {
      await apiService.completeMission(userMissionId);
      await refreshMissions(apiService);
    } catch (e) {
      debugPrint('Error completing mission: $e');
      rethrow;
    }
  }
}
