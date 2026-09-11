# MediaPipe task options use Protobuf Lite reflection. R8 otherwise removes
# fields such as MediaPipeLoggingProto.SystemInfo.platform_ in release builds.
# https://github.com/protocolbuffers/protobuf/blob/main/java/lite.md
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }
# JNI locates MediaPipe classes and methods by their original Java names.
-keep class com.google.mediapipe.** { *; }
# Flogger infers callers from stack frames; inlining/renaming breaks Graph's
# static logger initialization ("no caller found on the stack").
-keep class com.google.common.flogger.** { *; }
# Optional graph-template/profiling APIs are referenced by the upstream Graph
# class but omitted from tasks-vision. This app never invokes either API.
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate
