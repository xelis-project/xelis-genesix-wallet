; ModuleID = 'probe5.5e1ab8ff-cgu.0'
source_filename = "probe5.5e1ab8ff-cgu.0"
target datalayout = "e-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128"
target triple = "aarch64-unknown-linux-android"

@alloc3 = private unnamed_addr constant <{ [75 x i8] }> <{ [75 x i8] c"/rustc/d5a82bbd26e1ad8b7401f6a718a9c57c96905483/library/core/src/num/mod.rs" }>, align 1
@alloc4 = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc3, [16 x i8] c"K\00\00\00\00\00\00\00\99\03\00\00\05\00\00\00" }>, align 8
@str.0 = internal constant [25 x i8] c"attempt to divide by zero"

; probe5::probe
; Function Attrs: nonlazybind uwtable
define void @_ZN6probe55probe17h3bbad1cbe721f5ceE() unnamed_addr #0 {
start:
  %0 = call i1 @llvm.expect.i1(i1 false, i1 false)
  br i1 %0, label %panic.i, label %"_ZN4core3num21_$LT$impl$u20$u32$GT$10div_euclid17h5c32b4277d33bf05E.exit"

panic.i:                                          ; preds = %start
; call core::panicking::panic
  call void @_ZN4core9panicking5panic17haac685927c8c1edbE(ptr align 1 @str.0, i64 25, ptr align 8 @alloc4) #3
  unreachable

"_ZN4core3num21_$LT$impl$u20$u32$GT$10div_euclid17h5c32b4277d33bf05E.exit": ; preds = %start
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind readnone willreturn
declare i1 @llvm.expect.i1(i1, i1) #1

; core::panicking::panic
; Function Attrs: cold noinline noreturn nonlazybind uwtable
declare void @_ZN4core9panicking5panic17haac685927c8c1edbE(ptr align 1, i64, ptr align 8) unnamed_addr #2

attributes #0 = { nonlazybind uwtable "target-cpu"="generic" "target-features"="+neon,+fp-armv8,+v8a" }
attributes #1 = { nocallback nofree nosync nounwind readnone willreturn }
attributes #2 = { cold noinline noreturn nonlazybind uwtable "target-cpu"="generic" "target-features"="+neon,+fp-armv8,+v8a" }
attributes #3 = { noreturn }

!llvm.module.flags = !{!0, !1}

!0 = !{i32 7, !"PIC Level", i32 2}
!1 = !{i32 2, !"RtLibUseGOT", i32 1}
