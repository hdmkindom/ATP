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
  let e : ι ≃ ι := data.shiftEquiv t
  calc
    ∑ x, f (data.shift t x) * data.kernel a x
        = ∑ x, f x * data.kernel a (e.symm x) := by
            refine (Fintype.sum_equiv e ?_ ?_ ?_).symm
            intro x
            simp [e]
    _ = ∑ x, f x * (data.phase a t * data.kernel a x) := by
          refine Fintype.sum_congr ?_
          intro x
          rw [show e.symm x = data.shift t x by
            simpa [e] using (e.apply_symm_apply x)]
          rw [data.phase_mul (a := a) (x := t) (y := x)]
    _ = ∑ x, data.phase a t * (f x * data.kernel a x) := by
          refine Fintype.sum_congr ?_
          intro x
          ring
    _ = data.phase a t * ∑ x, f x * data.kernel a x := by
          simp [mul_add, mul_left_comm, mul_assoc]

end T8
end TemTH
