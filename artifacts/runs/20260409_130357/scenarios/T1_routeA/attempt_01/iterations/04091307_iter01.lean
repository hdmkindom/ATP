/-
`temTH` 模板：`T1` 路线 A。
-/
import CandidateTheorems.T1.Support
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_routeA (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  classical
  by_contra hsum
  have hS : (∑ g : G, (χ g : ℂ)) ≠ 0 := by simpa using hsum
  have hχh : ∃ h : G, χ h ≠ (1 : ℂ) := by
    by_contra hforall
    apply hχ
    ext g
    specialize hforall g
    simpa using hforall
  rcases hχh with ⟨h, hh⟩
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hmul : (χ h : ℂ) * S = S := by
    dsimp [S]
    calc
      (χ h : ℂ) * (∑ g : G, (χ g : ℂ))
          = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
              simp [mul_sum]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simp [map_mul]
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using
              (Fintype.sum_bijective (f := fun g : G => h * g)
                (by
                  intro a b hab
                  exact mul_left_cancel hab)
                (by
                  intro g
                  refine ⟨h⁻¹ * g, ?_⟩
                  simp [mul_assoc]))
  have hχh_ne_zero : (χ h : ℂ) - 1 ≠ 0 := by
    have : (χ h : ℂ) ≠ 1 := hh
    linarith
  have hEq : ((χ h : ℂ) - 1) * S = 0 := by
    have := hmul
    linarith
  have hS0 : S = 0 := by
    apply mul_eq_zero.mp hEq |> Or.resolve_left hχh_ne_zero
  exact hS hS0

end T1
end TemTH
