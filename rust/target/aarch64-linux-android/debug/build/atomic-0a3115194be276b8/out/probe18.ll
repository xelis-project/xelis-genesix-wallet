; ModuleID = 'probe18.f2338db3-cgu.0'
source_filename = "probe18.f2338db3-cgu.0"
target datalayout = "e-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128"
target triple = "aarch64-unknown-linux-android"

; probe18::probe
; Function Attrs: nonlazybind uwtable
define void @_ZN7probe185probe17h636b4fbbf1250ef6E() unnamed_addr #0 {
start:
  ret void
}

attributes #0 = { nonlazybind uwtable "target-cpu"="generic" "target-features"="+neon,+fp-armv8,+v8a" }

!llvm.module.flags = !{!0, !1}

!0 = !{i32 7, !"PIC Level", i32 2}
!1 = !{i32 2, !"RtLibUseGOT", i32 1}
