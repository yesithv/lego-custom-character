abstract class Failure {
  final String message;
  const Failure(this.message);
}

class LocalStorageFailure extends Failure {
  const LocalStorageFailure(super.message);
}

class CharacterLimitFailure extends Failure {
  const CharacterLimitFailure()
      : super('Free tier allows up to 5 characters. Upgrade to Pro for unlimited.');
}
