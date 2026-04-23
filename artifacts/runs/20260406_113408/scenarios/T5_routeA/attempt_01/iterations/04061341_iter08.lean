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
  by_cases ht : t = 0
  · subst ht
    simp [delta0, cyclicChar]
    exact inv_mul_cancel₀ (show (N : ℂ) ≠ 0 by exact_mod_cast (NeZero.ne N))
  · have ht_coprime : Nat.Coprime (t : ℕ) N := by
      simpa [Fin.coprime_iff_univ] using t.isUnit_iff_ne_zero.mpr ht
    have hprim : IsPrimitiveRoot (root.ζ ^ (t : ℕ)) N :=
      root.isPrimitive.pow_of_coprime (t := (t : ℕ)) ht_coprime
    have hsum : ∑ a : Fin N, cyclicChar root a t = 0 := by
      rw [Fin.sum_univ_eq_sum_range]
      simp only [cyclicChar]
      simpa using hprim.geom_sum_eq_zero (by
        have hN : 0 < N := Nat.pos_of_ne_zero (NeZero.ne N)
        omega)
    rw [hsum]
    simp [delta0, ht]

end T5
end TemTH
