/-
`temTH` 模板：`T1` 自由模式。
-/
import CandidateTheorems.T1.Support
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  classical
  by_contra hsum
  have hsum_ne : ∑ g : G, (χ g : ℂ) ≠ 0 := by
    simpa using hsum
  -- Let `S` be the total sum. We compare `χ a * S` with `S`.
  set S : ℂ := ∑ g : G, (χ g : ℂ) with hS
  have hmul_sum (a : G) : (χ a : ℂ) * S = S := by
    calc
      (χ a : ℂ) * S = (χ a : ℂ) * ∑ g : G, (χ g : ℂ) := by simp [hS]
      _ = ∑ g : G, ((χ a : ℂ) * (χ g : ℂ)) := by
            simp [Finset.mul_sum]
      _ = ∑ g : G, (χ (a * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simp [map_mul]
      _ = ∑ g : G, (χ g : ℂ) := by
            refine Finset.sum_bij (fun g _ => a * g) ?_ ?_ ?_ ?_
            · intro g hg
              simp
            · intro g hg
              simp [map_mul]
            · intro g1 g2 hg1 hg2 hEq
              exact mul_left_cancel hEq
            · intro g hg
              refine ⟨a⁻¹ * g, by simp, ?_⟩
              simp [mul_assoc]
      _ = S := by simp [hS]
  have hforall_one : ∀ a : G, (χ a : ℂ) = 1 := by
    intro a
    have hEq := hmul_sum a
    have hsub : ((χ a : ℂ) - 1) * S = 0 := by
      linarith
    have hχa : (χ a : ℂ) - 1 = 0 := by
      exact sub_eq_zero.mp (mul_eq_zero.mp hsub).resolve_right hsum_ne
    linarith
  have hχ_one : χ = 1 := by
    ext a
    have ha : (χ a : ℂ) = (1 : ℂ) := hforall_one a
    exact Subtype.ext (by exact_mod_cast ha)
  exact hχ (by simpa using hχ_one)

end T1
end TemTH
