/-
`temTH` 模板：`T3` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter

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
    exact AddChar.zmodChar_primitive_of_primitive_root N root.isPrimitiveRoot
  have hsumZMod : ∑ y : ZMod N, ψ (y * (a : ZMod N)) = 0 := by
    have ha' : (a : ZMod N) ≠ 0 := by
      exact_mod_cast ha
    simpa [ha'] using AddChar.sum_mulShift (ψ := ψ) (b := (a : ZMod N)) hprim
  have hrewrite :
      (∑ x : Fin N, cyclicChar root a x) = ∑ y : ZMod N, ψ (y * (a : ZMod N)) := by
    refine Fintype.sum_bijective (fun x : Fin N => (x : ZMod N)) ?_ ?_
    · exact ZMod.finBijective N
    · intro x
      simp [ψ, cyclicChar, mul_comm]
  rw [hrewrite]
  exact hsumZMod

end T3
end TemTH
