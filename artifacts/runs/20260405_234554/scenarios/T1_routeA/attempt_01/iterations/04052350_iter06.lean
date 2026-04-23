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
  obtain ⟨h, hh⟩ : ∃ h : G, χ h ≠ 1 := by
    by_contra hnot
    apply hχ
    ext g
    by_contra hg
    exact hnot ⟨g, hg⟩

  let S : ℂ := ∑ g : G, (χ g : ℂ)

  have hmulS : (χ h : ℂ) * S = S := by
    calc
      (χ h : ℂ) * S = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by rfl
      _ = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
            simp [S, mul_sum]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simpa using (map_mul χ h g).symm
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using
              (Fintype.sum_bijective (fun g : G => h * g)
                (mul_left_bijective h) (fun g : G => (χ g : ℂ)))
      _ = S := by rfl

  have hχh_ne_oneC : (χ h : ℂ) ≠ 1 := by
    intro hEq
    apply hh
    ext
    exact hEq

  have hfactor : ((χ h : ℂ) - 1) * S = 0 := by
    calc
      ((χ h : ℂ) - 1) * S = (χ h : ℂ) * S - S := by ring
      _ = S - S := by simpa [hmulS]
      _ = 0 := by ring

  have hχh_sub_ne_zero : (χ h : ℂ) - 1 ≠ 0 := by
    intro h0
    apply hχh_ne_oneC
    linarith

  have hSzero : S = 0 := by
    exact (mul_eq_zero.mp hfactor).resolve_left hχh_sub_ne_zero

  simpa [S] using hSzero

end T1
end TemTH
