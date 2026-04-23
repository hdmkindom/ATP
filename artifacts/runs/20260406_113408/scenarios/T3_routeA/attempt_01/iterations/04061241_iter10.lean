/-
`temTH` 模板：`T3` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot

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
    have hNge1 : 1 ≤ N := Nat.succ_le_of_lt hNpos
    have hN1 : N = 1 := le_antisymm hNle1 hNge1
    have hsub : Subsingleton (Fin N) := by
      subst hN1
      infer_instance
    exact ha (Subsingleton.elim _ _)
  have ha_pos : 0 < a.1 := by
    exact Nat.pos_of_ne_zero (fun h0 => ha (Fin.ext h0))
  have ha_lt : a.1 < N := a.2
  let ω : ℂ := ζ ^ a.1
  have hω_ne_one : ω ≠ 1 := by
    dsimp [ω]
    exact hprimitive a.1 ha_pos ha_lt
  have hωN : ω ^ N = 1 := by
    dsimp [ω]
    rw [pow_mul, hζN, one_pow]
  have hgeom : Finset.sum (Finset.range N) (fun i => ω ^ i) * (ω - 1) = 0 := by
    calc
      Finset.sum (Finset.range N) (fun i => ω ^ i) * (ω - 1)
          = (Finset.sum (Finset.range N) (fun i => ω ^ i) * ω)
              - Finset.sum (Finset.range N) (fun i => ω ^ i) := by ring
      _ = Finset.sum (Finset.range N) (fun i => ω ^ (i + 1))
            - Finset.sum (Finset.range N) (fun i => ω ^ i) := by
            congr 1
            rw [Finset.mul_sum]
            refine Finset.sum_congr rfl ?_
            intro i hi
            ring_nf
            rw [pow_succ']
      _ = ω ^ N - 1 := by
            simpa using Finset.sum_range_sub_sum_range_shift (f := fun i => ω ^ i) N
      _ = 0 := by rw [hωN, sub_self]
  have hωm1_ne_zero : ω - 1 ≠ 0 := by
    intro h
    apply hω_ne_one
    linarith
  have hsum : Finset.sum (Finset.range N) (fun i => ω ^ i) = 0 := by
    apply sub_eq_zero.mp
    apply eq_of_mul_eq_mul_right hωm1_ne_zero
    simpa using hgeom
  simpa [cyclicChar, Fin.sum_univ_eq_sum_range, ω, pow_mul] using hsum

end T3
end TemTH
