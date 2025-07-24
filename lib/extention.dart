class TimeFormatter {
  static String formatMessageTime(DateTime dateTime) {
    int hour = dateTime.hour;
    int minute = dateTime.minute;

    String period = hour >= 12 ? 'PM' : 'AM';

    // Convert to 12-hour format
    if (hour > 12) {
      hour = hour - 12;
    } else if (hour == 0) {
      hour = 12;
    }

    // Add leading zero to minutes if needed
    String minuteStr = minute.toString().padLeft(2, '0');

    return '$hour:$minuteStr $period';
  }

  // Optional: Format with date if message is from different day
  static String formatMessageTimeWithDate(DateTime dateTime) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime messageDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    if (messageDate == today) {
      return formatMessageTime(dateTime); // Just time for today
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday ${formatMessageTime(dateTime)}'; // Yesterday with time
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${formatMessageTime(dateTime)}';
    }
  }
}
