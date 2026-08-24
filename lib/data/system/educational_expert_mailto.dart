/// Builds a mailto URI that is interoperable with mail applications which do
/// not translate query-string plus signs back to spaces.
Uri buildEducationalExpertMailto({
  required String subject,
  required String body,
}) {
  String encode(String value) =>
      Uri.encodeComponent(value).replaceAll('+', '%20');

  return Uri.parse(
    'mailto:3ialna.app@gmail.com?subject=${encode(subject)}&body=${encode(body)}',
  );
}
