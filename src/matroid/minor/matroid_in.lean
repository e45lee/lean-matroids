import ftype.basic ftype.embed ftype.minmax set_tactic.solver
import matroid.rankfun matroid.dual .projection

open_locale classical 
noncomputable theory

open ftype matroid set 

variables {U : ftype}


/-- a matroid_in U corresponds to a matroid defined on some subset E of U. Implemented as a matroid on which the nonelements of 
E are all loops. -/
@[ext] structure matroid_in (U : ftype) :=
(E : set U)
(carrier : matroid U)
(support : carrier.r Eᶜ = 0)

namespace matroid_in 

/-- the rank of a set X wrt a matroid_in U. Elements of X outside the E of U are ignored -/
def r (M : matroid_in U)(X : set U) := M.carrier.r X 

lemma r_carrier_eq_r (M : matroid_in U)(X : set U): 
  M.carrier.r X = M.r X := 
rfl 

lemma r_eq_r_inter (M : matroid_in U)(X : set U):
  M.r X = M.r (X ∩ M.E) :=
begin
  nth_rewrite 0 ←(inter_union_compl X M.E), 
  apply rank_eq_rank_union_rank_zero,
  exact rank_inter_rank_zero _ M.support, 
end

lemma r_eq_inter_r (M : matroid_in U)(X : set U):
  M.r X = M.r (M.E ∩ X) :=
by rw [r_eq_r_inter, inter_comm]

lemma ext' {M₁ M₂ : matroid_in U}(h_ground : M₁.E = M₂.E)(h_r : ∀ X ⊆ M₁.E, M₁.r X = M₂.r X):
  M₁ = M₂ := 
begin
  apply matroid_in.ext _ _ h_ground, ext X,
  specialize h_r (X ∩ M₁.E) (by simp),  
  rw (by simp : X = (X ∩ M₁.E) ∪ (X ∩ M₁.Eᶜ)), 
  have h₁ := matroid.rank_inter_rank_zero X M₁.support,
  have h₂ := matroid.rank_inter_rank_zero X M₂.support, rw ←h_ground at h₂, 
  rw [matroid.rank_eq_rank_union_rank_zero (X ∩ M₁.E) h₁, matroid.rank_eq_rank_union_rank_zero (X ∩ M₁.E) h₂], 
  exact h_r, 
end

/-- the ftype coming from the E of M -/
def ground (M : matroid_in U) := subftype M.E

/-- a matroid_in U gives a matroid on a subtype -/
def as_mat_on (M : matroid_in U)(E : set U) : matroid (subftype E) := 
{ r := λ X, M.r X,
  R0 := λ X, M.carrier.R0 _,
  R1 := λ X, by {dsimp only [r], rw ←size_subtype_img, apply M.carrier.R1},
  R2 := λ X Y hXY, by {apply M.carrier.R2, apply set.image_subset _ hXY, },
  R3 := λ X Y, by {dsimp only, convert M.carrier.R3 _ _, apply set.image_union, exact (set.image_inter subtype.val_injective).symm} }

/-- a matroid_in U, viewed as a matroid on the subtype defined by its E -/
def as_mat (M : matroid_in U) : matroid M.ground := as_mat_on M M.E 

mk_simp_attribute msimp "minor simp lemmas"

attribute [msimp] ftype.diff_def 

@[simp, msimp] lemma as_mat_r (M : matroid_in U)(X : set (subftype M.E)): 
  M.as_mat.r X = M.r (X : set U) :=
rfl 



/-- a matroid_in U, constructed from a matroid on a subtype of U -/
def of_mat {E : set U}(N : matroid (subftype E)) : matroid_in U := 
{ E := E,
  carrier := 
  { r := λ X, N.r (inter_subtype E X ),
    R0 := λ X, N.R0 _,
    R1 := λ X, by {refine le_trans (N.R1 _) (eq.trans_le _ (size_mono_inter_right E X)), apply size_inter_subtype },
    R2 := λ X Y hXY, by {dsimp only, apply N.R2, tauto,  },
    R3 := λ X Y, N.R3 _ _, },
  support := by {simp [inter_subtype],} }

