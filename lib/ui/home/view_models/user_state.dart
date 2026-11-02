import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/data/model/user_google_model.dart';
import 'package:monamie_app/domain/models/user_model.dart';

part 'user_state.freezed.dart';

/// The signed-in person as `UserViewModel` last read them, replaced whole.
@freezed
abstract class UserState with _$UserState {
  const factory UserState({
    /// The person as the map knows them (e-mail and name), or `null` when
    /// no profile was saved at sign-in.
    UserModel? user,

    /// The profile saved at sign-in (Hive), with the avatar. Compared by
    /// identity: each read is a new object.
    UserGoogleModel? googleUser,

    /// Until the profile is first read.
    @Default(true) bool isLoading,
  }) = _UserState;
}
