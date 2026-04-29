theorem add_zero_nat (n : Nat) : n + 0 = n := by
  induction n with
  | zero =>
      simp
  | succ n ih =>
      simp [Nat.succ_add, ih]
