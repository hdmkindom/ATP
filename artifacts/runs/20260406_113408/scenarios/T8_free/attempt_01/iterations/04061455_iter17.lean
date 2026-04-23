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
    Equiv.ofBijective (data.shift t)
      (Function.Injective.bijective_of_finite (data.shift_injective t))
  calc
    ∑ x, f ((data.shift t) x) * data.kernel a x
        = ∑ x, f x * data.kernel a (e x) := by
            exact Fintype.sum_equiv e.symm
              (fun x => f ((data.shift t) x) * data.kernel a x)
              (fun x => f x * data.kernel a (e x))
              (fun x => by simp [e])
    _ = ∑ x, f x * (data.phase a t * data.kernel a x) := by
          refine Fintype.sum_congr fun x => ?_
          rw [show e x = data.shift t x by rfl]
          rw [data.phase_mul (a := a) (x := t) (y := x)]
    _ = ∑ x, data.phase a t * (f x * data.kernel a x) := by
          refine Fintype.sum_congr fun x => ?_
          ring
    _ = data.phase a t * ∑ x, f x * data.kernel a x := by
          symm
          exact Finset.mul_sum _ _

end T8
end TemTH
