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
  by_cases hχh : χ 1 = 1
  · -- Use the support lemma: if χ(1)=1 and χ≠1, there is h with χ h ≠ 1.
    obtain ⟨h, hh⟩ := exists_ne_one_of_ne_trivial (χ := χ) hχ hχh
    let S : ℂ := ∑ g : G, (χ g : ℂ)
    have hmul : (χ h : ℂ) * S = S := by
      -- Reindex by the permutation g ↦ h * g.
      calc
        (χ h : ℂ) * S
            = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := rfl
        _ = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
              simp [S, mul_sum]
        _ = ∑ g : G, (χ (h * g) : ℂ) := by
              simp [map_mul]
        _ = ∑ g : G, (χ g : ℂ) := by
              simpa using
                (Fintype.sum_bijective (f := fun g : G => h * g) (by
                  exact mul_left_bijective h) (fun g => (χ g : ℂ)))
        _ = S := rfl
    have hfactor : ((χ h : ℂ) - 1) * S = 0 := by
      linarith [hmul]
    have hχh_ne : (χ h : ℂ) - 1 ≠ 0 := by
      exact sub_ne_zero.mpr hh
    have hS : S = 0 := by
      exact (mul_eq_zero.mp hfactor).resolve_left hχh_ne
    simpa [S] using hS
  · -- If χ(1) ≠ 1, χ is the zero character (support theorem), so every term is 0.
    have hzero : χ = 0 := by
      exact eq_zero_of_ne_one_at_one (χ := χ) hχh
    subst hzero
    simp

end T1
end TemTH
