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
  have hsum' : (∑ g : G, (χ g : ℂ)) ≠ 0 := by simpa using hsum
  obtain ⟨g0, hg0⟩ : ∃ g0 : G, χ g0 ≠ 1 := by
    by_contra h
    apply hχ
    ext g
    by_contra hg
    exact h ⟨g, hg⟩
  have hmul : (χ g0 : ℂ) * (∑ g : G, (χ g : ℂ)) = ∑ g : G, (χ g : ℂ) := by
    calc
      (χ g0 : ℂ) * (∑ g : G, (χ g : ℂ))
          = ∑ g : G, ((χ g0 : ℂ) * (χ g : ℂ)) := by
              simpa [mul_sum]
      _ = ∑ g : G, (χ (g0 * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simpa using map_mul χ g0 g
      _ = ∑ g : G, (χ g : ℂ) := by
            exact Finset.sum_bijective (fun g => g0 * g) (by intro g; simp) (by intro g; simp) (by intro a b h; simpa [mul_left_cancel₀] using h) (by intro g; refine ⟨g0⁻¹ * g, by simp⟩)
  have : (χ g0 : ℂ) = 1 := by
    apply mul_right_cancel₀ hsum'
    simpa [hmul]
  exact hg0 (by exact_mod_cast this)

end T1
end TemTH
