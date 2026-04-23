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
  by_contra hsum
  have hsum_ne : (∑ g : G, (χ g : ℂ)) ≠ 0 := hsum
  have h_exists : ∃ h : G, χ h ≠ 1 := by
    by_contra hno
    apply hχ
    ext g
    by_contra hg
    exact hno ⟨g, hg⟩
  rcases h_exists with ⟨h, hh⟩
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hmul : (χ h : ℂ) * S = S := by
    dsimp [S]
    calc
      (χ h : ℂ) * ∑ g : G, (χ g : ℂ)
          = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
              simp [mul_sum]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            norm_num [map_mul]
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using Fintype.sum_bijective (f := fun g : G => h * g)
  have hχh_ne : (χ h : ℂ) ≠ 1 := by
    exact_mod_cast hh
  have hS_eq : S = 0 := by
    apply mul_eq_zero.mp
    have : ((χ h : ℂ) - 1) * S = 0 := by
      linarith [hmul]
    simpa [sub_eq_add_neg, add_comm, add_left_comm, add_assoc, mul_add, add_mul] using this
  exact hsum_ne hS_eq

end T1
end TemTH
