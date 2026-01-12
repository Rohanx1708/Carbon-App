import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/meeting/data/meeting_service.dart';

class MeetingDetailScreen extends StatelessWidget {
  final Meeting meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  String _typeLabel(String type) {
    return type.replaceFirst(RegExp(r'^With\s+', caseSensitive: false), '').trim();
  }

  String _dateTimeLabel(DateTime dt) => DateFormat('d MMM yyyy, h:mm a').format(dt);

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, {required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = _typeLabel(meeting.type);
    final location = (meeting.location ?? '').trim();
    final notes = (meeting.notes ?? '').trim();
    final other = (meeting.otherMeeting ?? '').trim();

    final related = <String>[];
    if ((meeting.lead ?? '').trim().isNotEmpty) related.add('Lead: ${meeting.lead!.trim()}');
    if ((meeting.client ?? '').trim().isNotEmpty) related.add('Client: ${meeting.client!.trim()}');
    if (meeting.team.isNotEmpty) related.add('Team: ${meeting.team.join(', ')}');
    if (other.isNotEmpty) related.add('Other: $other');

    return Scaffold(
      appBar: const GradientAppBar(title: 'Meeting Details'),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meeting.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha((0.12 * 255).round()),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withAlpha((0.22 * 255).round()),
                          ),
                        ),
                        child: Text(
                          typeLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryBlue,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionTitle('BASIC'),
                  _infoRow(context, label: 'Organizer', value: meeting.organizer),
                  if (related.isNotEmpty) _infoRow(context, label: 'With', value: related.join(' • ')),
                  _sectionTitle('SCHEDULE'),
                  _infoRow(context, label: 'Start', value: _dateTimeLabel(meeting.startDateTime)),
                  _infoRow(context, label: 'End', value: _dateTimeLabel(meeting.endDateTime)),
                  if (location.isNotEmpty) ...[
                    _sectionTitle('LOCATION'),
                    _infoRow(context, label: 'Place', value: location),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _card(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('AGENDA'),
                  Text(
                    meeting.agenda.trim().isEmpty ? '-' : meeting.agenda.trim(),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade900),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _sectionTitle('NOTES'),
                    Text(
                      notes,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade900),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _card(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('ATTACHMENTS'),
                  if (meeting.attachments.isEmpty)
                    Text(
                      'No attachments',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                    )
                  else
                    ...meeting.attachments.map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.accentGreen.withAlpha((0.14 * 255).round()),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.attach_file, size: 18, color: AppTheme.accentGreen),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.grey.shade900,
                                    ),
                                  ),
                                  if ((a.path ?? '').trim().isNotEmpty)
                                    Text(
                                      a.path!.trim(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
