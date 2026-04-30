import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Tactic.Ring
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

abbrev Character (G : Type*) [Group G] := G →* ℂˣ

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  have h_exists : ∃ g : G, χ g ≠ 1 := by
    by_contra h_no
    push_neg at h_no
    apply hχ
    ext g
    simpa using h_no g
  rcases h_exists with ⟨h, hh⟩
  set S := ∑ g : G, (χ g : ℂ) with hS
  have h_mul_eq : (χ h : ℂ) * S = ∑ g : G, (χ (h * g) : ℂ) := by
    calc
      (χ h : ℂ) * S = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
        rw [hS, Finset.mul_sum]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
        refine Finset.sum_congr rfl fun g _ => ?_
        have h_mul := χ.map_mul h g
        simpa [Units.val_mul] using congrArg (fun x : ℂˣ => (x : ℂ)) h_mul
  have h_reindex : ∑ g : G, (χ (h * g) : ℂ) = S := by
    let e : G ≃ G := Equiv.mulLeft h
    have h_sum_map := Finset.sum_map (s := Finset.univ) (e := e.toEmbedding) (f := fun x : G => (χ x : ℂ))
    calc
      ∑ g : G, (χ (h * g) : ℂ) = ∑ g : G, (χ (e g) : ℂ) := rfl
      _ = Finset.sum (Finset.map e.toEmbedding Finset.univ) (fun g => (χ g : ℂ)) := by
        simpa [e] using h_sum_map.symm
      _ = Finset.sum Finset.univ (fun g => (χ g : ℂ)) := by simp [Finset.map_univ_equiv e]
      _ = S := by rw [hS]
  have h_eq : (χ h : ℂ) * S = S := by
    rw [h_mul_eq, h_reindex]
  have h_chi_h_ne_one : (χ h : ℂ) ≠ 1 := by
    intro h_one
    apply hh
    apply Units.ext
    exact h_one
  have h_factor : ((χ h : ℂ) - 1) * S = 0 := by
    calc
      ((χ h : ℂ) - 1) * S = (χ h : ℂ) * S - 1 * S := by ring
      _ = S - S := by rw [h_eq, one_mul]
      _ = 0 := by ring
  have h_zero : S = 0 := by
    have h_cases := mul_eq_zero.mp h_factor
    rcases h_cases with (hminus | hSzero)
    · have h_chi_h_eq_one : (χ h : ℂ) = 1 := sub_eq_zero.mp hminus
      exact absurd h_chi_h_eq_one h_chi_h_ne_one
    · exact hSzero
  exact h_zero
