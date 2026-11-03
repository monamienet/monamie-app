import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member.freezed.dart';

/// A person of the observed group: someone with a position there. Compared
/// by content, so lists of members compare by content too.
@freezed
abstract class GroupMember with _$GroupMember {
  const factory GroupMember({required String name, required String email}) =
      _GroupMember;
}
