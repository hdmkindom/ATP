/-
`temTH` 模板：`T4` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib.NumberTheory.RootsOfUnity.Basic

open scoped BigOperators

namespace TemTH
namespace T4

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T4_free (root : PrimitiveNthRoot (N := N)) (x : Fin N) :
    ∑ a : Fin N, cyclicChar root a x = if x = 0 then (N : ℂ) else 0 := by
  classical
  by_cases hx : x = 0
  · subst hx
    simp [cyclicChar]
  · let y : Fin N := ⟨(x.val + 1) % N, by simpa using Nat.mod_lt (x.val + 1) (Nat.pos_of_ne_zero (NeZero.ne N))⟩
    have hyx : y ≠ x := by
      intro h
      have hval : (x.val + 1) % N = x.val := by
        simpa [y] using congrArg Fin.val h
      have hNdvd : N ∣ 1 := by
        have hlt : x.val < N := x.is_lt
        have hle : x.val + 1 ≤ N := Nat.succ_le_of_lt hlt
        have hEq : x.val + 1 = x.val := by
          exact (Nat.mod_eq_of_lt hle).trans hval
        omega
      have : N = 1 := Nat.dvd_one.mp hNdvd
      have hx0 : x = 0 := by
        apply Fin.ext
        have : x.val = 0 := by omega
        simpa using this
      exact hx hx0
    have hshift :
        (fun a : Fin N => cyclicChar root (a + y) x) = fun a : Fin N => cyclicChar root a x * cyclicChar root y x := by
      funext a
      simp [cyclicChar, pow_add, mul_assoc, mul_left_comm, mul_comm]
    have hsumShift :
        ∑ a : Fin N, cyclicChar root (a + y) x = ∑ a : Fin N, cyclicChar root a x := by
      simpa using Fintype.sum_bijective (fun a : Fin N => a + y) (by
        intro a b hab
        exact add_right_cancel hab) 
          (by
            intro b
            refine ⟨b - y, by simp⟩)
          (by intro a; simp)
    rw [hshift] at hsumShift
    simp_rw [Finset.mul_sum] at hsumShift
    rw [mul_comm] at hsumShift
    have hneq1 : cyclicChar root y x ≠ 1 := by
      intro h1
      have hpow : root.zeta ^ x.val = 1 := by
        simpa [cyclicChar, y] using h1
      have hprim := root.prim
      have hdvd : N ∣ x.val := (IsPrimitiveRoot.iff_def _ _).mp hprim |>.2 _ hpow
      have hxval : x.val = 0 := by
        exact Nat.eq_zero_of_lt_of_dvd x.is_lt hdvd
      apply hx
      exact Fin.ext hxval
    have hzeroFactor : cyclicChar root y x - 1 ≠ 0 := sub_ne_zero.mpr hneq1
    have hmain : (cyclicChar root y x - 1) * (∑ a : Fin N, cyclicChar root a x) = 0 := by
      calc
        (cyclicChar root y x - 1) * (∑ a : Fin N, cyclicChar root a x)
            = cyclicChar root y x * (∑ a : Fin N, cyclicChar root a x) - (∑ a : Fin N, cyclicChar root a x) := by ring
        _ = (∑ a : Fin N, cyclicChar root a x) - (∑ a : Fin N, cyclicChar root a x) := by simpa [hsumShift]
        _ = 0 := by simp
    apply eq_of_sub_eq_zero
    rw [sub_eq_iff_eq_add]
    rw [if_neg hx]
    norm_num
    have := mul_eq_zero.mp hmain
    cases this with
    | inl hfac => exact (hzeroFactor hfac).elim
    | inr hsum => simpa using hsum

end T4
end TemTH
