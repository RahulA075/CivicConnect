import 'package:flutter_test/flutter_test.dart';

import 'package:civicconnect/core/utils/validators.dart';

void main() {
  group('Validators.password matches backend RegisterRequest policy', () {
    test('accepts a compliant password', () {
      expect(Validators.password('SecurePass@1'), isNull);
    });

    test('rejects passwords the backend would reject', () {
      expect(Validators.password('Secure@1'), isNotNull); // < 10 chars
      expect(Validators.password('securepass@1'), isNotNull); // no uppercase
      expect(Validators.password('SECUREPASS@1'), isNotNull); // no lowercase
      expect(Validators.password('SecurePass@'), isNotNull); // no digit
      expect(Validators.password('SecurePass12'), isNotNull); // no symbol
    });
  });
}
