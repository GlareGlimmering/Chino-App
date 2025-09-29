import 'package:freezed_annotation/freezed_annotation.dart';
import 'test.dart';

part 'test2.freezed.dart';

@freezed
class MessageState with _$MessageState {
  const factory MessageStates({
    @Default([]) List<Message> items,
    @Default(false) bool isLoading,
    @Default(false) bool hasError,
    @Default(false) bool hasNextPage,
    @Default(0) int page,
  }) = _MessageState;
}