@[simp, msimp] lemma of_mat_E {E : set U}(N : matroid (subftype E)) : 
  (of_mat N).E = E :=
rfl 

@[simp, msimp] lemma of_mat_r {E : set U}(N : matroid (subftype E))(X : set U) : 
  (of_mat N).r X = N.r (inter_subtype E X) := 
rfl 

lemma r_of_mat {E : set U}(N : matroid (subftype E))(X : set (subftype E)): 
  N.r X = (of_mat N).r X := 
begin
  simp only [matroid_in.of_mat_r], convert rfl, 
  unfold inter_subtype, ext x , --rcases x with ⟨x,hx⟩, 
  simp only [mem_set_of_eq, subtype.coe_mk], 
  refine ⟨λ h, _, λ h, ⟨x,⟨h, by simp⟩⟩ ⟩,
  rcases h with ⟨⟨y, h⟩, h', h''⟩, 
  cases x, 
  simp only [subtype.coe_mk] at h'', 
  convert h',  rwa h'', 
end


@[simp,msimp] lemma as_mat_of_mat {E : set U}(N : matroid (subftype E)) : 
  as_mat (of_mat N) = N :=
begin
  ext X, dsimp only [as_mat, as_mat_on, of_mat], convert rfl, ext x, 
  suffices: x ∈ X ↔ x.val ∈ subtype.val '' X, from this, 
  simp only [image_congr, mem_image, exists_eq_right, subtype.exists, subtype.val_eq_coe],
  refine ⟨λ h, by {cases x, tauto}, λ h, _⟩,
  cases x with x hx, rcases h with ⟨y,z, h⟩, convert h.1, convert h.2.symm, 
end

@[simp,msimp] lemma of_mat_as_mat (M : matroid_in U) : 
  of_mat (as_mat M) = M :=
ext' (by simp) 
     (λ X hX, by {simp only with msimp coe_up at *, convert rfl, rw subset_def_inter_mp hX}) 


