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
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hχh : ∃ h : G, (χ h : ℂ) ≠ 1 := by
    by_contra hno
    apply hχ
    ext g
    have hg : ¬((χ g : ℂ) ≠ 1) := by
      intro hge
      exact hno ⟨g, hge⟩
    exact Classical.byContradiction hg
  rcases hχh with ⟨h, hh⟩
  have hmul : (χ h : ℂ) * S = S := by
    calc
      (χ h : ℂ) * S = (χ h : ℂ) * (∑ g : G, (χ g : ℂ)) := rfl
      _ = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by simp [S]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g _
            simp [map_mul]
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using (Fintype.sum_equiv (Equiv.mulLeft h) (fun g : G => (χ g : ℂ)))
      _ = S := by rfl
  have hEq : ((χ h : ℂ) - 1) * S = 0 := by
    nlinarith [hmul]
  have hχh_ne_zero : (χ h : ℂ) - 1 ≠ 0 := by
    intro hz
    apply hh
    exact sub_eq_zero.mp hz
  have hSzero : S = 0 := by
    exact (mul_eq_zero.mp hEq).resolve_left hχh_ne_zero
  simpa [S] using hSzero

end T1
end TemTH
