; ModuleID = 'probe6.255734b2-cgu.0'
source_filename = "probe6.255734b2-cgu.0"
target datalayout = "e-m:e-p:32:32-Fi8-i64:64-v128:64:128-a:0:32-n32-S64"
target triple = "armv7-none-linux-android"

; probe6::probe
; Function Attrs: nonlazybind uwtable
define void @_ZN6probe65probe17hb61955c5a6d7a8baE() unnamed_addr #0 {
start:
  ret void
}

attributes #0 = { nonlazybind uwtable "target-cpu"="generic" "target-features"="+v7,+thumb-mode,+thumb2,+vfp3,-d32,-neon" }

!llvm.module.flags = !{!0, !1}

!0 = !{i32 7, !"PIC Level", i32 2}
!1 = !{i32 2, !"RtLibUseGOT", i32 1}
