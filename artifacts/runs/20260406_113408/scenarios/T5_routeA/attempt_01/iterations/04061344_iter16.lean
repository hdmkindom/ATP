/-
`temTH` 模板：`T5` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot
import CandidateTheorems.T5.Support

open scoped BigOperators

namespace TemTH
namespace T5

open CandidateTheorems.T3
open CandidateTheorems.T5

variable {N : ℕ} [NeZero N]

theorem candidate_T5_routeA (root : PrimitiveNthRoot (N := N)) (t : Fin N) :
    delta0 (N := N) t = (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a t := by
  classical
  by_cases ht : t = 0
  · subst ht
    simp [delta0, cyclicChar]
    symm
    exact inv_mul_cancel₀ (show (N : ℂ) ≠ 0 by exact_mod_cast (NeZero.ne N))
  · have hsum : ∑ a : Fin N, cyclicChar root a t = 0 := by
      have hne : root.toAddChar t ≠ 0 := by
        intro hzero
        have hall : ∀ ψ : AddChar (Fin N) ℂ, ψ t = 1 := by
          intro ψ
          rw [← hzero]
          exact AddChar.zero_apply t
        exact ht ((AddChar.forall_apply_eq_zero).1 hall)
      simpa [cyclicChar] using (AddChar.sum_eq_zero_of_ne_one hne)
    rw [delta0, if_neg ht, hsum]
    simp

end T5
end TemTH
