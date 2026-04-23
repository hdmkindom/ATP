/-
`temTH` 模板：`T5` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot
import CandidateTheorems.T5.Support
import Mathlib.NumberTheory.RootsOfUnity.Basic

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
    rw [inv_eq_one_div]
    exact inv_mul_cancel₀ (show (N : ℂ) ≠ 0 by exact_mod_cast (NeZero.ne N))
  · have hprim : IsPrimitiveRoot (root.ζ ^ (t : ℕ)) N := by
      simpa using root.isPrimitive.pow_of_coprime (t := (t : ℕ)) (by
        simpa [Fin.ne_iff_vne, Nat.Coprime, Nat.gcd_eq_right_iff_dvd, ht] using t.coprime)
    have hsum : ∑ a : Fin N, cyclicChar root a t = 0 := by
      simp only [cyclicChar]
      simpa [Finset.univ_eq_attach, Fin.sum_univ_eq_sum_range] using
        hprim.geom_sum_eq_zero (by
          have hN : 0 < N := Nat.pos_of_ne_zero (NeZero.ne N)
          omega)
    rw [hsum]
    simp [delta0, ht]

end T5
end TemTH
