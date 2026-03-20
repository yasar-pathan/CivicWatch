import 'dart:math';

class PasswordGenerator {
  static const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const _digits = '0123456789';
  static const _special = '@#%^*()-_=+!';

  static String generate({int length = 12}) {
    if (length < 8) {
      throw ArgumentError('Password length must be at least 8.');
    }

    final random = Random.secure();
    final all = '$_upper$_lower$_digits$_special';
    final chars = <String>[
      _upper[random.nextInt(_upper.length)],
      _lower[random.nextInt(_lower.length)],
      _digits[random.nextInt(_digits.length)],
      _special[random.nextInt(_special.length)],
    ];

    for (int i = chars.length; i < length; i++) {
      chars.add(all[random.nextInt(all.length)]);
    }

    chars.shuffle(random);
    return chars.join();
  }
}
