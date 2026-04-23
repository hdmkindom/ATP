/-
`temTH` 模板：`T3` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_disable (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  let ψ : AddChar (ZMod N) ℂ :=
    AddChar.zmodChar N root.pow_eq_one
  have hprim : ψ.IsPrimitive := by
    simpa [ψ] using AddChar.zmodChar_primitive_of_primitive_root (n := N) root.property
  have ha' : (a : ZMod N) ≠ 0 := by
    intro h
    apply ha
    apply Fin.ext
    have hval : ((a : ZMod N).val : ZMod N) = (0 : ZMod N) := by
      simpa using congrArg ZMod.val h
    simpa using h
  have hsumZMod : ∑ y : ZMod N, ψ (y * (a : ZMod N)) = 0 := by
    simpa [ha'] using AddChar.sum_mulShift (ψ := ψ) (b := (a : ZMod N)) hprim
  have hrewrite :
      (∑ x : Fin N, cyclicChar root a x) = ∑ y : ZMod N, ψ (y * (a : ZMod N)) := by
    let e : Fin N ≃ ZMod N := ZMod.finEquiv N
    refine Fintype.sum_equiv e (fun x : Fin N => cyclicChar root a x) (fun y : ZMod N => ψ (y * (a : ZMod N))) ?_
    intro x
    simp [e, ψ, cyclicChar, AddChar.zmodChar_apply, mul_comm, mul_left_comm, mul_assoc]
  rw [hrewrite]
  exact hsumZMod

end T3
end TemTH
