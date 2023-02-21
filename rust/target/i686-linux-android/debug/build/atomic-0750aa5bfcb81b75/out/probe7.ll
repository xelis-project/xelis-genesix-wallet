; ModuleID = 'probe7.c5bbe9cf-cgu.0'
source_filename = "probe7.c5bbe9cf-cgu.0"
target datalayout = "e-m:e-p:32:32-p270:32:32-p271:32:32-p272:64:64-f64:32:64-f80:32-n8:16:32-S128"
target triple = "i686-unknown-linux-android"

; probe7::probe
; Function Attrs: nonlazybind uwtable
define void @_ZN6probe75probe17ha41b472c87af9e32E() unnamed_addr #0 {
start:
  ret void
}

attributes #0 = { nonlazybind uwtable "probe-stack"="__rust_probestack" "target-cpu"="pentiumpro" "target-features"="+mmx,+sse,+sse2,+sse3,+ssse3" }

!llvm.module.flags = !{!0, !1}

!0 = !{i32 7, !"PIC Level", i32 2}
!1 = !{i32 2, !"RtLibUseGOT", i32 1}
