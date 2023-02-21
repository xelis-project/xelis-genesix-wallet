; ModuleID = 'probe16.660023e1-cgu.0'
source_filename = "probe16.660023e1-cgu.0"
target datalayout = "e-m:e-p:32:32-p270:32:32-p271:32:32-p272:64:64-f64:32:64-f80:32-n8:16:32-S128"
target triple = "i686-unknown-linux-android"

; probe16::probe
; Function Attrs: nonlazybind uwtable
define void @_ZN7probe165probe17h693131c01cf55971E() unnamed_addr #0 {
start:
  ret void
}

attributes #0 = { nonlazybind uwtable "probe-stack"="__rust_probestack" "target-cpu"="pentiumpro" "target-features"="+mmx,+sse,+sse2,+sse3,+ssse3" }

!llvm.module.flags = !{!0, !1}

!0 = !{i32 7, !"PIC Level", i32 2}
!1 = !{i32 2, !"RtLibUseGOT", i32 1}
