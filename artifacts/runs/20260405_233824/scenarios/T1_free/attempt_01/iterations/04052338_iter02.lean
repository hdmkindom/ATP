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
  have hsum' : ∑ g : G, (χ g : ℂ) ≠ 0 := by simpa using hsum
  -- Pick an element where the character value is not 1.
  have hexists : ∃ h : G, χ h ≠ 1 := by
    by_contra hforall
    apply hχ
    ext g
    have hg : χ g = 1 := by
      by_contra hne
      exact hforall ⟨g, hne⟩
    simpa using hg
  rcases hexists with ⟨h, hh⟩
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hS0 : S ≠ 0 := by simpa [S] using hsum'
  have hperm : S = (χ h : ℂ) * S := by
    -- Change of variable g ↦ h * g in the finite sum.
    calc
      S = ∑ g : G, (χ (h * g) : ℂ) := by
            simp [S, Finset.mul_sum]
      _ = ∑ g : G, (χ h : ℂ) * (χ g : ℂ) := by
            simp [Character.map_mul]
      _ = (χ h : ℂ) * S := by
            simp [S, Finset.mul_sum]
  have hχh_one : (χ h : ℂ) = 1 := by
    apply mul_right_cancel₀ hS0
    simpa [hperm] using (Eq.symm hperm)
  exact hh (by simpa using hχh_one)

end T1
end TemTH
