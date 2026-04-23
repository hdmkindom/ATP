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
  obtain ⟨g, hg⟩ : ∃ g : G, χ g ≠ 1 := by
    by_contra hforall
    apply hχ
    ext g
    exact not_exists.mp hforall g
  have hmul : (χ g : ℂ) * (∑ x : G, (χ x : ℂ)) = ∑ x : G, (χ x : ℂ) := by
    calc
      (χ g : ℂ) * (∑ x : G, (χ x : ℂ))
          = ∑ x : G, ((χ g : ℂ) * (χ x : ℂ)) := by
              simpa using Finset.mul_sum (χ g : ℂ) (fun x : G => (χ x : ℂ))
      _ = ∑ x : G, (χ (g * x) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro x hx
            norm_num [map_mul]
      _ = ∑ y : G, (χ y : ℂ) := by
            simpa using Fintype.sum_bijective (fun x : G => g * x) (by
              intro a b h
              exact mul_left_cancel h) (by
              intro y
              refine ⟨g⁻¹ * y, ?_⟩
              simp [mul_assoc]) (by
              intro x
              rfl)
  have hχg_ne_zero : (χ g : ℂ) - 1 ≠ 0 := by
    intro h0
    apply hg
    have : (χ g : ℂ) = 1 := sub_eq_zero.mp h0
    exact Subtype.ext (by simpa using this)
  have hsum_eq_zero : (∑ x : G, (χ x : ℂ)) = 0 := by
    apply sub_eq_zero.mp
    have hfactor : ((χ g : ℂ) - 1) * (∑ x : G, (χ x : ℂ)) = 0 := by
      calc
        ((χ g : ℂ) - 1) * (∑ x : G, (χ x : ℂ))
            = (χ g : ℂ) * (∑ x : G, (χ x : ℂ)) - (∑ x : G, (χ x : ℂ)) := by ring
        _ = 0 := by simpa [hmul]
    exact eq_zero_of_mul_left_eq_zero hχg_ne_zero hfactor
  exact hsum hsum_eq_zero

end T1
end TemTH
