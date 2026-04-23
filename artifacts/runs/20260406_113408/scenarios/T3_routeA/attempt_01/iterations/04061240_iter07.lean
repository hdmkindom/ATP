/-
`temTH` 模板：`T3` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib/Algebra/BigOperators/Ring/Fin
import Mathlib/NumberTheory/RootsOfUnity

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_routeA (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  rcases root with ⟨ζ, hζN, hprimitive⟩
  have hNpos : 0 < N := Nat.pos_of_ne_zero (NeZero.ne N)
  have hNgt1 : 1 < N := by
    by_contra h
    have hNle1 : N ≤ 1 := Nat.le_of_not_gt h
    have hNeq1 : N = 1 := le_antisymm hNle1 hNpos
    have hSub : Subsingleton (Fin N) := by
      subst hNeq1
      infer_instance
    exact ha (Subsingleton.elim _ _)
  have hprim : IsPrimitiveRoot ζ N := by
    rw [IsPrimitiveRoot.iff_def]
    refine ⟨hζN, ?_⟩
    intro m hm
    by_cases hmN : m < N
    · exact hprimitive m (Nat.pos_of_ne_zero hm) hmN
    · exact fun hEq => hmN (lt_of_not_ge fun hge => by
        have hdiv : N ∣ m := by
          refine ⟨m / N, ?_⟩
          exact (Nat.div_eq_iff_eq_mul_left hNpos).2 rfl
        have hm0 : m = 0 := by
          have := congrArg Nat.succ (Nat.eq_zero_of_dvd_of_lt_Nat ?_ ?_)
          simp at this
          exact Nat.eq_zero_of_le_zero (Nat.zero_le _)
        exact hm (by simpa [hm0]))
  have hcop : Nat.Coprime a.1 N := by
    refine Fin.isUnit_iff_coprime.mp ?_
    exact ⟨⟨a, 1, by ext <;> simp, by ext <;> simp⟩, rfl⟩
  have hprimPow : IsPrimitiveRoot (ζ ^ a.1) N := hprim.pow_of_coprime a.1 hcop
  have hsum : ∑ i in Finset.range N, (ζ ^ a.1) ^ i = 0 := hprimPow.geom_sum_eq_zero hNgt1
  simpa [cyclicChar, Fin.sum_univ_eq_sum_range, pow_mul] using hsum

end T3
end TemTH
