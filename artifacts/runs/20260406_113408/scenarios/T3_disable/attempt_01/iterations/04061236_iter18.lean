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
  let σ : Fin N ≃ Fin N :=
    {
      toFun := fun x => a * x
      invFun := fun x => a⁻¹ * x
      left_inv := by
        intro x
        simp [mul_assoc]
      right_inv := by
        intro x
        simp [mul_assoc]
    }
  have hσ : ∑ x : Fin N, cyclicChar root a x = ∑ x : Fin N, cyclicChar root 1 x := by
    refine Fintype.sum_equiv σ ?_
    intro x
    simp [σ, cyclicChar, mul_assoc]
  have hone : (∑ x : Fin N, cyclicChar root (1 : Fin N) x) = 0 := by
    simpa using root.sum_eq_zero (by simp)
  rw [hσ, hone]

end T3
end TemTH
