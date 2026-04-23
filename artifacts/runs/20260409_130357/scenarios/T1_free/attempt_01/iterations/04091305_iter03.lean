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
  obtain ⟨a, ha⟩ : ∃ a : G, χ a ≠ 1 := by
    by_contra h
    apply hχ
    ext g
    by_contra hg
    exact h ⟨g, hg⟩
  have hmul : (χ a : ℂ) * (∑ g : G, (χ g : ℂ)) = ∑ g : G, (χ g : ℂ) := by
    calc
      (χ a : ℂ) * (∑ g : G, (χ g : ℂ))
          = ∑ g : G, ((χ a : ℂ) * (χ g : ℂ)) := by
              simp [mul_sum]
      _ = ∑ g : G, (χ (a * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g _
            simpa using (map_mul χ a g)
      _ = ∑ g : G, (χ g : ℂ) := by
            refine Finset.sum_bijective (fun g : G => a * g) ?_
            intro x
            exact ⟨a⁻¹ * x, by simp [mul_assoc]⟩
  by_contra hsum
  have hsum_ne : (∑ g : G, (χ g : ℂ)) ≠ 0 := hsum
  have hχa_eq_one : (χ a : ℂ) = 1 := by
    apply mul_right_cancel₀ hsum_ne
    simpa [hmul]
  exact ha (by
    apply Subtype.ext
    exact_mod_cast hχa_eq_one)

end T1
end TemTH
