DateTime? parseApiDateTime(dynamic value) {
  if (value == null) return null;

  final parsed = value is DateTime
      ? value
      : DateTime.tryParse(value.toString());

  return parsed?.toLocal();
}
