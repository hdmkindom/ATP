
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

variable {ι : Type*} [Fintype ι]

structure FourierTranslationData where
  shift : ι → Equiv.Perm ι
  kernel : ι → ι → ℂ
  phase : ι → ι → ℂ
  kernel_shift :
    ∀ a t x : ι, kernel a ((shift t).symm x) = phase a t * kernel a x

def translate (data : FourierTranslationData (ι := ι)) (t : ι) (f : ι → ℂ) : ι → ℂ :=
  fun x => f (data.shift t x)

/-- 与给定核对应的 Fourier 系数。 -/
def fourierCoeff (data : FourierTranslationData (ι := ι)) (f : ι → ℂ) (a : ι) : ℂ :=
  ∑ x : ι, f x * data.kernel a x

theorem candidate_T8_routeA
    (data : FourierTranslationData (ι := ι)) (f : ι → ℂ) (t a : ι) :
    fourierCoeff data (translate data t f) a =
      data.phase a t * fourierCoeff data f a := by
  sorry
