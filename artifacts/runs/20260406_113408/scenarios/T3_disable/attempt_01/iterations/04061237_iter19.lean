/-
`temTH` 模板：`T3` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter

open AddChar
open BigOperators
open CandidateTheorems.T3
open scoped

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_disable (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  let e : Fin N ≃+ ZMod N := ZMod.finEquiv N
  let ψ : AddChar (ZMod N) ℂ :=
    AddChar.zmodChar N (by
      simpa using root.isPrimitiveRoot.pow_eq_one)
  have hprim : ψ.IsPrimitive := by
    simpa [ψ] using AddChar.zmodChar_primitive_of_primitive_root (n := N) root.isPrimitiveRoot
  have hsum : ∑ y : ZMod N, ψ (y * (e a : ZMod N)) = 0 := by
    have hane : (e a : ZMod N) ≠ 0 := by
      intro h
      apply ha
      exact e.injective h
    simpa [hane] using AddChar.sum_mulShift (R := ZMod N) (R' := ℂ) (ψ := ψ) (b := (e a : ZMod N)) hprim
  have hrewrite :
      (∑ x : Fin N, cyclicChar root a x) = ∑ y : ZMod N, ψ (y * (e a : ZMod N)) := by
    rw [← Fintype.ofEquiv_sum e]
    refine Finset.sum_congr rfl ?_
    intro x hx
    simp [ψ, e, cyclicChar]
  rw [hrewrite, hsum]

end T3
end TemTH
