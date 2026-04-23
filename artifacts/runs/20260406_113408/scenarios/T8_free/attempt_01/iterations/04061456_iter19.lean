/-
`temTH` 模板：`T8` 自由模式。
-/
import CandidateTheorems.T8.Support

open scoped BigOperators

namespace TemTH
namespace T8

open CandidateTheorems.T8

variable {ι : Type*} [Fintype ι]

theorem candidate_T8_free
    (data : FourierTranslationData (ι := ι)) (f : ι → ℂ) (t a : ι) :
    fourierCoeff data (translate data t f) a =
      data.phase a t * fourierCoeff data f a := by
  classical
  unfold fourierCoeff translate
  let e : ι ≃ ι :=
    { toFun := data.shift t
      invFun := data.shift t
      left_inv := by
        intro x
        simpa using data.shift_involutive t x
      right_inv := by
        intro x
        simpa using data.shift_involutive t x }
  calc
    ∑ x, f (data.shift t x) * data.kernel a x
        = ∑ x, f x * data.kernel a (data.shift t x) := by
            refine Fintype.sum_equiv e
              (fun x => f (data.shift t x) * data.kernel a x)
              (fun x => f x * data.kernel a (data.shift t x)) ?_
            intro x
            simp [e, data.shift_involutive]
    _ = ∑ x, f x * (data.phase a t * data.kernel a x) := by
          apply Fintype.sum_congr
          intro x
          rw [data.phase_mul (a := a) (x := t) (y := x)]
    _ = ∑ x, data.phase a t * (f x * data.kernel a x) := by
          apply Fintype.sum_congr
          intro x
          ring
    _ = data.phase a t * fourierCoeff data f a := by
          simp [fourierCoeff, Finset.mul_sum, mul_assoc]

end T8
end TemTH
