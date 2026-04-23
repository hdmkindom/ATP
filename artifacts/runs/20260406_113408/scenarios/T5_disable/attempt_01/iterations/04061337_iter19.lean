/-
`temTH` 模板：`T5` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import CandidateTheorems.T5.Support
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter

open scoped BigOperators

namespace TemTH
namespace T5

open CandidateTheorems.T3
open CandidateTheorems.T5

variable {N : ℕ} [NeZero N]

theorem candidate_T5_disable (root : PrimitiveNthRoot (N := N)) (t : Fin N) :
    delta0 (N := N) t = (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a t := by
  classical
  let ψ : AddChar (ZMod N) ℂ := AddChar.zmodChar N root.isRoot
  have hψ_prim : ψ.IsPrimitive := by
    exact AddChar.zmodChar_primitive_of_primitive_root N root.primitive
  have hsum :
      ∑ a : Fin N, cyclicChar root a t = ∑ a : Fin N, ψ a * ψ (-t) := by
    refine Finset.sum_congr rfl ?_
    intro a ha
    change root.ζ ^ ((a.val * t.val) % N) = ψ a * ψ (-t)
    simp [ψ, AddChar.zmodChar_apply]
  have horth :
      (∑ a : Fin N, cyclicChar root a t) = if t = 0 then (N : ℂ) else 0 := by
    by_cases ht : t = 0
    · subst ht
      simp [cyclicChar, root.pow_zero]
    · have ht' : (t : ZMod N) ≠ 0 := by
        intro h0
        apply ht
        ext
        simpa using h0
      have hneq : ψ t ≠ 1 := by
        intro h1
        exact ht' ((AddChar.IsPrimitive.zmod_char_eq_one_iff N hψ_prim t).mp h1)
      have hgeom : ∑ a : Fin N, cyclicChar root a t = 0 := by
        classical
        have hshift : ∑ a : Fin N, cyclicChar root a t = ψ t * ∑ a : Fin N, cyclicChar root a t := by
          calc
            ∑ a : Fin N, cyclicChar root a t
                = ∑ a : Fin N, cyclicChar root (a + 1) t := by
                    simpa using Finset.univ.sum_bijective (Equiv.addRight (1 : Fin N)).bijective
            _ = ψ t * ∑ a : Fin N, cyclicChar root a t := by
                  rw [Finset.mul_sum]
                  refine Finset.sum_congr rfl ?_
                  intro a ha
                  simp [cyclicChar, mul_assoc, pow_add, ψ, AddChar.zmodChar_apply, Nat.add_mod]
        have hone : (1 - ψ t) * ∑ a : Fin N, cyclicChar root a t = 0 := by
          linarith [hshift]
        have hne1 : 1 - ψ t ≠ 0 := by exact sub_ne_zero.mpr hneq
        exact by
          apply eq_of_sub_eq_zero
          apply (mul_eq_zero.mp ?_).resolve_left hne1
          simpa [sub_eq_add_neg, one_mul] using hone
      simpa [ht] using hgeom
  rw [delta0]
  by_cases ht : t = 0
  · simp [horth, ht]
  · simp [horth, ht]

end T5
end TemTH
