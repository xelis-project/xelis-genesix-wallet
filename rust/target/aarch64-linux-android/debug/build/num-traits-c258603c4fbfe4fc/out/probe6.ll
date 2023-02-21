; ModuleID = 'probe6.255734b2-cgu.0'
source_filename = "probe6.255734b2-cgu.0"
target datalayout = "e-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128"
target triple = "aarch64-unknown-linux-android"

; std::f64::<impl f64>::copysign
; Function Attrs: inlinehint nonlazybind uwtable
define internal double @"_ZN3std3f6421_$LT$impl$u20$f64$GT$8copysign17h34e485672e16112fE"(double %self, double %sign) unnamed_addr #0 {
start:
  %0 = alloca double, align 8
  %1 = call double @llvm.copysign.f64(double %self, double %sign)
  store double %1, ptr %0, align 8
  %2 = load double, ptr %0, align 8
  ret double %2
}

; probe6::probe
; Function Attrs: nonlazybind uwtable
define void @_ZN6probe65probe17hb61955c5a6d7a8baE() unnamed_addr #1 {
start:
; call std::f64::<impl f64>::copysign
  %_1 = call double @"_ZN3std3f6421_$LT$impl$u20$f64$GT$8copysign17h34e485672e16112fE"(double 1.000000e+00, double -1.000000e+00)
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare double @llvm.copysign.f64(double, double) #2

attributes #0 = { inlinehint nonlazybind uwtable "target-cpu"="generic" "target-features"="+neon,+fp-armv8,+v8a" }
attributes #1 = { nonlazybind uwtable "target-cpu"="generic" "target-features"="+neon,+fp-armv8,+v8a" }
attributes #2 = { nocallback nofree nosync nounwind readnone speculatable willreturn }

!llvm.module.flags = !{!0, !1}

!0 = !{i32 7, !"PIC Level", i32 2}
!1 = !{i32 2, !"RtLibUseGOT", i32 1}
