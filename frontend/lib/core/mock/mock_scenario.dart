enum MockScenario { data, empty, error }

class MockException implements Exception {
  const MockException([this.message = 'Gagal memuat data (mock)']);

  final String message;

  @override
  String toString() => message;
}

extension MockScenarioX on MockScenario {
  Future<T> resolve<T>({required T empty, required T data}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return switch (this) {
      MockScenario.data => data,
      MockScenario.empty => empty,
      MockScenario.error => throw const MockException(),
    };
  }
}
