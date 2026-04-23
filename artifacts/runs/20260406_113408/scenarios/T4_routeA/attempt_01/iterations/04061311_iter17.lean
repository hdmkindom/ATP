/-
`temTH` 模板：`T4` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib/NumberTheory/RootsOfUnity/PrimitiveRoots

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
  · have hx_nat_ne_zero : (x : ℕ) ≠ 0 := by
      intro hx0
      apply hx
      exact Fin.ext hx0
    have hx_coprime : Nat.Coprime (x : ℕ) N := by
      rw [Nat.coprime_comm]
      have hprime : Fact (Nat.Prime N) := inferInstance
      exact (Fact.out : Nat.Prime N).coprime_iff_not_dvd.mpr <| by
        intro hdiv
        exact hx_nat_ne_zero <| Nat.eq_zero_of_dvd_of_lt hdiv x.isLt
    have hprim : IsPrimitiveRoot (root.zeta ^ (x : ℕ)) N :=
      root.isPrimitiveRoot.pow_of_coprime (x : ℕ) hx_coprime
    have hNgt1 : 1 < N := hprim.one_lt
    have hsum_range : (Finset.sum (Finset.range N) fun i : ℕ => (root.zeta ^ (x : ℕ)) ^ i) = 0 := by
      exact hprim.geom_sum_eq_zero hNgt1
    have hrewrite :
        (∑ a : Fin N, cyclicChar root a x) =
          Finset.sum (Finset.range N) (fun i : ℕ => (root.zeta ^ (x : ℕ)) ^ i) := by
      rw [Fin.sum_univ_eq_sum_range]
      apply Finset.sum_congr rfl
      intro a ha
      simp [cyclicChar, pow_mul, Nat.mul_comm, Nat.mul_left_comm, Nat.mul_assoc]
    rw [if_neg hx, hrewrite]
    exact hsum_range

end T4
end TemTH
