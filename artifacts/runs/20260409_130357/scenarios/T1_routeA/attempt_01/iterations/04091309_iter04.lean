/-
`temTH` 模板：`T1` 路线 A。
-/
import CandidateTheorems.T1.Support
import Mathlib.Algebra.BigOperators.Group.Finset
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Tactic

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_routeA (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  classical
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hχh : ∃ h : G, (χ h : ℂ) ≠ 1 := by
    by_contra hno
    apply hχ
    ext g
    by_contra hg
    exact hno ⟨g, hg⟩
  rcases hχh with ⟨h, hh⟩
  have hmul : (χ h : ℂ) * S = S := by
    calc
      (χ h : ℂ) * S = (χ h : ℂ) * (∑ g : G, (χ g : ℂ)) := rfl
      _ = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
            simp [S, mul_sum]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g _
            simp [map_mul]
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using (Fintype.sum_bijective (f := fun g : G => h * g) (Equiv.mulLeft h).bijective
              (fun g => (χ g : ℂ)))
      _ = S := by rfl
  have hEq : ((χ h : ℂ) - 1) * S = 0 := by
    have : ((χ h : ℂ) - 1) * S = (χ h : ℂ) * S - S := by ring
    rw [this, hmul, sub_self]
  have hχh_ne_zero : (χ h : ℂ) - 1 ≠ 0 := by
    intro hz
    apply hh
    exact sub_eq_zero.mp hz
  have hSzero : S = 0 := by
    exact (mul_eq_zero.mp hEq).resolve_left hχh_ne_zero
  simpa [S] using hSzero

end T1
end TemTH
