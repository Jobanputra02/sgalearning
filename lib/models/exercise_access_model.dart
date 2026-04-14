class ExerciseAccess {
  // Pitch Identification
  final bool ep_pi_1e;
  final bool ep_pi_1m;
  final bool ep_pi_1h;
  final bool ep_pi_2e;
  final bool ep_pi_2m;
  final bool ep_pi_2h;
  final bool ep_pi_3e;
  final bool ep_pi_3m;
  final bool ep_pi_3h;
  final bool ep_pi_exam123;
  final bool ep_pi_4e;
  final bool ep_pi_4m;
  final bool ep_pi_4h;
  final bool ep_pi_5e;
  final bool ep_pi_5m;
  final bool ep_pi_5h;
  final bool ep_pi_6e;
  final bool ep_pi_6m;
  final bool ep_pi_6h;
  final bool ep_pi_exam123456;

  // Note Identification
  final bool ep_ni_1;
  final bool ep_ni_12;
  final bool ep_ni_123;
  final bool ep_ni_exam123;
  final bool ep_ni_1234;
  final bool ep_ni_12345;
  final bool ep_ni_123456;
  final bool ep_ni_exam123456;

  const ExerciseAccess({
    this.ep_pi_1e         = false,
    this.ep_pi_1m         = false,
    this.ep_pi_1h         = false,
    this.ep_pi_2e         = false,
    this.ep_pi_2m         = false,
    this.ep_pi_2h         = false,
    this.ep_pi_3e         = false,
    this.ep_pi_3m         = false,
    this.ep_pi_3h         = false,
    this.ep_pi_exam123    = false,
    this.ep_pi_4e         = false,
    this.ep_pi_4m         = false,
    this.ep_pi_4h         = false,
    this.ep_pi_5e         = false,
    this.ep_pi_5m         = false,
    this.ep_pi_5h         = false,
    this.ep_pi_6e         = false,
    this.ep_pi_6m         = false,
    this.ep_pi_6h         = false,
    this.ep_pi_exam123456 = false,
    this.ep_ni_1          = false,
    this.ep_ni_12         = false,
    this.ep_ni_123        = false,
    this.ep_ni_exam123    = false,
    this.ep_ni_1234       = false,
    this.ep_ni_12345      = false,
    this.ep_ni_123456     = false,
    this.ep_ni_exam123456 = false,
  });

  // Default for new student — only first exercise unlocked
  factory ExerciseAccess.defaultStudent() {
    return const ExerciseAccess(
      ep_pi_1e: true,
      ep_ni_1:  true,
    );
  }

  // Full access for faculty and admin
  factory ExerciseAccess.fullAccess() {
    return const ExerciseAccess(
      ep_pi_1e:         true,
      ep_pi_1m:         true,
      ep_pi_1h:         true,
      ep_pi_2e:         true,
      ep_pi_2m:         true,
      ep_pi_2h:         true,
      ep_pi_3e:         true,
      ep_pi_3m:         true,
      ep_pi_3h:         true,
      ep_pi_exam123:    true,
      ep_pi_4e:         true,
      ep_pi_4m:         true,
      ep_pi_4h:         true,
      ep_pi_5e:         true,
      ep_pi_5m:         true,
      ep_pi_5h:         true,
      ep_pi_6e:         true,
      ep_pi_6m:         true,
      ep_pi_6h:         true,
      ep_pi_exam123456: true,
      ep_ni_1:          true,
      ep_ni_12:         true,
      ep_ni_123:        true,
      ep_ni_exam123:    true,
      ep_ni_1234:       true,
      ep_ni_12345:      true,
      ep_ni_123456:     true,
      ep_ni_exam123456: true,
    );
  }

  factory ExerciseAccess.fromMap(Map<String, dynamic> map) {
    return ExerciseAccess(
      ep_pi_1e:         map['EP_PI_1E']         ?? false,
      ep_pi_1m:         map['EP_PI_1M']         ?? false,
      ep_pi_1h:         map['EP_PI_1H']         ?? false,
      ep_pi_2e:         map['EP_PI_2E']         ?? false,
      ep_pi_2m:         map['EP_PI_2M']         ?? false,
      ep_pi_2h:         map['EP_PI_2H']         ?? false,
      ep_pi_3e:         map['EP_PI_3E']         ?? false,
      ep_pi_3m:         map['EP_PI_3M']         ?? false,
      ep_pi_3h:         map['EP_PI_3H']         ?? false,
      ep_pi_exam123:    map['EP_PI_Exam123']    ?? false,
      ep_pi_4e:         map['EP_PI_4E']         ?? false,
      ep_pi_4m:         map['EP_PI_4M']         ?? false,
      ep_pi_4h:         map['EP_PI_4H']         ?? false,
      ep_pi_5e:         map['EP_PI_5E']         ?? false,
      ep_pi_5m:         map['EP_PI_5M']         ?? false,
      ep_pi_5h:         map['EP_PI_5H']         ?? false,
      ep_pi_6e:         map['EP_PI_6E']         ?? false,
      ep_pi_6m:         map['EP_PI_6M']         ?? false,
      ep_pi_6h:         map['EP_PI_6H']         ?? false,
      ep_pi_exam123456: map['EP_PI_Exam123456'] ?? false,
      ep_ni_1:          map['EP_NI_1']          ?? false,
      ep_ni_12:         map['EP_NI_12']         ?? false,
      ep_ni_123:        map['EP_NI_123']        ?? false,
      ep_ni_exam123:    map['EP_NI_Exam123']    ?? false,
      ep_ni_1234:       map['EP_NI_1234']       ?? false,
      ep_ni_12345:      map['EP_NI_12345']      ?? false,
      ep_ni_123456:     map['EP_NI_123456']     ?? false,
      ep_ni_exam123456: map['EP_NI_Exam123456'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'EP_PI_1E':         ep_pi_1e,
    'EP_PI_1M':         ep_pi_1m,
    'EP_PI_1H':         ep_pi_1h,
    'EP_PI_2E':         ep_pi_2e,
    'EP_PI_2M':         ep_pi_2m,
    'EP_PI_2H':         ep_pi_2h,
    'EP_PI_3E':         ep_pi_3e,
    'EP_PI_3M':         ep_pi_3m,
    'EP_PI_3H':         ep_pi_3h,
    'EP_PI_Exam123':    ep_pi_exam123,
    'EP_PI_4E':         ep_pi_4e,
    'EP_PI_4M':         ep_pi_4m,
    'EP_PI_4H':         ep_pi_4h,
    'EP_PI_5E':         ep_pi_5e,
    'EP_PI_5M':         ep_pi_5m,
    'EP_PI_5H':         ep_pi_5h,
    'EP_PI_6E':         ep_pi_6e,
    'EP_PI_6M':         ep_pi_6m,
    'EP_PI_6H':         ep_pi_6h,
    'EP_PI_Exam123456': ep_pi_exam123456,
    'EP_NI_1':          ep_ni_1,
    'EP_NI_12':         ep_ni_12,
    'EP_NI_123':        ep_ni_123,
    'EP_NI_Exam123':    ep_ni_exam123,
    'EP_NI_1234':       ep_ni_1234,
    'EP_NI_12345':      ep_ni_12345,
    'EP_NI_123456':     ep_ni_123456,
    'EP_NI_Exam123456': ep_ni_exam123456,
  };

  // Check access by key string
  bool hasAccess(String key) {
    switch (key) {
      case 'EP_PI_1E':         return ep_pi_1e;
      case 'EP_PI_1M':         return ep_pi_1m;
      case 'EP_PI_1H':         return ep_pi_1h;
      case 'EP_PI_2E':         return ep_pi_2e;
      case 'EP_PI_2M':         return ep_pi_2m;
      case 'EP_PI_2H':         return ep_pi_2h;
      case 'EP_PI_3E':         return ep_pi_3e;
      case 'EP_PI_3M':         return ep_pi_3m;
      case 'EP_PI_3H':         return ep_pi_3h;
      case 'EP_PI_Exam123':    return ep_pi_exam123;
      case 'EP_PI_4E':         return ep_pi_4e;
      case 'EP_PI_4M':         return ep_pi_4m;
      case 'EP_PI_4H':         return ep_pi_4h;
      case 'EP_PI_5E':         return ep_pi_5e;
      case 'EP_PI_5M':         return ep_pi_5m;
      case 'EP_PI_5H':         return ep_pi_5h;
      case 'EP_PI_6E':         return ep_pi_6e;
      case 'EP_PI_6M':         return ep_pi_6m;
      case 'EP_PI_6H':         return ep_pi_6h;
      case 'EP_PI_Exam123456': return ep_pi_exam123456;
      case 'EP_NI_1':          return ep_ni_1;
      case 'EP_NI_12':         return ep_ni_12;
      case 'EP_NI_123':        return ep_ni_123;
      case 'EP_NI_Exam123':    return ep_ni_exam123;
      case 'EP_NI_1234':       return ep_ni_1234;
      case 'EP_NI_12345':      return ep_ni_12345;
      case 'EP_NI_123456':     return ep_ni_123456;
      case 'EP_NI_Exam123456': return ep_ni_exam123456;
      default:                 return false;
    }
  }
}