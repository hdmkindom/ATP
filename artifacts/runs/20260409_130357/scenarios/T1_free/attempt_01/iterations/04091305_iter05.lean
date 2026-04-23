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
  have hsum' : (∑ g : G, (χ g : ℂ)) ≠ 0 := hsum
  -- Pick an element where χ is not 1.
  have hne1 : ∃ a : G, χ a ≠ 1 := by
    by_contra hall
    apply hχ
    ext g
    by_contra hg
    exact hall ⟨g, hg⟩
  rcases hne1 with ⟨a, ha⟩
  have hχa_ne_zero : (χ a : ℂ) ≠ 0 := by
    exact_mod_cast (Units.ne_zero (χ a))
  have hχa_ne_one : (χ a : ℂ) ≠ 1 := by
    intro h
    apply ha
    ext
    exact h
  -- Compare the sum with its left-translation by `a`.
  have hperm :
      (∑ g : G, (χ (a * g) : ℂ)) = ∑ g : G, (χ g : ℂ) := by
    refine Finset.sum_bijective (fun g => a * g) ?_ ?_
    · intro g _
      simp
    · intro g _
      simp
  have hmul :
      (∑ g : G, (χ (a * g) : ℂ)) = (χ a : ℂ) * ∑ g : G, (χ g : ℂ) := by
    calc
      (∑ g : G, (χ (a * g) : ℂ))
          = ∑ g : G, ((χ a : ℂ) * (χ g : ℂ)) := by
              refine Finset.sum_congr rfl ?_
              intro g hg
              simp [map_mul]
      _ = (χ a : ℂ) * ∑ g : G, (χ g : ℂ) := by
            simp [Finset.mul_sum]
  have hkey : (χ a : ℂ) * ∑ g : G, (χ g : ℂ) = ∑ g : G, (χ g : ℂ) := by
    simpa [hperm] using hmul
  have hfactor : ((χ a : ℂ) - 1) * ∑ g : G, (χ g : ℂ) = 0 := by
    linarith [hkey]
  have hsum_zero : ∑ g : G, (χ g : ℂ) = 0 := by
    apply mul_eq_zero.mp hfactor |> Or.resolve_left
    exact sub_ne_zero.mpr hχa_ne_one
  exact hsum' hsum_zero

end T1
end TemTH
