; ModuleID = 'probe3.b5e07ad4-cgu.0'
source_filename = "probe3.b5e07ad4-cgu.0"
target datalayout = "e-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128"
target triple = "aarch64-unknown-linux-android"

; probe3::probe
; Function Attrs: nonlazybind uwtable
define void @_ZN6probe35probe17hcc636669d75c98a8E() unnamed_addr #0 {
start:
  %0 = alloca i32, align 4
  store i32 1, ptr %0, align 4
  %1 = load i32, ptr %0, align 4
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare i32 @llvm.cttz.i32(i32, i1 immarg) #1

attributes #0 = { nonlazybind uwtable "target-cpu"="generic" "target-features"="+neon,+fp-armv8,+v8a" }
attributes #1 = { nocallback nofree nosync nounwind readnone speculatable willreturn }

!llvm.module.flags = !{!0, !1}

!0 = !{i32 7, !"PIC Level", i32 2}
!1 = !{i32 2, !"RtLibUseGOT", i32 1}
