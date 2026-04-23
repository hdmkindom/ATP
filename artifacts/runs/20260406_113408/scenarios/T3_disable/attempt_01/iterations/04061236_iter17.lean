/-
`temTH` 模板：`T3` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib.Data.ZMod.Basic
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_disable (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  let ψ : AddChar (ZMod N) ℂ := AddChar.zmodChar N root.pow_eq_one
  have hprim : ψ.IsPrimitive := by
    simpa [ψ] using AddChar.zmodChar_primitive_of_primitive_root (n := N) root.property
  have haZ : ((a : ℕ) : ZMod N) ≠ 0 := by
    intro h
    apply ha
    exact Fin.ext h
  have hsumZ : ∑ y : ZMod N, ψ (y * (((a : ℕ) : ZMod N))) = 0 := by
    have h := AddChar.sum_mulShift (R := ZMod N) (R' := ℂ) (ψ := ψ) (b := (((a : ℕ) : ZMod N))) hprim
    rw [if_neg haZ] at h
    exact h
  have hrewrite :
      (∑ x : Fin N, cyclicChar root a x) = ∑ y : ZMod N, ψ (y * (((a : ℕ) : ZMod N))) := by
    let e : Fin N ≃ ZMod N := ZMod.finEquiv N
    refine Fintype.sum_bijective e.bijective (fun x : Fin N => ?_)
    simp [e, ψ, cyclicChar, AddChar.zmodChar_apply, mul_comm, mul_left_comm, mul_assoc]
  rw [hrewrite]
  exact hsumZ

end T3
end TemTH
