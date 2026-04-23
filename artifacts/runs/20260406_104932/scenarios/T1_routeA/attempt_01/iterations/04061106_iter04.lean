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
  by_cases h1 : χ = 1
  · exact (hχ h1).elim
  · have hex : ∃ a : G, χ a ≠ 1 := by
      by_contra hno
      apply h1
      ext a
      by_contra ha
      exact hno ⟨a, ha⟩
    rcases hex with ⟨a, ha⟩
    have hperm : ∑ g : G, (χ (a * g) : ℂ) = S := by
      simpa [S] using
        (Function.Bijective.sum_comp (e := fun g : G => a * g)
          (Group.mulLeft_bijective a) (fun x : G => (χ x : ℂ))).symm
    have hmul : ∑ g : G, (χ (a * g) : ℂ) = (χ a : ℂ) * S := by
      calc
        ∑ g : G, (χ (a * g) : ℂ)
            = ∑ g : G, ((χ a : ℂ) * (χ g : ℂ)) := by
                refine Finset.sum_congr rfl ?_
                intro g hg
                rw [map_mul]
        _ = (χ a : ℂ) * S := by
              simp [S, mul_sum]
    have hfixed : S = (χ a : ℂ) * S := by
      rw [← hperm]
      exact hmul
    have hone_ne : (χ a : ℂ) ≠ 1 := by
      intro hcoe
      apply ha
      exact Circle.coe_inj.mp hcoe
    have hzero_factor : (1 - (χ a : ℂ)) * S = 0 := by
      calc
        (1 - (χ a : ℂ)) * S = S - (χ a : ℂ) * S := by ring
        _ = 0 := by rw [hfixed, sub_self]
    have hfactor_ne : 1 - (χ a : ℂ) ≠ 0 := by
      intro hz
      apply hone_ne
      have : (χ a : ℂ) = 1 := by linarith
      exact this
    have hS : S = 0 := by
      apply eq_zero_of_mul_eq_zero_left hfactor_ne
      simpa [mul_comm] using hzero_factor
    simpa [S] using hS

end T1
end TemTH
