/-
`temTH` 模板：`T3` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib.Algebra.GeomSum

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
  have ha_pos : 0 < a.1 :=
    Nat.pos_of_ne_zero (fun h0 => ha (Fin.ext h0))
  have ha_lt : a.1 < N := a.2
  let ω : ℂ := ζ ^ a.1
  have hω_ne_one : ω ≠ 1 := by
    dsimp [ω]
    exact hprimitive a.1 ha_pos ha_lt
  have hωN : ω ^ N = 1 := by
    dsimp [ω]
    rw [pow_mul]
    rw [hζN, one_pow]
  have hsum_range : Finset.sum (Finset.range N) (fun i => ω ^ i) = 0 := by
    have hgeom := geom_sum_mul ω N
    have hmul_zero : Finset.sum (Finset.range N) (fun i => ω ^ i) * (ω - 1) = 0 := by
      calc
        Finset.sum (Finset.range N) (fun i => ω ^ i) * (ω - 1) = ω ^ N - 1 := by
          simpa using hgeom
        _ = 0 := by rw [hωN, sub_self]
    have hωm1_ne_zero : ω - 1 ≠ 0 := by
      intro h
      apply hω_ne_one
      have : ω = 1 := sub_eq_zero.mp h
      exact this
    exact mul_eq_zero.mp hmul_zero |>.resolve_right hωm1_ne_zero
  have hcyclic : ∀ x : Fin N, cyclicChar ⟨ζ, hζN, hprimitive⟩ a x = ω ^ x.1 := by
    intro x
    simp [cyclicChar, ω, pow_mul]
  calc
    ∑ x : Fin N, cyclicChar ⟨ζ, hζN, hprimitive⟩ a x
        = ∑ x : Fin N, ω ^ x.1 := by
            refine Finset.sum_congr rfl ?_
            intro x hx
            exact hcyclic x
    _ = Finset.sum (Finset.range N) (fun i => ω ^ i) := by
          simpa using (Fin.sum_univ_eq_sum_range (f := fun i => ω ^ i) N).symm
    _ = 0 := hsum_range

end T3
end TemTH
