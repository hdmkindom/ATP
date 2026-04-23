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
  obtain ⟨a, ha⟩ : ∃ a : G, χ a ≠ 1 := by
    by_contra hnot
    apply hχ
    ext g
    by_contra hg
    exact hnot ⟨g, hg⟩
  have hmul : (χ a : ℂ) * (∑ g : G, (χ g : ℂ)) = ∑ g : G, (χ g : ℂ) := by
    calc
      (χ a : ℂ) * (∑ g : G, (χ g : ℂ))
          = ∑ g : G, ((χ a : ℂ) * (χ g : ℂ)) := by
              simpa [Finset.mul_sum]
      _ = ∑ g : G, (χ (a * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simpa using (map_mul χ a g)
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using Finset.sum_bijective (fun g : G => a * g) (by
              intro x hx
              exact Finset.mem_univ _)
                (by
                  intro x hx
                  simp)
  have hχa_eq_one : (χ a : ℂ) = 1 := by
    have hsum_ne : (∑ g : G, (χ g : ℂ)) ≠ 0 := hsum
    apply mul_right_cancel₀ hsum_ne
    simpa [hmul]
  exact ha (by exact_mod_cast hχa_eq_one)

end T1
end TemTH
