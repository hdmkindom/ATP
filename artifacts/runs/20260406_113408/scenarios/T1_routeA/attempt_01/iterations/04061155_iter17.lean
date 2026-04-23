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
  have h_exists : ∃ h : G, χ h ≠ 1 := by
    by_contra h_not_exists
    apply hχ
    ext g
    by_contra hne
    exact h_not_exists ⟨g, hne⟩
  rcases h_exists with ⟨h, hh_ne_one⟩
  have h_reindex : ∑ g : G, (χ (h * g) : ℂ) = S := by
    dsimp [S]
    simpa using
      Function.Bijective.sum_comp (e := fun g : G => h * g) (Group.mulLeft_bijective h)
        (fun g : G => (χ g : ℂ))
  have h_mul_left : ∑ g : G, (χ (h * g) : ℂ) = (χ h : ℂ) * S := by
    calc
      ∑ g : G, (χ (h * g) : ℂ)
          = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
              refine Finset.sum_congr rfl ?_
              intro g _
              simp
      _ = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by
            symm
            exact Finset.mul_sum Finset.univ (fun g : G => (χ g : ℂ)) (χ h : ℂ)
      _ = (χ h : ℂ) * S := by rfl
  have h_eq : S = (χ h : ℂ) * S := by
    calc
      S = ∑ g : G, (χ (h * g) : ℂ) := h_reindex.symm
      _ = (χ h : ℂ) * S := h_mul_left
  have h_one_sub_ne_zero : 1 - (χ h : ℂ) ≠ 0 := by
    intro hz
    have hcoh : (χ h : ℂ) = 1 := by
      have := congrArg (fun z : ℂ => z + (χ h : ℂ)) hz
      simpa [sub_eq_add_neg, add_comm, add_left_comm, add_assoc] using this
    apply hh_ne_one
    exact Subtype.ext hcoh
  have h_factor : (1 - (χ h : ℂ)) * S = 0 := by
    calc
      (1 - (χ h : ℂ)) * S = S - (χ h : ℂ) * S := by ring
      _ = S - S := by rw [h_eq]
      _ = 0 := by ring
  have hS : S = 0 := by
    exact right_eq_zero_of_mul_eq_zero_left h_one_sub_ne_zero h_factor
  exact hS

end T1
end TemTH
