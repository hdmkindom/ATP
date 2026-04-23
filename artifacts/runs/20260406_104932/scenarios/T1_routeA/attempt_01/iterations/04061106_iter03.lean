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
  rcases (MulChar.ne_one_iff.mp hχ) with ⟨a, ha⟩
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
              norm_num
      _ = (χ a : ℂ) * S := by
            simp [S, Finset.mul_sum]
  have hfixed : S = (χ a : ℂ) * S := by
    rw [← hperm]
    exact hmul
  have hone_ne : (χ a : ℂ) ≠ 1 := by
    intro h1
    apply ha
    exact_mod_cast h1
  have hzero_factor : (1 - (χ a : ℂ)) * S = 0 := by
    calc
      (1 - (χ a : ℂ)) * S = S - (χ a : ℂ) * S := by ring
      _ = 0 := by rw [hfixed, sub_self]
  have hfactor_ne : 1 - (χ a : ℂ) ≠ 0 := by
    intro h
    apply hone_ne
    linarith
  have hS : S = 0 := by
    have := eq_zero_of_mul_eq_zero_left hfactor_ne hzero_factor
    simpa using this
  simpa [S] using hS

end T1
end TemTH
