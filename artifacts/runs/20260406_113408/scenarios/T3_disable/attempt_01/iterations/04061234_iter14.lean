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
  let ψ : AddChar (ZMod N) ℂ := AddChar.zmod N
  have hψprim : ψ.IsPrimitive := ZMod.isPrimitive_stdAddChar (N := N)
  have hsum : ∑ x : ZMod N, ψ (x * (a : ZMod N)) = 0 := by
    have hane0 : (a : ZMod N) ≠ 0 := by
      intro h
      apply ha
      exact Fin.ext h
    simpa [hane0] using (AddChar.sum_mulShift (ψ := ψ) (b := (a : ZMod N)) hψprim)
  have hrewrite : (∑ x : Fin N, cyclicChar root a x) = ∑ x : ZMod N, ψ (x * (a : ZMod N)) := by
    refine Fintype.sum_bijective (e := fun x : Fin N => (x : ZMod N)) ?hbij ?f ?g ?hfg
    · exact ZMod.finBijective N
    · intro x
      rfl
    · intro x
      rfl
    · intro x
      simp [cyclicChar, ψ, mul_comm]
  rw [hrewrite]
  exact hsum

end T3
end TemTH
