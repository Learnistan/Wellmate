import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:wellmate/core/theme/colors.dart';
import '../../../../core/theme/textStyles.dart';
import '../providers/activityProvider.dart';

class MovementActivityPage extends StatefulWidget {
  const MovementActivityPage({super.key});

  @override
  State<MovementActivityPage> createState() => _MovementActivityPageState();
}

class _MovementActivityPageState extends State<MovementActivityPage> {
  // User-selectable duration in minutes. Minimum 1 minute.
  static const int minMinutes = 1;
  static const int maxMinutes = 120;

  int _selectedMinutes = 15;
  int get _sessionDuration => _selectedMinutes * 60;

  Timer? _timer;
  int _remainingSeconds = 15 * 60;
  bool _isRunning = false;

  StreamSubscription<StepCount>? _stepSubscription;
  int? _baselineSteps;
  int _sessionSteps = 0;

  static const double _strideLengthMeters = 0.78;
  static const double _weightKg = 70;

  double get _distanceKm => _sessionSteps * _strideLengthMeters / 1000;

  int get _elapsedSeconds => _sessionDuration - _remainingSeconds;

  double get _paceMinPerKm =>
      _distanceKm > 0 ? (_elapsedSeconds / 60) / _distanceKm : 0;

  double get _caloriesBurned => _distanceKm * _weightKg * 0.53;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _sessionDuration;
  }

  Future<void> _startSession() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Motion permission is required')),
        );
      }
      return;
    }

    _stepSubscription ??= Pedometer.stepCountStream.listen(
          (event) {
        _baselineSteps ??= event.steps;
        if (_isRunning) {
          setState(() {
            _sessionSteps = event.steps - _baselineSteps!;
          });
        }
      },
      onError: (e) => debugPrint('Pedometer error: $e'),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _showSessionFinishedDialog();
      } else {
        setState(() => _remainingSeconds--);
      }
    });

    setState(() => _isRunning = true);
  }

  void _pauseSession() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _stopSession() {
    _timer?.cancel();
    _stepSubscription?.cancel();
    _stepSubscription = null;

    setState(() {
      _isRunning = false;
      _remainingSeconds = _sessionDuration;
      _baselineSteps = null;
      _sessionSteps = 0;
    });
  }

  void _showSessionFinishedDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text(
            "You completed your daily walking goal. \nGreat job!",
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<ActivityProvider>().saveActivityLog(
                  activityId: 2,
                  value:
                  '{"distance":${_distanceKm.toStringAsFixed(2)}, "calories":${_caloriesBurned.toStringAsFixed(0)}}',
                );
                Navigator.of(context).pop();
                _stopSession();
                context.pop("activity completed");
              },
              child: const Text('Awesome'),
            ),
          ],
        );
      },
    );
  }

  void _showDurationPicker() {
    int tempMinutes = _selectedMinutes;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final locale = Localizations.localeOf(context);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choose duration',
                    style: AppTextStyles.semiBold(locale).copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '$tempMinutes min',
                    style:
                    AppTextStyles.semiBold(locale).copyWith(fontSize: 40),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        iconSize: 36,
                        color: AppColors.primary,
                        onPressed: tempMinutes > minMinutes
                            ? () => setSheetState(() => tempMinutes--)
                            : null,
                        icon: const Icon(Icons.remove_circle),
                      ),
                      Expanded(
                        child: Slider(
                          value: tempMinutes.toDouble(),
                          min: minMinutes.toDouble(),
                          max: maxMinutes.toDouble(),
                          divisions: maxMinutes - minMinutes,
                          activeColor: AppColors.primary,
                          label: '$tempMinutes min',
                          onChanged: (v) =>
                              setSheetState(() => tempMinutes = v.round()),
                        ),
                      ),
                      IconButton(
                        iconSize: 36,
                        color: AppColors.primary,
                        onPressed: tempMinutes < maxMinutes
                            ? () => setSheetState(() => tempMinutes++)
                            : null,
                        icon: const Icon(Icons.add_circle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: [1, 5, 10, 15, 30, 45, 60].map((m) {
                      final selected = tempMinutes == m;
                      return ChoiceChip(
                        label: Text('$m'),
                        selected: selected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : null,
                        ),
                        onSelected: (_) =>
                            setSheetState(() => tempMinutes = m),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedMinutes = tempMinutes;
                          _remainingSeconds = _sessionDuration;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Set'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String get _formattedTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _formattedPace {
    if (_paceMinPerKm == 0) return '--';
    final m = _paceMinPerKm.floor();
    final s = ((_paceMinPerKm - m) * 60).round().toString().padLeft(2, '0');
    return "$m'$s\" /km";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stepSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    // Allow changing duration only when nothing is in progress.
    final canChangeDuration = !_isRunning && _elapsedSeconds == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Mindful Movement',
          style: AppTextStyles.semiBold(locale).copyWith(fontSize: 20),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${_distanceKm.toStringAsFixed(2)} km',
              textAlign: TextAlign.center,
              style: AppTextStyles.semiBold(locale).copyWith(fontSize: 64),
            ),

            const SizedBox(height: 20),

            Text(
              _formattedTime,
              textAlign: TextAlign.center,
              style: AppTextStyles.introTitle(locale),
            ),

            const SizedBox(height: 12),

            // Duration selector
            Center(
              child: GestureDetector(
                onTap: canChangeDuration ? _showDurationPicker : null,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: canChangeDuration
                          ? AppColors.primary
                          : AppColors.appGray,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: canChangeDuration
                            ? AppColors.primary
                            : AppColors.appGray,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Duration: $_selectedMinutes min',
                        style: TextStyle(
                          color: canChangeDuration
                              ? AppColors.primary
                              : AppColors.appGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(35)),
                border: Border.all(color: AppColors.appGray, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatTile(label: 'Avg pace', value: _formattedPace),
                  Container(
                    width: 1.5,
                    height: 80,
                    decoration: BoxDecoration(color: AppColors.appGray),
                  ),
                  _StatTile(
                    label: 'Calories',
                    value: '${_caloriesBurned.toStringAsFixed(0)} kcal',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 80,
                  width: 80,
                  child: ElevatedButton(
                    onPressed: _isRunning ? _pauseSession : _startSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                SizedBox(
                  height: 80,
                  width: 80,
                  child: ElevatedButton(
                    onPressed: (_isRunning || _elapsedSeconds > 0)
                        ? _stopSession
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[800],
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: const Icon(Icons.stop, size: 30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}