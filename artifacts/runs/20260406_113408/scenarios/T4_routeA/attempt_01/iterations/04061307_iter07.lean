/-
`temTH` 模板：`T4` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T4

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T4_routeA (root : PrimitiveNthRoot (N := N)) (x : Fin N) :
    ∑ a : Fin N, cyclicChar root a x = if x = 0 then (N : ℂ) else 0 := by
  by_cases hx : x = 0
  · subst hx
    simp [cyclicChar]
  · rw [if_neg hx]
    have hroot : IsPrimitiveRoot root.zeta N := by
      simpa [PrimitiveNthRoot] using root.property
    have hx_coprime : Nat.Coprime (x : ℕ) N := x.2
    let ζ : ℂ := root.zeta ^ (x : ℕ)
    have hζ : IsPrimitiveRoot ζ N := by
      dsimp [ζ]
      exact hroot.pow_of_coprime (x : ℕ) hx_coprime
    have hsum : (∑ a : Fin N, cyclicChar root a x) = ∑ k : Fin N, ζ ^ (k : ℕ) := by
      refine Finset.sum_congr rfl ?_
      intro a ha
      simp [cyclicChar, ζ, pow_mul]
    rw [hsum]
    exact hζ.geom_sum_eq_zero

end T4
end TemTH
