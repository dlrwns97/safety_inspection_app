import 'package:flutter/material.dart';

class MarkerDetailSection extends StatelessWidget {
  const MarkerDetailSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final List<MarkerDetailRowData> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerTitleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final headerSubtitleStyle = theme.textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: headerTitleStyle),
          const SizedBox(height: 4),
          Text(subtitle, style: headerSubtitleStyle),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text(
              '표시할 상세 정보가 없습니다.',
              style: theme.textTheme.bodyMedium,
            )
          else
            ...rows.map((row) => MarkerDetailRow(row: row)),
        ],
      ),
    );
  }
}

class MarkerDetailRowData {
  const MarkerDetailRowData(this.label, this.value);

  final String label;
  final String value;
}

class MarkerDetailRow extends StatelessWidget {
  const MarkerDetailRow({
    super.key,
    required this.row,
  });

  final MarkerDetailRowData row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              row.label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.value,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
