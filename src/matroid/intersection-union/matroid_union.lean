
import matroid.constructions matroid.projection ftype.minmax .matroid_inter 
import algebra.big_operators

open_locale classical 
noncomputable theory 
open ftype 
open matroid  

variables {U : ftype}

section intersections_of_bases

/-- is the intersection of a basis of M₁ and a basis of M₂ -/
def is_inter_bases (M₁ M₂ : matroid U) := 
  λ X, ∃ B₁ B₂, is_basis M₁ B₁ ∧ is_basis M₂ B₂ ∧ B₁ ∩ B₂ = X 

/-- is contained in the intersection of a basis of M₁ and a basis of M₂-/
def is_subset_inter_bases (M₁ M₂ : matroid U) := 
  λ X, ∃ Y, is_inter_bases M₁ M₂ Y ∧ X ⊆ Y 

lemma exists_inter_bases (M₁ M₂ : matroid U):
  ∃ I, (is_inter_bases M₁ M₂ I) := 
begin
  cases exists_basis M₁ with B₁ hB₁, 
  cases exists_basis M₂ with B₂ hB₂,
  from ⟨B₁ ∩ B₂, ⟨B₁,B₂,hB₁,hB₂,rfl⟩⟩, 
end

def inter_bases (M₁ M₂ : matroid U) := {X : set U // is_inter_bases M₁ M₂ X}

instance inter_bases_nonempty (M₁ M₂ : matroid U) : nonempty (inter_bases M₁ M₂) :=
by {apply nonempty_subtype.mpr, apply exists_inter_bases, } 

instance inter_bases_fintype (M₁ M₂ : matroid U) : fintype (inter_bases M₁ M₂) := 
by {unfold inter_bases, apply_instance,}

lemma subset_inter_bases_is_common_ind {M₁ M₂ : matroid U}{I : set U} :
  is_subset_inter_bases M₁ M₂ I → is_common_ind M₁ M₂ I :=
begin
  rintros ⟨Y, ⟨B₁,B₂,hB₁,hB₂, hIB₁B₂⟩,hY'⟩, 
  rw ←hIB₁B₂ at hY', split, 
  refine I2 (subset_trans hY' _) (basis_is_indep hB₁),
  apply inter_subset_left,    
  refine I2 (subset_trans hY' _) (basis_is_indep hB₂),
  apply inter_subset_right,
end

lemma is_common_ind_iff_is_subset_inter_bases {M₁ M₂ : matroid U}:
  is_common_ind M₁ M₂ = is_subset_inter_bases M₁ M₂ :=
begin
  ext I, 
  refine ⟨λ h, _, subset_inter_bases_is_common_ind⟩, 
  rcases extends_to_basis h.1 with ⟨B₁,hIB₁,hB₁⟩,
  rcases extends_to_basis h.2 with ⟨B₂,hIB₂,hB₂⟩, 
  from ⟨B₁ ∩ B₂, ⟨B₁, B₂, hB₁, hB₂, rfl⟩, inter_is_lb hIB₁ hIB₂⟩, 
end

lemma inter_two_bases_is_subset_inter_bases {M₁ M₂ : matroid U}{B₁ B₂ : set U}:
  is_basis M₁ B₁ → is_basis M₂ B₂ → is_subset_inter_bases M₁ M₂ (B₁ ∩ B₂) := 
λ h₁ h₂, by {refine ⟨B₁ ∩ B₂, ⟨B₁,B₂,h₁,h₂, rfl⟩ , subset_refl _⟩, }

lemma inter_bases_is_subset_inter_bases {M₁ M₂ : matroid U}{I : set U}: 
  is_inter_bases M₁ M₂ I → is_subset_inter_bases M₁ M₂ I := 
λ h, by {rcases h with ⟨B₁,B₂,h⟩, refine ⟨I, ⟨B₁, B₂, h⟩, subset_refl _⟩,}

lemma inter_bases_is_common_ind {M₁ M₂ : matroid U}{I : set U} :
  is_inter_bases M₁ M₂ I → is_common_ind M₁ M₂ I := 
by {rw is_common_ind_iff_is_subset_inter_bases, from inter_bases_is_subset_inter_bases}


lemma max_common_indep_inter_bases (M₁ M₂ : matroid U):
  ν M₁ M₂ = max_val (λ (pair : basis_pair M₁ M₂), inter_size pair.val) :=
begin
  rcases max_spec (λ (X : common_ind M₁ M₂), size X.val) with ⟨⟨I,hI_ind⟩,hI_size,hI_ub⟩, 
  rcases max_spec (λ (pair : basis_pair M₁ M₂), inter_size pair.val) with ⟨⟨⟨B₁, B₂⟩,hB⟩,h_inter,h_size_ub⟩, 
  rw [ν], dsimp at *, rw [←hI_size, ←h_inter],
  apply le_antisymm, 
  rw is_common_ind_iff_is_subset_inter_bases at hI_ind, 
  rcases hI_ind with ⟨Y,⟨⟨B₁',B₂',⟨hB₁',hB₂',hY⟩⟩,h'⟩⟩, 
  have := h_size_ub ⟨⟨B₁',B₂'⟩, ⟨hB₁', hB₂'⟩⟩, rw inter_size at this, dsimp at this,  
  rw ←hY at h', 
  linarith [size_monotone h'],
  refine (hI_ub ⟨B₁ ∩ B₂, subset_inter_bases_is_common_ind (inter_two_bases_is_subset_inter_bases hB.1 hB.2) ⟩), 
end

end intersections_of_bases


section two_union

/-- size of the largest set that is the union of independent sets of M₁ and M₂-/
def π₂ (M₁ M₂ : matroid U) : ℤ :=  
  max_val (λ (Ip : indep_pair M₁ M₂), union_size Ip.val)

lemma π₂_eq_max_union_bases (M₁ M₂ : matroid U) :
  π₂ M₁ M₂ = max_val (λ (Bp : basis_pair M₁ M₂), union_size Bp.val) := 
begin
  rcases max_spec (λ (Bp : basis_pair M₁ M₂), union_size Bp.val) 
    with ⟨⟨⟨Bp₁, Bp₂⟩, hBp⟩, hBp_union, hBp_ub⟩, 
  rcases max_spec (λ (Ip : indep_pair M₁ M₂), union_size Ip.val) 
    with ⟨⟨⟨Ip₁, Ip₂⟩, hIp⟩, hIp_union, hIp_ub⟩, 
  rw [π₂ ], dsimp only at *, rw [←hBp_union, ←hIp_union], 
  apply le_antisymm,
  rcases extends_to_basis hIp.1 with ⟨B₁,hB₁⟩, 
  rcases extends_to_basis hIp.2 with ⟨B₂,hB₂⟩, 
  refine le_trans (size_monotone _) (hBp_ub ⟨⟨B₁, B₂⟩, ⟨hB₁.2, hB₂.2⟩⟩), 
  from union_subset_pairs hB₁.1 hB₂.1, 
  from hIp_ub ⟨⟨Bp₁,Bp₂⟩, ⟨basis_is_indep hBp.1,basis_is_indep hBp.2⟩⟩, 
end

/-- simple relationship between π M₁ M₂ and ν M₁ M₂* -/
theorem π₂_eq_ν_plus_r (M₁ M₂ : matroid U) :
  π₂ M₁ M₂ = ν M₁ (dual M₂) + M₂.r univ := 
begin
  rw [eq_comm,max_common_indep_inter_bases, π₂_eq_max_union_bases],
  
  -- bijection φ that we will use to reindex summation
  set φ : basis_pair M₁ M₂ → basis_pair M₁ (dual M₂) := λ p, ⟨⟨p.val.1, p.val.2ᶜ⟩,_⟩ with hφ, 
  swap,
  -- φ really maps to basis,cobasis pairs
  {
    dsimp only, refine ⟨p.property.1, _⟩, 
    rw [←cobasis_iff_compl_basis, cobasis_iff, dual_dual], 
    from p.property.2, 
  },
  -- ... and is bijective
  have hφ_sur : function.surjective φ := by  
  {
    refine λ Bp, ⟨⟨⟨Bp.val.1,Bp.val.2ᶜ⟩,⟨Bp.property.1,_⟩⟩,_⟩, dsimp,  
    rw [←cobasis_iff_compl_basis, cobasis_iff], from Bp.property.2, 
    rw hφ,  simp,  
  },
  -- use φ to reindex so LHS/RHS are being summed over the same set 
  have := max_reindex φ hφ_sur (λ pair, inter_size pair.val), 
  erw ←this,
  
  -- bring addition inside the max 
  rw max_add_commute, 
  
  -- it remains show the functions we're maximizing are the same 
  convert rfl, 
  ext Bp, 
  rcases Bp with ⟨⟨B₁,B₂⟩,hB⟩,   
  dsimp [union_size,inter_size] at ⊢ hB,
  linarith [size_basis hB.1, size_basis hB.2, size_modular B₁ B₂, size_induced_partition_inter B₁ B₂], 
end 


/-- The matroid union theorem for two matroids : a minmax formula for the size of the
largest partitionable set. The heavy lifting in the proof is done by matroid intersection. -/
theorem two_matroid_union (M₁ M₂ : matroid U) :
  π₂ M₁ M₂ = min_val (λ A : set U, size Aᶜ + M₁.r A + M₂.r A ) :=
begin
  rw [π₂_eq_ν_plus_r, matroid_intersection],
  rw min_add_commute (matroid_intersection_ub_fn M₁ (dual M₂)) (M₂.r univ),
  congr', ext X, rw [matroid_intersection_ub_fn], dsimp,
  rw [dual_r, compl_compl], linarith,  
end

end two_union 

section two_union_matroid

namespace two_union_matroid 

variables (M₁ M₂ : matroid U)



--notation M ∣ X := M.loopify_to X 
local infix ` |  `:50 := λ (M : matroid U)(X : set U), (M.loopify_to X)

/-- independent pairs of a subset are independent pairs of a loopification to that set -/ 
lemma indep_pair_of_subset_as_indep_pair_loopify (X : set U):
    max_val (λ Ip : indep_pair_of_subset M₁ M₂ X, union_size Ip.val) 
  = max_val (λ Ip : indep_pair (M₁ | X) (M₂ | X), union_size Ip.val) :=
begin
  set φ : indep_pair_of_subset M₁ M₂ X → indep_pair (M₁ | X) (M₂ | X) :=
    λ Ip, ⟨Ip.val ,_⟩ with hφ, 
  have hφ_sur : function.surjective φ := λ Ip, _, 
  from (max_reindex φ hφ_sur (λ Ip : indep_pair (M₁ | X) (M₂ | X), union_size Ip.val)), 
  rcases Ip with ⟨p, ⟨h₁,h₂⟩⟩, dsimp only at *, rw indep_loopify_to_iff at h₁ h₂, cases h₁, cases h₂, 
  refine ⟨⟨p,⟨⟨_,_⟩,⟨_,_⟩⟩⟩ ,_⟩; try {assumption},
  ext; trivial, 
  split; 
  {rw indep_loopify_to_iff, rcases Ip with ⟨_,⟨⟨_,_⟩,⟨_,_⟩⟩⟩, split; assumption},
end

/-- matroid union theorem for common independent sets of a given subset X -/
theorem two_matroid_union_on_subset (X : set U):
  max_val (λ Ip : indep_pair_of_subset M₁ M₂ X, union_size Ip.val) 
  = min_val (λ A : {Y : set U // Y ⊆ X}, size (X \ A) + M₁.r A + M₂.r A) := 
begin
  rw [indep_pair_of_subset_as_indep_pair_loopify, ←π₂, two_matroid_union], 
  
  rcases min_spec (λ A : {Y : set U // Y ⊆ X}, size (X \ A) + M₁.r A + M₂.r A)
    with ⟨A, hA', hA⟩, 
  rcases min_spec (λ A : set U, size Aᶜ + (M₁|X).r A + (M₂|X).r A)
    with ⟨B, hB', hB⟩,

  rw [←hA', ←hB'], clear hA' hB',
  simp_rw [rank_loopify_to] at *,
  have hXB : Xᶜ ⊆ B := by 
  {
    rw [subset_def_union, eq_comm],   
    suffices : ¬B ⊂ (Xᶜ ∪ B),
    from eq_of_ssubset (subset_union_right Xᶜ B) this,  
    intro h, 
    have h' := hB (Xᶜ ∪ B), 
    simp only [inter_distrib_right, inter_compl_left, compl_compl, set.compl_union, 
                                                empty_union, add_le_add_iff_right] at h',  
    rw [←compl_compl_union_left, compl_size, compl_size] at h', 
    linarith [size_strict_monotone h], 
  },  
  apply le_antisymm, 
  
  convert hB (Xᶜ ∪ A), 
  simp [compl_compl_union_left],  
  
  repeat 
  {
    unfold_coes, 
    simp only [inter_distrib_right, subset_def_inter_mp A.property, inter_compl_left, empty_union],
  },

  convert hA ⟨B ∩ X, inter_subset_right _ _⟩, 
  dsimp, -- Use the tactic here! 
  rw [set.compl_subset_comm, subset_def_inter, inter_comm] at hXB, 
  rw [compl_inter, inter_distrib_left], simp [hXB],  
end



/-- the rank function of the partitionable-sets matroid : rank is the size of a largest 
(M₁,M₂)-partitionable subset.  -/
def r : set U → ℤ :=
  λ X, max_val (λ Ip : indep_pair_of_subset M₁ M₂ X, union_size Ip.val)

lemma R0 : 
  satisfies_R0 (r M₁ M₂) :=
λ X, by { apply lb_le_max, intro Ip, apply size_nonneg}
  
lemma R1 : 
  satisfies_R1 (r M₁ M₂):= 
begin
  intro X, apply max_le_ub, 
  from λ Ip, size_monotone (union_is_ub Ip.2.2.1 Ip.2.2.2), 
end

lemma R2 :
  satisfies_R2 (r M₁ M₂) := 
begin
  intros X Y hXY, 
  let φ : indep_pair_of_subset M₁ M₂ X → indep_pair_of_subset M₁ M₂ Y := λ Ip, ⟨Ip.val, _⟩, 
  from max_compose_le_max φ (λ Ip, union_size Ip.val),
  rcases Ip with ⟨p, ⟨⟨_,_⟩,⟨_,_⟩⟩⟩, 
  refine ⟨⟨_,_⟩,⟨_,_⟩⟩; 
  {try {assumption}, try {from subset_trans (by assumption) hXY}}, 
end

lemma R3 : 
  satisfies_R3 (r M₁ M₂) := 
begin
  intros X Y, 
  unfold r, 
  repeat {rw [two_matroid_union_on_subset]}, 
  repeat {rw [sum_of_min]},  
  have hu : ∀ p : {Y // Y ⊆ X} × {Y_1 // Y_1 ⊆ Y}, p.1.1 ∪ p.2.1 ⊆ X ∪ Y := 
    λ p, set.union_subset_union p.1.2 p.2.2, 
  have hi : ∀ p : {Y // Y ⊆ X} × {Y_1 // Y_1 ⊆ Y}, p.1.1 ∩ p.2.1 ⊆ X ∩ Y := 
    λ p, set.inter_subset_inter p.1.2 p.2.2,
  set φ : {Y // Y ⊆ X} × {Y_1 // Y_1 ⊆ Y} → {Y_1 // Y_1 ⊆ X ∪ Y} × {Y_1 // Y_1 ⊆ X ∩ Y} := 
    λ p, ⟨⟨p.1.1 ∪ p.2.1, hu p⟩,⟨p.1.1 ∩ p.2.1, hi p⟩⟩ with hφ, 
  refine le_trans (min_le_min_compose φ _) _, 
  apply min_of_le_is_le, 
  rintro ⟨A,B⟩, rw hφ, 
  dsimp [-diff_def], 
  unfold_coes, rw [diff_size A.property, diff_size B.property, diff_size (hi ⟨A,B⟩), diff_size (hu ⟨A,B⟩)],
  linarith [size_modular X Y, size_modular A.val B.val, 
              M₁.rank_submod A.val B.val, M₂.rank_submod A.val B.val], 
end

/-- the matroid whose independent sets are the (M₁,M₂)-partitionable ones -/
def two_partitionable_sets_matroid (M₁ M₂ : matroid U): matroid U := 
  ⟨r M₁ M₂, R0 M₁ M₂, R1 M₁ M₂, R2 M₁ M₂, R3 M₁ M₂⟩

/-- independence in the two-partitionable-sets matroid -/
lemma partitionable_sets_matroid_indep_iff (M₁ M₂ : matroid U){X : set U}:
  (two_partitionable_sets_matroid M₁ M₂).is_indep X ↔ is_two_partitionable M₁ M₂ X :=
begin
  rw [indep_iff_r, two_partitionable_sets_matroid], simp only [r], 
  rcases max_spec (λ (Ip : indep_pair_of_subset M₁ M₂ X), union_size Ip.val) 
    with ⟨⟨⟨I₁,I₂⟩,⟨⟨hi1,hi2⟩,hX1,hX2⟩⟩, hI', hI⟩, 
  rw [←hI'], clear hI', dsimp only, 
  have hss := (set.union_subset_union hX1 hX2), simp only [set.union_self] at hss, 
 
  refine ⟨λ h, ⟨I₁,I₂ \ I₁, hi1,_,_,_⟩, λ h, _⟩, 
  from I2 (diff_subset I₂ I₁) hi2, 
  dsimp only [union_size] at h,  rw [eq_of_eq_size_subset_iff hss] at h, rw ←h, 
  simp only [diff_def, union_inter_compl],  apply inter_diff, 
  rcases h with ⟨I₁',I₂', ⟨h11,h12,h21,h22⟩⟩, 
  subst h21, 
  refine le_antisymm (size_monotone hss) _ , 
  refine hI ⟨⟨I₁',I₂'⟩, _⟩,
  from ⟨⟨h11,h12⟩, subset_union_left _ _, subset_union_right _ _⟩, 
end 

end two_union_matroid 

end two_union_matroid


section union
 open_locale big_operators 

/-- statement that each I_i is indep in M_i -/
def is_indep_tuple {n : ℕ}(Ms: fin n → matroid U) : (fin n → set U) → Prop := 
  λ Is, ∀ i : fin n, (Ms i).is_indep (Is i)

/-- subtype of vectors of independent sets -/
def indep_tuple {n : ℕ}(Ms : fin n → matroid U) : Type :=
  {Is : fin n → (set U) // is_indep_tuple Ms Is}

instance indep_tuple_nonempty {n : ℕ}(Ms : fin n → matroid U ) : nonempty (indep_tuple Ms) := 
by {apply nonempty_subtype.mpr, from ⟨(λ x, ∅), λ i, (Ms i).I1 ⟩}
  
instance indep_tuple_fintype {n : ℕ}(Ms: fin n → matroid U): fintype (indep_tuple Ms) := 
by {unfold indep_tuple, apply_instance }

def sum_of_ranks {n : ℕ}(Ms : fin n → matroid U) : ℤ := 
  ∑ i, (Ms i).r univ

def union_of_tuple {n : ℕ}(Xs : fin n → set U) : set U := 
  ⋃ i, Xs i

def π_tuple {n : ℕ}: (fin n → matroid U) → ℤ := 
  λ Ms, max_val (λ (Is: indep_tuple Ms), size (union_of_tuple Is.val) )



@[simp] lemma sum_fin_one (a : fin 1 → ℤ):
  ∑ i, a i = a 0 := 
by simp 

@[simp] lemma union_fin_zero (a : fin 0 → set U):
  (⋃ i, a i) = ∅ := 
begin
  simp only [set.Union_eq_empty], 
  from λ i, fin_zero_elim i, 
end

@[simp] lemma inter_fin_zero (a : fin 0 → set U):
  (⋂ i, a i) = univ := 
begin
  simp only [set.Inter_eq_univ], 
  from λ i, fin_zero_elim i, 
end

@[simp] lemma union_fin_one (a : fin 1 → set U):
  (⋃ i, a i) = a 0 :=
begin
  ext x, rw [set.mem_Union], 
  refine ⟨λ h, _, λ h, ⟨0,h⟩⟩, 
  cases h with i hi, 
  rw (fin.eq_zero i) at hi,
  from hi, 
end

@[simp] lemma inter_fin_one (a : fin 1 → set U):
  (⋂ i, a i) = a 0 :=
begin
  ext x, rw [set.mem_Inter], 
  refine ⟨λ h, _, λ h i,_ ⟩, 
  from h 0, 
  rw fin.eq_zero i,
  from h, 
end





/-- function mapping tuples of indep sets to the size of the union -/
def matroid_union_lb_fn {n : ℕ} (Ms : fin n → matroid U) := 
  (λ (Is : indep_tuple Ms), size (union_of_tuple Is.val))

/-- function mapping each sets the size of its complement plus the sum of its ranks 
in the list of matroids: an upper bound for matroid union -/
def matroid_union_ub_fn {n : ℕ} (Ms : fin n → matroid U) := 
  (λ (A : set U), size Aᶜ + ∑ i, (Ms i).r A )




lemma lb_fn_trivial (Ms : fin 0 → matroid U): 
  matroid_union_lb_fn Ms = λ Is, 0 := 
begin
  ext x, 
  unfold matroid_union_lb_fn union_of_tuple, dsimp only,
  rw [size_zero_iff_empty, set.Union_eq_empty], 
  from λ i, fin_zero_elim i,  
end


theorem matroid_union' {n : ℕ} (Ms : fin n → matroid U): 
  max_val (matroid_union_lb_fn Ms) = min_val (matroid_union_ub_fn Ms) :=
begin
  induction n with n IH, 

  -- base case
  simp only [matroid_union_ub_fn, add_zero, fin.sum_univ_zero, lb_fn_trivial, max_const],  
  rw attained_lb_is_min' (λ (X : set U), size Xᶜ ) (univ : set U) 0 _ _; 
  simp [size_nonneg], 
  
  cases nat.eq_zero_or_pos n with hn,

  -- one-matroid case 
  subst hn,  
  unfold matroid_union_lb_fn matroid_union_ub_fn union_of_tuple, 
  simp_rw [union_fin_one, sum_fin_one], 
  apply minmax_eq_cert, 
  cases exists_basis (Ms 0) with B hB, 
  set Bfn := (λ (i : fin 1), B) with h_Bfn, 
  have Bprop : ∀ (i : fin 1), (Ms i).is_indep (Bfn i) := by
    {intros i,  rw h_Bfn, dsimp only, convert (basis_is_indep hB)},

  refine ⟨⟨Bfn, Bprop⟩, univ, _⟩,  
  simp [size_basis hB],   

  intros Is A,
  rw ←indep_iff_r.mp (Is.property 0),
  have hd := (dual (Ms 0)).rank_nonneg Aᶜ, 
  rw [dual_r , compl_compl] at hd, 
  linarith [(Ms 0).rank_mono (subset_univ (Is.val 0))], 
  
  --have := rank_le_univ M0  
  
  

  --let Bt : indep_tuple Ms := ⟨⟨λ (i : fin n.succ), B⟩ , by {}⟩, 
  --use ⟨⟨λ i, B⟩, _⟩, 
  --refine ⟨⟨λ x, B⟩ ,_⟩ , (univ : set U)⟩, 
  --rw hn at Ms, 
  rcases max_spec (matroid_union_lb_fn Ms) with ⟨Is, ⟨hIs₁, hIs₂⟩⟩, 
  rcases min_spec (matroid_union_ub_fn Ms) with ⟨A, ⟨hA₁, hA₂⟩⟩, 
   
  rw [←hIs₁, ←hA₁], 
  sorry, 
  --unfold matroid_union_ub_fn matroid_union_lb_fn, 


  
  
  


  
                    

end

/-

nvalid type ascription, term has type
  @max_val (@indep_tuple U 1 Ms) ℤ (@indep_tuple_fintype U 1 Ms) _ int.linear_order (@matroid_union_lb_fn U 1 Ms) =
    @min_val (set ↥U) ℤ (ftype.set_fintype_of U) _ int.linear_order (@matroid_union_ub_fn U 1 Ms)
but is expected to have type
  @max_val (@indep_tuple U n.succ Ms) ℤ (@indep_tuple_fintype U n.succ Ms) _ int.linear_order
      (@matroid_union_lb_fn U n.succ Ms) =
    @min_val (set ↥U) ℤ (ftype.set_fintype_of U) _ int.linear_order (@matroid_union_ub_fn U n.succ Ms)
types contain aliased name(s): Ms
remark: the tactic `dedup` can be used to rename aliases

-/

end union 