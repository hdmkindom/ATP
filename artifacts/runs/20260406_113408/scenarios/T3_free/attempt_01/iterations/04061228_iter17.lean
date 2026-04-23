/-
`temTH` 模板：`T3` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_free (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  have hNlt : 1 < N := by
    by_contra h
    have hN : N = 1 := by omega
    subst hN
    apply ha
    ext
    simp
  let ζ := root.1 ^ (a : ℕ)
  have hζ_neq_one : ζ ≠ 1 := by
    intro hζ
    have hroot := root.2
    have hpow : root.1 ^ (a : ℕ) = 1 := hζ
    have hdiv : N ∣ (a : ℕ) := (hroot.2 _ hpow)
    have hlt : (a : ℕ) < N := a.is_lt
    have hzero : (a : ℕ) = 0 := by
      omega
    apply ha
    ext
    simpa using hzero
  have hgeom : ∑ x : Fin N, cyclicChar root a x = ∑ x : Fin N, ζ ^ (x : ℕ) := by
    apply Finset.sum_congr rfl
    intro x hx
    simp [cyclicChar, ζ, mul_comm, mul_left_comm, mul_assoc, pow_mul]
  rw [hgeom]
  by_cases hz : ζ = 1
  · exact (hζ_neq_one hz).elim
  · have hmul : ζ * ∑ x : Fin N, ζ ^ (x : ℕ) = ∑ x : Fin N, ζ ^ (x : ℕ) := by
      calc
        ζ * ∑ x : Fin N, ζ ^ (x : ℕ)
            = ∑ x : Fin N, ζ ^ ((x : ℕ) + 1) := by
                simp [Finset.mul_sum, mul_comm, mul_left_comm, mul_assoc, pow_succ']
        _ = ∑ x : Fin N, ζ ^ (x : ℕ) := by
              refine Fin.sum_univ_succAbove_eq ?_
              intro y
              simp
              rw [show (root.1 ^ (a : ℕ)) ^ N = 1 by
                rw [← pow_mul]
                have hroot := root.2
                exact hroot.1.pow a]
      have hsub : (ζ - 1) * ∑ x : Fin N, ζ ^ (x : ℕ) = 0 := by
        linarith
      have hzunit : IsUnit (ζ - 1) := by
        exact sub_ne_zero.mpr hz |> isUnit_iff_ne_zero.mpr
      exact mul_left_cancel₀ (sub_ne_zero.mpr hz) <| by simpa [sub_mul] using hsub
    have hfix : (ζ - 1) * ∑ x : Fin N, ζ ^ (x : ℕ) = 0 := by
      calc
        (ζ - 1) * ∑ x : Fin N, ζ ^ (x : ℕ)
            = ζ * ∑ x : Fin N, ζ ^ (x : ℕ) - ∑ x : Fin N, ζ ^ (x : ℕ) := by ring
        _ = 0 := by rw [hmul, sub_self]
    exact mul_eq_zero.mp hfix |> Or.elim (fun h => (hz (sub_eq_zero.mp h)).elim) id

end T3
end TemTH