lemma of_mat_as_mat_on {E E' : set U}(N : matroid (subftype E))(h : E' = E): 
   of_mat ((of_mat N).as_mat_on E') = of_mat N := 
begin
  apply ext', convert rfl, 
  intros X hX, 
  simp only [of_mat, as_mat_on], dsimp only [ftype.ftype_coe], 
  convert rfl, exact h.symm, 
  dsimp only [ftype.ftype_coe, r, inter_subtype],   
  ext Y, convert rfl,  ext e, rcases e with ⟨e,he⟩,  
  simp only [image_congr, mem_image, exists_eq_right, subtype.exists, subtype.val_eq_coe,
  exists_eq_right, subtype.coe_mk], 
  refine ⟨λ h', _, λ h', _⟩,
  {simp only at h', rcases h' with ⟨_, h'', rfl⟩, exact h'',}, 
  rw h, exact ⟨⟨e,he⟩,⟨h',rfl⟩⟩,
end

lemma of_mat_inj {R : set U}(N N' : matroid (subftype R)):
  of_mat N = of_mat N' → N = N' := 
λ h, by {ext, rw [r_of_mat,r_of_mat,h]}  

def as_matroid_in (M : matroid U) : matroid_in U := ⟨univ, M, by simp⟩

instance coe_to_matroid_in : has_coe (matroid U) (matroid_in U) := ⟨λ M, as_matroid_in M⟩

section defs 

def is_indep (M : matroid_in U)(X : set U) := M.carrier.is_indep X

lemma indep_iff_carrier {M : matroid_in U}{X : set U}:
  M.is_indep X ↔ M.carrier.is_indep X :=
by rw is_indep 

lemma indep_iff_r {M : matroid_in U}{X : set U} : 
  M.is_indep X ↔ M.r X = size X := 
by rw [is_indep,r, matroid.is_indep]

lemma indep_iff_subtype {M : matroid_in U}{X : set U}: 
  M.is_indep X ↔ X ⊆ M.E ∧ M.as_mat.is_indep (inter_subtype M.E X) :=
begin
  refine ⟨λ h, _, λ h, _⟩, 
  begin
    have hXE : X ⊆ M.E := by {rw subset_iff_disjoint_compl, exact indep_inter_rank_zero h M.support},
    split, assumption, 
    rw matroid.indep_iff_r, simp only [as_mat_r] with coe_up, 
    rwa [←indep_iff_r, subset_def_inter_mp hXE], 
  end,
  cases h with h h', 
  simp only [matroid.indep_iff_r,as_mat_r] with coe_up at h', 
  rwa [←subset_def_inter_mp h, indep_iff_r, h'], 
end

def is_circuit (M : matroid_in U)(C : set U) :=
  M.carrier.is_circuit C ∧ C ⊆ M.E 

lemma circuit_iff_carrier {M : matroid_in U}{C : set U}:
  M.is_circuit C ↔ M.carrier.is_circuit C ∧ C ⊆ M.E :=
by rw is_circuit 

lemma circuit_iff_r {M : matroid_in U}{C : set U}:
  M.is_circuit C ↔ (M.r C = size C - 1 ∧ ∀ Y, Y ⊂ C → M.r Y = size Y) ∧ C ⊆ M.E := 
by {rw [circuit_iff_carrier, circuit_iff_r], refl} 

/-lemma circuit_iff_subtype {M : matroid_in U}{X : set U}:
  M.is_circuit X ↔ X ⊆ M.E ∧ M.as_mat.is_circuit (inter_subtype M.E X) := 
begin
  simp_rw [circuit_iff_carrier, matroid.circuit_iff_r],  
  refine ⟨λ h, ⟨h.2,_⟩, λ h, ⟨_,h.1⟩⟩, 
  begin
     
    /-rw [circuit_iff_i, ←indep_iff_carrier] at h, rw [circuit_iff_i], 
    rcases h with ⟨⟨hXE, h⟩, h'⟩, split, 
    { rw indep_iff_subtype at hXE, tauto, },
    intros Y hY, specialize h (subtype.val '' Y), 
    rw [←indep_iff_carrier, indep_iff_subtype] at h, -/ 
  end,
end 
-/



def dual (M : matroid_in U) : matroid_in U := 
  of_mat (as_mat M).dual 

@[simp, msimp] lemma dual_r (M : matroid_in U)(X : set U) :
  (dual M).r X = size (X ∩ M.E) + M.r (M.E \ X) - M.r M.E  :=
begin
  rw [dual, of_mat_r, matroid.dual_r], simp only with coe_up, convert rfl, 
  simp only with coe_up, 
  ext,simp only [ftype.diff_def, set.mem_inter_eq, set.mem_compl_eq], tauto, 
  simp only with coe_up, 
end 

lemma of_mat_dual {E : set U}(M : matroid (subftype E)): 
  of_mat M.dual = (of_mat M).dual := 
by {unfold dual, convert rfl, simp}


@[simp, msimp] lemma dual_ground (M : matroid_in U): 
  (dual M).E = M.E := 
rfl 

@[simp, msimp] lemma dual_dual (M : matroid_in U):
  M.dual.dual = M := 
by {simp_rw [dual,of_mat_dual, as_mat_of_mat, ←of_mat_dual, matroid.dual_dual, of_mat_as_mat]}

lemma dual_inj {M M' : matroid_in U}(h : M.dual = M'.dual):
  M = M' := 
by rw [←dual_dual M, ←dual_dual M',h]

lemma dual_inj_iff {M M' : matroid_in U}:
  M = M' ↔ M.dual = M'.dual := 
⟨λ h, by {rw h}, λ h, dual_inj h⟩

end defs 

end matroid_in