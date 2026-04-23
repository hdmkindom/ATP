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
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hS : S ≠ 0 := by
    simpa [S] using hsum
  have hχ_ne_one_at_inv : χ ((Classical.choose (Character.exists_ne_one_of_ne_one hχ))⁻¹) ≠ (1 : ℂ) := by
    intro hEq
    have hpoint : χ (Classical.choose (Character.exists_ne_one_of_ne_one hχ)) = (1 : ℂ) := by
      have hmul : χ ((Classical.choose (Character.exists_ne_one_of_ne_one hχ))⁻¹) *
          χ (Classical.choose (Character.exists_ne_one_of_ne_one hχ)) = (1 : ℂ) := by
        simpa using χ.map_mul ((Classical.choose (Character.exists_ne_one_of_ne_one hχ))⁻¹)
          (Classical.choose (Character.exists_ne_one_of_ne_one hχ))
      have hleft : χ ((Classical.choose (Character.exists_ne_one_of_ne_one hχ))⁻¹) *
          χ (Classical.choose (Character.exists_ne_one_of_ne_one hχ)) =
          (1 : ℂ) * χ (Classical.choose (Character.exists_ne_one_of_ne_one hχ)) := by
        simpa [hEq]
      have : (1 : ℂ) * χ (Classical.choose (Character.exists_ne_one_of_ne_one hχ)) = (1 : ℂ) := by
        exact hleft.trans hmul
      simpa using this
    exact (Classical.choose_spec (Character.exists_ne_one_of_ne_one hχ)) hpoint
  let a : G := (Classical.choose (Character.exists_ne_one_of_ne_one hχ))⁻¹
  have hmul_sum : (χ a : ℂ) * S = S := by
    calc
      (χ a : ℂ) * S
          = (χ a : ℂ) * ∑ g : G, (χ g : ℂ) := by rfl
      _ = ∑ g : G, ((χ a : ℂ) * (χ g : ℂ)) := by
            simp [mul_sum]
      _ = ∑ g : G, (χ (a * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simpa using (χ.map_mul a g).symm
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using
              (Fintype.sum_bijective (fun g : G => a * g) (by
                intro x y hxy
                exact mul_left_cancel hxy)
                (by
                  intro y
                  refine ⟨a⁻¹ * y, ?_⟩
                  simp [mul_assoc]))
      _ = S := by rfl
  have hχa_eq_one : (χ a : ℂ) = 1 := by
    apply mul_right_cancel₀ hS
    simpa [hS] using hmul_sum
  exact hχ_ne_one_at_inv (by simpa [a] using hχa_eq_one)

end T1
end TemTH
