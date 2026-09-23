import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/api_service.dart';
import '../services/alarm_service.dart';
import '../theme/app_theme.dart';

class RemindersScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String? createdBy;
  final bool isCaretakerViewing;
  final bool isBengali;

  const RemindersScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.createdBy,
    this.isCaretakerViewing = false,
    this.isBengali = false,
  });

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<PatientReminder> _reminders = [];
  bool _isLoading = true;
  String _selectedCategoryFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadReminders();
    AlarmService.instance.initialize();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getPatientReminders(widget.patientId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success && result.data != null) {
        _reminders = result.data!;
      }
    });
  }

  List<PatientReminder> get _filteredReminders {
    if (_selectedCategoryFilter == 'ALL') return _reminders;
    return _reminders.where((r) => r.category == _selectedCategoryFilter).toList();
  }

  void _showAddReminderSheet({PatientReminder? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final voiceMsgController = TextEditingController(text: existing?.voiceMessage ?? '');
    String selectedCategory = existing?.category ?? 'MEDICINE';
    TimeOfDay selectedTime = existing != null
        ? TimeOfDay(
            hour: int.tryParse(existing.reminderTime.split(':')[0]) ?? 8,
            minute: int.tryParse(existing.reminderTime.split(':')[1]) ?? 0,
          )
        : const TimeOfDay(hour: 8, minute: 30);
    String selectedLang = existing?.voiceLanguage ?? (widget.isBengali ? 'bn' : 'en');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isBn = selectedLang == 'bn';

          void updateDefaultVoice() {
            if (titleController.text.trim().isEmpty) return;
            if (selectedCategory == 'MEDICINE') {
              voiceMsgController.text = isBn
                  ? "ওষুধ খাওয়ার সময় হয়েছে। দয়া করে ${titleController.text.trim()} গ্রহণ করুন।"
                  : "Hello ${widget.patientName.split(' ').first}! Time for your medicine: ${titleController.text.trim()} with water.";
            } else if (selectedCategory == 'FOOD') {
              voiceMsgController.text = isBn
                  ? "খাবার খাওয়ার সময় হয়েছে: ${titleController.text.trim()}।"
                  : "Meal reminder for ${widget.patientName.split(' ').first}: ${titleController.text.trim()} time!";
            } else if (selectedCategory == 'SLEEP') {
              voiceMsgController.text = isBn
                  ? "ঘুমানোর সময় হয়েছে। শান্তিতে ঘুমান।"
                  : "Bedtime reminder: Time to wind down and get a restful sleep.";
            } else if (selectedCategory == 'WATER') {
              voiceMsgController.text = isBn
                  ? "জল পান করার সময় হয়েছে। হাইড্রেটেড থাকুন।"
                  : "Time for a glass of water. Stay hydrated and healthy!";
            }
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing != null
                            ? (isBn ? "রিমাইন্ডার সম্পাদনা" : "Edit Alarm / Reminder")
                            : (isBn ? "নতুন রুটিন অ্যালার্ম যোগ করুন" : "Set Routine Alarm"),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Category Chips
                  Text(
                    isBn ? "বিভাগ নির্বাচন করুন (Category):" : "Select Category:",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip(
                          label: "💊 Medicine",
                          category: 'MEDICINE',
                          color: Colors.teal,
                          isSelected: selectedCategory == 'MEDICINE',
                          onTap: () {
                            setSheetState(() => selectedCategory = 'MEDICINE');
                            updateDefaultVoice();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: "🍽️ Food / Meal",
                          category: 'FOOD',
                          color: Colors.orange.shade700,
                          isSelected: selectedCategory == 'FOOD',
                          onTap: () {
                            setSheetState(() => selectedCategory = 'FOOD');
                            updateDefaultVoice();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: "🛌 Sleep",
                          category: 'SLEEP',
                          color: Colors.indigoAccent,
                          isSelected: selectedCategory == 'SLEEP',
                          onTap: () {
                            setSheetState(() => selectedCategory = 'SLEEP');
                            updateDefaultVoice();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: "💧 Water",
                          category: 'WATER',
                          color: Colors.blue,
                          isSelected: selectedCategory == 'WATER',
                          onTap: () {
                            setSheetState(() => selectedCategory = 'WATER');
                            updateDefaultVoice();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. Title / Reminder Name
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    onChanged: (_) => setSheetState(() => updateDefaultVoice()),
                    decoration: InputDecoration(
                      labelText: isBn ? "রিমাইন্ডারের নাম / ওষুধ" : "Reminder Title / Medicine Name",
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: selectedCategory == 'MEDICINE'
                          ? "e.g. Morning Blood Pressure Pill"
                          : selectedCategory == 'FOOD'
                              ? "e.g. Lunch with Low Sodium"
                              : "e.g. Night Bedtime",
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.edit_calendar_rounded, color: Colors.tealAccent),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Time Picker Selector
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setSheetState(() => selectedTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.tealAccent.shade400, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded, color: Colors.tealAccent, size: 28),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBn ? "অ্যালার্মের সময় (Time)" : "Scheduled Alarm Time",
                                style: const TextStyle(fontSize: 12, color: Colors.white60),
                              ),
                              Text(
                                selectedTime.format(context),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.tealAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text("Change", style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Voice Announcement Preview & Language Toggle
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.record_voice_over_rounded, color: Colors.cyanAccent, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Voice Announcement",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent, fontSize: 14),
                                ),
                              ],
                            ),
                            // Language Chip Toggle
                            GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  selectedLang = selectedLang == 'en' ? 'bn' : 'en';
                                  updateDefaultVoice();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  selectedLang == 'bn' ? "বাংলা (BN)" : "English (EN)",
                                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: voiceMsgController,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: "Spoken voice message when alarm sounds...",
                            hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                            border: InputBorder.none,
                          ),
                        ),
                        const Divider(color: Colors.white10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              final dummy = PatientReminder(
                                reminderId: 'test',
                                patientId: widget.patientId,
                                title: titleController.text.trim().isNotEmpty ? titleController.text.trim() : 'Test Reminder',
                                category: selectedCategory,
                                reminderTime: "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                                voiceMessage: voiceMsgController.text.trim(),
                                voiceLanguage: selectedLang,
                              );
                              AlarmService.instance.speakReminder(dummy);
                            },
                            icon: const Icon(Icons.volume_up_rounded, color: Colors.cyanAccent, size: 18),
                            label: const Text("🔊 Test Spoken Voice", style: TextStyle(color: Colors.cyanAccent)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. Save Button
                  ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter a title for the alarm")),
                              );
                              return;
                            }

                            setSheetState(() => isSaving = true);
                            final timeStr =
                                "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";

                            final res = await ApiService.createReminder(
                              patientId: widget.patientId,
                              createdBy: widget.createdBy,
                              title: title,
                              category: selectedCategory,
                              reminderTime: timeStr,
                              voiceMessage: voiceMsgController.text.trim().isNotEmpty
                                  ? voiceMsgController.text.trim()
                                  : null,
                              voiceLanguage: selectedLang,
                            );

                            if (!mounted) return;
                            Navigator.pop(ctx);
                            _loadReminders();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.success
                                    ? "⏰ Alarm saved for $timeStr (${widget.patientName})"
                                    : res.message),
                                backgroundColor: res.success ? Colors.teal : Colors.red,
                              ),
                            );
                          },
                    icon: const Icon(Icons.alarm_add_rounded),
                    label: Text(
                      existing != null ? "Update Alarm" : "Save & Activate Alarm",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required String category,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.white24, width: isSelected ? 2 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBengali;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? "দৈনন্দিন রুটিন ও রিমাইন্ডার" : "Routine Alarms & Reminders"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReminders,
            tooltip: "Refresh Alarms",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderSheet(),
        backgroundColor: const Color(0xFF0D9488),
        icon: const Icon(Icons.alarm_add_rounded, color: Colors.white),
        label: Text(
          isBn ? "নতুন অ্যালার্ম" : "+ Add Alarm",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.schedule_rounded, color: Colors.tealAccent, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isCaretakerViewing
                                      ? "Alarms for ${widget.patientName}"
                                      : "Daily Health Schedule",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.isCaretakerViewing
                                      ? "Reminders set here will ring and speak aloud on the patient's phone."
                                      : "Audible voice reminders for your medicine, meals, and sleep routine.",
                                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Filter Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterTab("ALL", isBn ? "সব (All)" : "All (${_reminders.length})"),
                            const SizedBox(width: 8),
                            _buildFilterTab("MEDICINE", "💊 Medicine"),
                            const SizedBox(width: 8),
                            _buildFilterTab("FOOD", "🍽️ Food"),
                            const SizedBox(width: 8),
                            _buildFilterTab("SLEEP", "🛌 Sleep"),
                            const SizedBox(width: 8),
                            _buildFilterTab("WATER", "💧 Water"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Reminders List
                Expanded(
                  child: _filteredReminders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.alarm_off_rounded, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                isBn ? "কোনো অ্যালার্ম নেই" : "No active alarms scheduled",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isBn
                                    ? "ওষুধ বা খাবারের রিমাইন্ডার যোগ করতে নিচে ক্লিক করুন"
                                    : "Tap '+ Add Alarm' below to set your daily voice routines",
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                          itemCount: _filteredReminders.length,
                          itemBuilder: (context, idx) {
                            final item = _filteredReminders[idx];
                            return _buildReminderCard(item);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterTab(String category, String label) {
    final isSelected = _selectedCategoryFilter == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryFilter = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.white12,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(PatientReminder item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: item.isActive ? item.color.withOpacity(0.4) : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Icon Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.isActive ? item.color.withOpacity(0.15) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.icon,
                color: item.isActive ? item.color : Colors.grey,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.reminderTime,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: item.isActive ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: item.isActive ? AppTheme.textPrimary : Colors.grey,
                    ),
                  ),
                  if (item.voiceMessage.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.volume_up_rounded, size: 14, color: Colors.teal),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.voiceMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Actions Wrap: Speak Test, Trigger Alarm Modal, Delete
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      // Voice Preview Action
                      InkWell(
                        onTap: () => AlarmService.instance.speakReminder(item),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.play_circle_fill_rounded, size: 16, color: Colors.teal),
                              SizedBox(width: 4),
                              Text("Hear Voice", style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),

                      // Test Ring Modal
                      InkWell(
                        onTap: () => AlarmService.instance.triggerAlarmPopup(
                          context: context,
                          reminder: item,
                          onStatusChanged: _loadReminders,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.notifications_active_rounded, size: 16, color: Colors.deepOrange),
                              SizedBox(width: 4),
                              Text("Test Alarm", style: TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),

                      // Delete Button
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text("Delete Alarm?"),
                              content: Text("Are you sure you want to delete '${item.title}'?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await ApiService.deleteReminder(item.reminderId);
                            _loadReminders();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Active Switch
            Switch(
              value: item.isActive,
              activeColor: item.color,
              onChanged: (val) async {
                setState(() => item.isActive = val);
                await ApiService.updateReminderStatus(
                  reminderId: item.reminderId,
                  active: val,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
