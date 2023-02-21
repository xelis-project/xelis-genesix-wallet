; ModuleID = 'probe18.f2338db3-cgu.0'
source_filename = "probe18.f2338db3-cgu.0"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-android"

; probe18::probe
; Function Attrs: nonlazybind uwtable
define void @_ZN7probe185probe17h636b4fbbf1250ef6E() unnamed_addr #0 {
start:
  ret void
}

attributes #0 = { nonlazybind uwtable "probe-stack"="__rust_probestack" "target-cpu"="x86-64" "target-features"="+mmx,+sse,+sse2,+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt" }

!llvm.module.flags = !{!0, !1}

!0 = !{i32 7, !"PIC Level", i32 2}
!1 = !{i32 2, !"RtLibUseGOT", i32 1}
