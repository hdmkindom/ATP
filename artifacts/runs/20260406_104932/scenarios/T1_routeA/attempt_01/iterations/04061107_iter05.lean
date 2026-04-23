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
  have hex : ∃ a : G, χ a ≠ 1 := by
    by_contra hno
    apply hχ
    ext a
    by_contra ha
    exact hno ⟨a, ha⟩
  rcases hex with ⟨a, ha⟩
  have hperm : ∑ g : G, (χ (a * g) : ℂ) = S := by
    simpa [S] using
      (Function.Bijective.sum_comp (e := fun g : G => a * g)
        (Group.mulLeft_bijective a) (fun x : G => (χ x : ℂ)))
  have hmul : ∑ g : G, (χ (a * g) : ℂ) = (χ a : ℂ) * S := by
    calc
      ∑ g : G, (χ (a * g) : ℂ)
          = ∑ g : G, ((χ a * χ g : Character.UnitCircle) : ℂ) := by
              refine Finset.sum_congr rfl ?_
              intro g hg
              rw [map_mul]
      _ = ∑ g : G, ((χ a : ℂ) * (χ g : ℂ)) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            rfl
      _ = (χ a : ℂ) * S := by
            simp [S, Finset.mul_sum]
  have hfixed : S = (χ a : ℂ) * S := by
    calc
      S = ∑ g : G, (χ (a * g) : ℂ) := by symm; exact hperm
      _ = (χ a : ℂ) * S := hmul
  have hone_ne : (χ a : ℂ) ≠ 1 := by
    intro hcoe
    apply ha
    ext
    simpa using hcoe
  have hfactor_ne : 1 - (χ a : ℂ) ≠ 0 := by
    intro hz
    apply hone_ne
    have : 1 = (χ a : ℂ) := by
      simpa [sub_eq_zero] using hz
    simpa using this.symm
  have hzero_factor : (1 - (χ a : ℂ)) * S = 0 := by
    rw [sub_mul, one_mul, hfixed, sub_self]
  have hS : S = 0 := by
    exact eq_zero_of_mul_eq_zero_left hfactor_ne hzero_factor
  simpa [S] using hS

end T1
end TemTH
