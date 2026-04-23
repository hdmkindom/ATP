/-
`temTH` 模板：`T8` 路线 B。
-/
import CandidateTheorems.T8.Support

open scoped BigOperators

namespace TemTH
namespace T8

open CandidateTheorems.T8

variable {ι : Type*} [Fintype ι]

theorem candidate_T8_routeB
    (data : FourierConvolutionData (ι := ι)) (f : ι → ℂ) (t a : ι) :
    fourierCoeff data.toFourierTranslationData
      (translate data.toFourierTranslationData t f) a =
      data.phase a t * fourierCoeff data.toFourierTranslationData f a := by
  simpa [translate_eq_delta_convolution] using
    (fourierCoeff_convolution
      (data := data)
      (f := delta data t)
      (g := f)
      (a := a)).trans <|
      by simpa [fourierCoeff_delta]

end T8
end TemTH
