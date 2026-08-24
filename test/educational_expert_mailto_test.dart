import 'package:flutter_test/flutter_test.dart';

import 'package:mu_super_app/data/system/educational_expert_mailto.dart';

void main() {
  test('encodes email draft spaces as percent escapes instead of plus signs', () {
    final Uri uri = buildEducationalExpertMailto(
      subject: 'طلب تواصل مع خبير تربوى',
      body: 'Mobile number: 555 0100\nNeed help today',
    );

    expect(uri.toString(), contains('%20'));
    expect(uri.toString(), isNot(contains('+')));
    expect(uri.queryParameters['body'], 'Mobile number: 555 0100\nNeed help today');
  });
}
