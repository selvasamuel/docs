Require Export List.
Require Export Bool.
Require Export Arith.
Require Export Peano_dec.
Require Export Coq.Arith.PeanoNat.
Require Import CpdtTactics.
Require Export Coq.Program.Wf.
Require Export Coq.Program.Tactics.
Require Export Recdef.
Set Implicit Arguments.




Inductive var : Type :=
| Var : nat -> var  (*concrete variables*)
| Abs : nat -> var. (*abstract variables*)


Inductive ty_label :=
| Material : nat -> ty_label
| Shape : nat -> ty_label.

Inductive label : Type :=
| l_def : nat -> label
| l_type : ty_label -> label.

Inductive ty : Type := (*types*)
| str : decl_tys -> ty
| sel : exp -> label -> ty
| fn_t  : ty -> ty -> ty
| top   : ty
| bot  : ty
                           
with
decl_ty : Type := (*declaration types*)
| dt_upp : label -> ty -> decl_ty
| dt_low : label -> ty -> decl_ty
| dt_val : label -> ty -> decl_ty

with
decl_tys : Type :=
| dt_nil : decl_tys
| dt_con : decl_ty -> decl_tys -> decl_tys

with
exp : Type := (*expressions*)
| new : decls -> exp
| e_app : exp -> exp -> exp
| e_fn : ty -> exp -> ty -> exp
| e_acc : exp -> label -> exp
| e_var : var -> exp
| e_loc : nat -> exp
| e_cast : exp -> ty -> exp

with
decl : Type := (*declarations*)
| d_upp : label -> ty -> decl
| d_low : label -> ty -> decl
| d_val : label -> exp -> ty -> decl

with
decls : Type :=
| d_nil : decls
| d_con : decl -> decls -> decls.


(*Notation "p 'cast' t" := (p_cast p t) (at level 80).
Notation "'v_' x" := (p_var x) (at level 80).*)

Notation "'c_' x" := (e_var (Var x)) (at level 80).
Notation "'a_' x" := (e_var (Abs x)) (at level 80).
Notation "'v_' x" := (e_var x) (at level 80).
Notation "'i_' x" := (e_loc x) (at level 80).
Notation "e 'cast' t" := (e_cast e t) (at level 80).

Notation "'type' l 'sup' t" := (dt_low l t) (at level 80).
Notation "'type' l 'ext' t" := (dt_upp l t) (at level 80).
Notation "'type' l 'supe' t" := (d_low l t) (at level 80).
Notation "'type' l 'exte' t" := (d_upp l t) (at level 80).
Notation "'val' l 'oft' t" := (dt_val l t) (at level 80).
Notation "'val' l 'assgn' e 'oft' t" := (d_val l e t) (at level 80).
Notation "'fn' t1 'in_exp' e 'off' t2" := (e_fn t1 e t2) (at level 80).
Notation "t1 'arr' t2" := (fn_t t1 t2) (at level 80).

Inductive is_path : exp -> Prop :=
| isp_loc : forall i, is_path (i_ i)
| isp_var : forall x, is_path (v_ x)
| isp_cast : forall p t, is_path p ->
                    is_path (p cast t).

Scheme type_mut_ind := Induction for ty Sort Prop
  with decl_ty_mut_ind := Induction for decl_ty Sort Prop
  with decl_tys_mut_ind := Induction for decl_tys Sort Prop
  with exp_mut_ind := Induction for exp Sort Prop
  with decl_mut_ind := Induction for decl Sort Prop
  with decls_mut_ind := Induction for decls Sort Prop.

Combined Scheme type_exp_mutind from type_mut_ind, decl_ty_mut_ind, decl_tys_mut_ind, exp_mut_ind, decl_mut_ind, decls_mut_ind.

Definition id_t (s : decl_ty) : label :=
  match s with
  | type l sup _ => l
  | type l ext _ => l
  | val l oft _ => l
  end.

Definition id_d (d : decl) : label :=
  match d with
  | type L exte _ => L
  | type L supe _ => L
  | val l assgn _ oft _ => l
  end.

Section variables.
  
  Definition env := list ty.
  Definition mu := list exp.
  
  Reserved Notation "'[' p '/t' n ']' t" (at level 80).
  Reserved Notation "'[' p '/d' n ']' d" (at level 80).
  Reserved Notation "'[' p1 '/p' n ']' p2" (at level 80).

  (*Left Shift*)
  
  Fixpoint left_shift_var (n : nat) (v : var) : var :=
    match v with
      | Var m => Var (n + m)
      | _ => v
    end.
      
  Notation "v 'lshift_v' n" := (left_shift_var n v) (at level 80).
  Reserved Notation "t 'lshift_t' n" (at level 80).
  Reserved Notation "d 'lshift_dt' n" (at level 80).
  Reserved Notation "d 'lshift_dts' n" (at level 80).
  Reserved Notation "e 'lshift_e' n" (at level 80).
  Reserved Notation "d 'lshift_d' n" (at level 80).
  Reserved Notation "d 'lshift_ds' n" (at level 80).
  Reserved Notation "G 'lshift_e' n" (at level 80).
  
  Fixpoint left_shift_type (n : nat) (t : ty) : ty :=
    match t with
      | top => top
      | bot => bot
      | t1 arr t2 => (t1 lshift_t n) arr (t2 lshift_t n)
      | sel p l => sel (p lshift_e n) l
      | str ds => str (ds lshift_dts n)
    end
      where "t 'lshift_t' n" := (left_shift_type n t)

  with
  left_shift_decl_ty (n : nat) (d : decl_ty) : decl_ty :=
    match d with
      | type l sup t => type l sup (t lshift_t n)
      | type l ext t => type l ext (t lshift_t n)
      | val l oft t => val l oft (t lshift_t n)
    end
      where "d 'lshift_dt' n" := (left_shift_decl_ty n d)

  with
  left_shift_decl_tys (n : nat) (ds : decl_tys) : decl_tys :=
    match ds with
      | dt_nil => dt_nil
      | dt_con d ds' => dt_con (d lshift_dt n) (ds' lshift_dts n)
    end
      where "d 'lshift_dts' n" := (left_shift_decl_tys n d)

  with
  left_shift_exp (n : nat) (e : exp) : exp :=
    match e with
    | new ds => new (ds lshift_ds S n)
    | e_app e1 e2 => e_app (e1 lshift_e n) (e2 lshift_e n)
    | fn t1 in_exp e off t2 => fn (t1 lshift_t n) in_exp (e lshift_e S n) off (t2 lshift_t S n)
    | e_acc e m => e_acc (e lshift_e n) m
    | e cast t => (e lshift_e n) cast (t lshift_t n)
    | v_ x => v_ (x lshift_v n)
    | i_ i => i_ i
    end
      where "e 'lshift_e' n" := (left_shift_exp n e)

  with
  left_shift_decl (n : nat) (d : decl) : decl :=
    match d with
      | type l supe t => type l supe (t lshift_t n)
      | type l exte t => type l exte (t lshift_t n)
      | val l assgn e oft t => val l assgn (e lshift_e n) oft (t lshift_t n)
    end
      where "d 'lshift_d' n" := (left_shift_decl n d)

  with
  left_shift_decls (n : nat) (ds : decls) : decls :=
    match ds with
      | d_nil => d_nil
      | d_con d ds' => d_con (d lshift_d n) (ds' lshift_ds n)
    end
      where "d 'lshift_ds' n" := (left_shift_decls n d).

  

  (*Right Shift*)
  
  Fixpoint right_shift_var (n : nat) (v : var) : var :=
    match v with
      | Var m => Var (m - n)
      | _ => v
    end.
      
  Notation "v 'rshift_v' n" := (right_shift_var n v) (at level 80).
  Reserved Notation "n 'rshift_n' m" (at level 80).
  Reserved Notation "t 'rshift_t' n" (at level 80).
  Reserved Notation "d 'rshift_d' n" (at level 80).
  Reserved Notation "d 'rshift_ds' n" (at level 80).
  Reserved Notation "d 'rshift_dt' n" (at level 80).
  Reserved Notation "d 'rshift_dts' n" (at level 80).
  Reserved Notation "p 'rshift_p' n" (at level 80).
  Reserved Notation "G 'rshift_e' n" (at level 80).
  
  Fixpoint right_shift_type (n : nat) (t : ty) : ty :=
    match t with
    | top => top
    | bot => bot
    | t1 arr t2 => (t1 rshift_t n) arr (t2 rshift_t n)
    | sel p l => sel (p rshift_e n) l
    | str ds => str (ds rshift_dts n)
    end
  where "t 'rshift_t' n" := (right_shift_type n t)

  with
  right_shift_decl_ty (n : nat) (d : decl_ty) : decl_ty :=
    match d with
    | type l sup t => type l sup (t rshift_t n)
    | type l ext t => type l ext (t rshift_t n)
    | val l oft t => val l oft (t rshift_t n)
    end
  where "d 'rshift_dt' n" := (right_shift_decl_ty n d)

  with
  right_shift_decl_tys (n : nat) (ds : decl_tys) : decl_tys :=
    match ds with
      | dt_nil => dt_nil
      | dt_con d ds' => dt_con (d rshift_dt n) (ds' rshift_dts n)
    end
  where "d 'rshift_dts' n" := (right_shift_decl_tys n d)
                                
  with
  right_shift_exp (n : nat) (e : exp) : exp :=
    match e with
    | new ds => new (ds rshift_ds S n)
    | e_app e1 e2 => e_app (e1 rshift_e n) (e2 rshift_e n)
    | fn t1 in_exp e off t2 => fn (t1 rshift_t n) in_exp (e rshift_e S n) off (t2 rshift_t S n)
    | e_acc e m => e_acc (e rshift_e n) m
    | e cast t => (e rshift_e n) cast (t rshift_t n)
    | v_ x => v_ (x rshift_v n)
    | i_ i => i_ i
    end
      where "e 'rshift_e' n" := (right_shift_exp n e)

  with
  right_shift_decl (n : nat) (d : decl) : decl :=
    match d with
      | type l supe t => type l supe (t rshift_t n)
      | type l exte t => type l exte (t rshift_t n)
      | val l assgn e oft t => val l assgn (e rshift_e n) oft (t rshift_t n)
    end
      where "d 'rshift_d' n" := (right_shift_decl n d)

  with
  right_shift_decls (n : nat) (ds : decls) : decls :=
    match ds with
      | d_nil => d_nil
      | d_con d ds' => d_con (d rshift_d n) (ds' rshift_ds n)
    end
      where "d 'rshift_ds' n" := (right_shift_decls n d).


  (*with
  right_shift_path (n : nat) (p : path) : path :=
    match p with
    | v_ x => v_ (x rshift_v n)
    | p cast t => (p rshift_p n) cast (t rshift_t n)
    end
      where "p 'rshift_p' n" := (right_shift_path n p)*)

  (*Environment shift*)
  
  (*move all variables less than n, 1 space to the left, this means reducing the relative distance of all 
   references greater than or equal to n by 1*)

  Definition inc (i : option nat) (n : nat) : option nat :=
    match i with
      | None => None
      | Some i' => Some (i' + n) 
    end.

  Definition dec (i : option nat) (n : nat): option nat :=
    match i with
    | None => None
    | Some i' => if i' <? n
                then None
                else Some (i' - n)
    end.

  Definition raise_nat (r i : nat) : nat :=
    if r <? i
    then r
    else r + 1.

  Notation "r 'raise_n' i" := (raise_nat r i)(at level 80).

  Definition raise_var (v : var)(i : nat) : var :=
    match v with
    | Var _ => v
    | Abs r => Abs (r raise_n i)
    end.

  Notation "v 'raise_v' i" := (raise_var v i)(at level 80).
  
  Reserved Notation "t 'raise_t' i" (at level 80).
  Reserved Notation "s 'raise_s' i" (at level 80).
  Reserved Notation "ss 'raise_ss' i" (at level 80).
  Reserved Notation "e 'raise_e' i" (at level 80).
  Reserved Notation "d 'raise_d' i" (at level 80).
  Reserved Notation "ds 'raise_ds' i" (at level 80).

  Fixpoint raise_ty (t : ty)(i : nat) : ty :=
    match t with
    | top => top
    | bot => bot
    | t1 arr t2 => (t1 raise_t i) arr (t2 raise_t (S i))
    | sel p L => sel (p raise_e i) L
    | str ss => str (ss raise_ss (S i))
    end
  where "t 'raise_t' i" := (raise_ty t i)

  with
  raise_decl_ty (s : decl_ty)(i : nat) : decl_ty :=
    match s with
    | type L ext t => type L ext (t raise_t i)
    | type L sup t => type L sup (t raise_t i)
    | val l oft t => val l oft (t raise_t i)
    end
  where "s 'raise_s' i" := (raise_decl_ty s i)

  with
  raise_decl_tys (ss : decl_tys)(i : nat) : decl_tys :=
    match ss with
    | dt_nil => dt_nil
    | dt_con s ss' => dt_con (s raise_s i) (ss' raise_ss i)
    end
  where "ss 'raise_ss' i" := (raise_decl_tys ss i)

  with
  raise_exp (e : exp)(i : nat) : exp :=
    match e with
    | v_ v => v_ (v raise_v i)
    | i_ _ => e
    | fn t1 in_exp e' off t2 => fn (t1 raise_t i) in_exp (e' raise_e (S i)) off (t2 raise_t (S i))
    | e_app e1 e2 => e_app (e1 raise_e i) (e2 raise_e i)
    | e_acc e' l => e_acc (e' raise_e i) l
    | new ds => new (ds raise_ds (S i))
    | e' cast t => (e' raise_e i) cast (t raise_t i)
    end
  where "e 'raise_e' i" := (raise_exp e i)

  with
  raise_decl (d : decl)(i : nat) : decl :=
    match d with
    | type L exte t => type L exte (t raise_t i)
    | type L supe t => type L supe (t raise_t i)
    | val l assgn e oft t => val l assgn (e raise_e i) oft (t raise_t i)
    end
  where "d 'raise_d' i" := (raise_decl d i)

  with
  raise_decls (ds : decls)(i : nat) : decls :=
    match ds with
    | d_nil => d_nil
    | d_con d ds' => d_con (d raise_d i) (ds' raise_ds i)
    end
  where "ds 'raise_ds' i" := (raise_decls ds i).
      

  
  Reserved Notation "v '[' i ']' 'rjump_v' n" (at level 80).
  Reserved Notation "t '[' i ']' 'rjump_t' n" (at level 80).
  Reserved Notation "d '[' i ']' 'rjump_s' n" (at level 80).
  Reserved Notation "d '[' i ']' 'rjump_ss' n" (at level 80).
  Reserved Notation "d '[' i ']' 'rjump_d' n" (at level 80).
  Reserved Notation "d '[' i ']' 'rjump_ds' n" (at level 80).
  Reserved Notation "p '[' i ']' 'rjump_e' n" (at level 80).

  (*left and right jumps for inserting new variables into the middle of contexts*)
  (*
for a context G1++G2 that is a context G1 appended with G2, we would like to insert another 
context G between them (G1++G++G2) while maitaining the correct variable naming. Since refereces use de Bruijn indeces
Therefore every reference in G1 that refers to something in G2 must be increased by the length of G. References 
in G1 that refer to positions in G1 do not change, and similarly, all references in G2 must remain the same.

@params i is the relative distance to the first element of G2. If i = 0, then the current element is in G2
        n is the length of G, the distance to be shifted
        m is reference. If m = 0, then the next element in the context is the refered type.
*)
          

  Definition right_jump_n (r i n : nat) : nat :=
      if i <=? r
      then r + n
      else r.

  Notation "r '[' i ']' 'rjump_n' n" := (right_jump_n r i n) (at level  80).

  Fixpoint right_jump_v (x : var)(i n : nat) : var :=
    match x with
      | Var r => Var (r[i] rjump_n n)
      | _ => x
    end.

  Notation "x '[' i ']' 'rjump_v' n" := (right_jump_v x i n) (at level  80).

  Fixpoint right_jump_t (t : ty) (i n : nat) : ty  :=
    match t with
      | top => top
      | bot => bot
      | t1 arr t2 => (t1 [i] rjump_t n) arr (t2 [i] rjump_t n)
      | sel p l => sel (p [i] rjump_e n) l
      | str ss => str (ss [i] rjump_ss n)
    end
      where "t '[' i ']' 'rjump_t' n" := (right_jump_t t i n)

  with
  right_jump_d_ty (s : decl_ty) (i n : nat) : decl_ty :=
    match s with
      | type l sup t => type l sup (t[i] rjump_t n)
      | type l ext t => type l ext (t[i] rjump_t n)
      | val l oft t => val l oft (t[i] rjump_t n)
    end
      where "d '[' i ']' 'rjump_s' n" := (right_jump_d_ty d i n)

  with
  right_jump_d_tys (ss : decl_tys) (i n : nat) : decl_tys :=
    match ss with 
      | dt_nil => dt_nil
      | dt_con s ss' => dt_con (s [i] rjump_s n) (ss' [i] rjump_ss n)
    end
      where "d '[' i ']' 'rjump_ss' n" := (right_jump_d_tys d i n)

  with
  right_jump_e (e : exp) (i n : nat) : exp :=
    match e with
    | new ds => new (ds [i] rjump_ds n)
    | e_app e1 e2 => e_app (e1 [i] rjump_e n) (e2 [i] rjump_e n)
    | fn t1 in_exp e off t2 => fn (t1 [i] rjump_t n) in_exp (e [i] rjump_e n) off (t2 [i] rjump_t n)
    | e_acc e m => e_acc (e [i] rjump_e n) m
    | v_ x => v_ (x [i] rjump_v n)
    | i_ i => i_ i
    | e cast t => (e [i] rjump_e n) cast (t [i] rjump_t n)
    end
      where "e '[' i ']' 'rjump_e' n" := (right_jump_e e i n)        
                                             
  with
  right_jump_d (d : decl) (i n : nat) : decl :=
    match d with
      | type l supe t => type l supe (t[i] rjump_t n)
      | type l exte t => type l exte (t[i] rjump_t n)
      | val l assgn e oft t => val l assgn (e[i] rjump_e n) oft (t [i] rjump_t n)
    end
      where "d '[' i ']' 'rjump_d' n" := (right_jump_d d i n)

  with
  right_jump_ds (ds : decls) (i n : nat) : decls :=
    match ds with
      | d_nil => d_nil
      | d_con d ds' => d_con (d [i] rjump_d n) (ds' [i] rjump_ds n)
    end
  where "d '[' i ']' 'rjump_ds' n" := (right_jump_ds d i n).

  Definition right_jump_env (G : env)(i n : nat) : env :=
    map (fun (t : ty) => t [i] rjump_t n) G.

  Notation "G '[' i ']' 'rjump_env' n" :=(right_jump_env G i n)(at level 80).
  
  Reserved Notation "'[' p '/t' n ']' ds" (at level 80).
  Reserved Notation "'[' p '/s' n ']' ds" (at level 80).
  Reserved Notation "'[' p '/ss' n ']' ds" (at level 80).
  Reserved Notation "'[' p '/d' n ']' ds" (at level 80).
  Reserved Notation "'[' p '/ds' n ']' ds" (at level 80).
  Reserved Notation "'[' p '/e' n ']' ds" (at level 80).


  Definition subst_v (n : nat) (x y : var) : var :=
    match y with
      | Abs m => if beq_nat n m
                then x
                else y
      | _ => y
    end.
  
  Notation "'[' x '/v' n ']' y" := (subst_v n x y) (at level 80).
    
  Fixpoint subst (n : nat) (e : exp) (t : ty) : ty :=
    match t with
    | top => top
    | bot => bot
    | t1 arr t2 => ([e /t n] t1) arr ([(e raise_e 0) /t S n] t2)
    | sel p l => sel ([ e /e n ] p) l
    | str ds => str ([ (e raise_e 0) /ss S n ] ds)
    end

  where "'[' p '/t' n ']' t" := (subst n p t)

  with
  subst_d_ty (n : nat) (e : exp) (d : decl_ty) : decl_ty :=
    match d with
    | type l sup t => type l sup ([e /t n] t)
    | type l ext t => type l ext ([e /t n] t)
    | val l oft t => val l oft ([e /t n] t)                        
    end
      
  where "'[' p '/s' n ']' d" := (subst_d_ty n p d)

  with
  subst_d_tys (n : nat) (e : exp) (d : decl_tys) : decl_tys :=
    match d with
    | dt_nil => dt_nil
    | dt_con d ds' => dt_con ([e /s n] d) ([e /ss n] ds')
    end
      
  where "'[' p '/ss' n ']' d" := (subst_d_tys n p d)

  with
  subst_e (n : nat) (e1 e2 : exp) : exp :=
    match e2 with
    | new ds => new ([(e1 raise_e 0) /ds S n] ds)
    | e_app e e' => e_app ([e1 /e n] e) ([e1 /e n] e')
    | fn t1 in_exp e off t2 => fn ([e1 /t n] t1) in_exp ([(e1 raise_e 0) /e S n] e) off ([(e1 raise_e 0) /t S n] t2)
    | e_acc e m => e_acc ([e1 /e n] e) m
    | v_ x => match x with
             | Abs m => if beq_nat n m
                       then e1
                       else v_ x
             | _ => v_ x
             end
    | i_ i => i_ i
    | e cast t => ([e1 /e n] e) cast ([e1 /t n] t)
    end
      
  where "'[' e1 '/e' n ']' e2" := (subst_e n e1 e2)

  with
  subst_d (n : nat) (e : exp) (d : decl) : decl :=
    match d with
    | type l exte t => type l exte ([e /t n] t)
    | type l supe t => type l supe ([e /t n] t)
    | val l assgn el oft t => val l assgn ([e /e n] el) oft ([e /t n] t)
    end
      
  where "'[' p '/d' n ']' d" := (subst_d n p d)

  with
  subst_ds (n : nat) (e : exp) (d : decls) : decls :=
    match d with
    | d_nil => d_nil
    | d_con d ds' => d_con ([e /d n] d) ([e /ds n] ds')
    end
      
  where "'[' p '/ds' n ']' d" := (subst_ds n p d).

  Fixpoint subst_env (n : nat)(p : exp)(G : env) : env :=
    match G with
    | nil => nil
    | t::G' => match n with
              | O => ([p /t n]t)::G'
              | S n' => ([p /t n]t)::(subst_env n' p G')
              end
    end.

  Notation "'[' x '/env' n ']' G" := (subst_env n x G)(at level 80).

  (*with
  subst_p (n : nat) (p1 p2 : path) : path :=
    match p2 with
    | v_ x => match x with
             | Abs m => if beq_nat n m
                       then p1
                       else p2
             | _ => p2
             end
    | p cast t => [p1 /p n] p cast [p1 /t n] t
    end
                              
      
  where "'[' p1 '/p' n ']' p2" := (subst_p n p1 p2)*)

  Fixpoint get {A : Type} (n : nat) (l : list A) : option A :=
    match n with
      | O => match l with
              | nil => None
              | h::t => Some h
            end
      | S m => match l with
                | nil => None
                | h::t => get m t
              end
    end.

  Definition mapping {A : Type}(n : nat)(l : list A) : option A :=
    get n (rev l).

  Notation "n 'mapsto' t 'elem' G" := (mapping n G = Some t)(at level 80).

  (*Definition get (n : nat) (l : list ty) : option ty :=
    nth n (rev l).*)
  
  Reserved Notation "Sig 'en' G 'vdash' p 'pathType' t" (at level 80).
  
  Inductive typing_p : env -> env -> exp -> ty -> Prop :=
  | pt_var : forall Sig G n t, n mapsto t elem G ->
                        Sig en G vdash (c_ n) pathType t
  | pt_loc : forall Sig G i t, i mapsto t elem Sig ->
                        Sig en G vdash (i_ i) pathType t
  | pt_cast : forall Sig G p t, Sig en G vdash (p cast t) pathType t

  where "Sig 'en' G 'vdash' p 'pathType' t" := (typing_p Sig G p t).

  Reserved Notation "Sig 'en' G 'vdash' p 'ni' d" (at level 80).
  Reserved Notation "Sig 'en' G 'vdash' d 'cont' t" (at level 80).

  Hint Constructors typing_p.

  Inductive in_dty : decl_ty -> decl_tys -> Prop :=
  | in_head_dty : forall d ds, in_dty d (dt_con d ds)
  | in_tail_dty : forall d d' ds, in_dty d ds ->
                             in_dty d (dt_con d' ds).

  Inductive in_d : decl -> decls -> Prop :=
  | in_head_d : forall d ds, in_d d (d_con d ds)
  | in_tail_d : forall d d' ds, in_d d ds ->
                             in_d d (d_con d' ds).

  Inductive has : env -> env -> exp -> decl_ty -> Prop :=
  | has_path : forall Sig G p t d, Sig en G vdash p pathType t ->
                            Sig en G vdash d cont t ->
                            Sig en G vdash p ni ([p /s 0] d)

  where "Sig 'en' G 'vdash' p 'ni' d" := (has Sig G p d)

  with
  contains : env -> env -> ty -> decl_ty -> Prop :=
  | cont_struct : forall Sig G ds d, in_dty d ds ->
                              Sig en G vdash d cont str ds
  | cont_upper : forall Sig G p L t d, Sig en G vdash p ni (type L ext t) ->
                                Sig en G vdash d cont t ->
                                Sig en G vdash ([a_ 0 cast t /s 0] d) cont (sel p L)
                                  
  where "Sig 'en' G 'vdash' d 'cont' t" := (contains Sig G t d).

  Hint Constructors has contains.
  
  Scheme has_mut_ind := Induction for has Sort Prop
                        with contains_mut_ind := Induction for contains Sort Prop.             

  Combined Scheme has_contains_mutind from has_mut_ind, contains_mut_ind. 
  (*
  Fixpoint left_jump_env (G : env) (n : nat) (i : option nat) : env :=
    match G with
      | nil => nil
      | t::G' => (t [i] ljump_t n) :: (G' [dec i 1] ljump_e n)
    end
  where "G '[' i ']' 'ljump_e' n" := (left_jump_env G n i).
*)

  Reserved Notation "Sig 'en' G1 'vdash' t1 '<;' t2 'dashv' G2" (at level 80).
  Reserved Notation "Sig 'en' G1 'vdash' d1 '<;;' d2 'dashv' G2" (at level 80).
  Reserved Notation "Sig 'en' G1 'vdash' ds1 '<;;;' ds2 'dashv' G2" (at level 80).
  
  Inductive sub : env -> env -> ty -> ty -> env -> Prop :=
  | s_top : forall Sig G1 t G2, Sig en G1 vdash t <; top dashv G2
  | s_bot : forall Sig G1 t G2, Sig en G1 vdash bot <; t dashv G2
  | s_refl : forall Sig G1 p L G2, Sig en G1 vdash (sel p L) <; (sel p L) dashv G2
                           
  | s_upper : forall Sig G1 p L t1 t2 G2, Sig en G1 vdash p ni (type L ext t1) ->
                                   Sig en G1 vdash t1 <; t2 dashv G2 ->
                                   Sig en G1 vdash (sel p L) <; t2 dashv G2
                           
  | s_lower : forall Sig G1 t1 p L t2 G2, Sig en G2 vdash p ni (type L sup t2) ->
                                   Sig en G1 vdash t1 <; t2 dashv G2 ->
                                   Sig en G1 vdash t1 <; (sel p L) dashv G2

  | s_struct : forall Sig G1 ds1 ds2 G2 i, i = length G1 ->
                                    i = length G2 ->
                                    Sig en (str ds1)::G1 vdash [c_ i /ss 0] ds1 <;;; [c_ i /ss 0] ds2 dashv (str ds2)::G2 ->
                                    Sig en G1 vdash str ds1 <; str ds2 dashv G2

  where "Sig 'en' G1 'vdash' t1 '<;' t2 'dashv' G2" := (sub Sig G1 t1 t2 G2)

  with
  sub_d : env -> env -> decl_ty -> decl_ty -> env -> Prop :=
  | sd_upper : forall Sig G1 L t1 t2 G2, Sig en G1 vdash t1 <; t2 dashv G2 ->
                                  Sig en G1 vdash (type L ext t1) <;; (type L ext t2) dashv G2
  | sd_lower : forall Sig G1 L t1 t2 G2, Sig en G2 vdash t2 <; t1 dashv G1 ->
                                  Sig en G1 vdash (type L sup t1) <;; (type L sup t2) dashv G2

  where "Sig 'en' G1 'vdash' d1 '<;;' d2 'dashv' G2" := (sub_d Sig G1 d1 d2 G2)

  with
  sub_ds : env -> env -> decl_tys -> decl_tys -> env -> Prop :=
  | sd_nil : forall Sig G1 G2, Sig en G1 vdash dt_nil <;;; dt_nil dashv G2
  | sd_cons : forall Sig G1 d1 ds1 d2 ds2 G2, Sig en G1 vdash d1 <;; d2 dashv G2 ->
                                       Sig en G1 vdash ds1 <;;; ds2 dashv G2 ->
                                       Sig en G1 vdash (dt_con d1 ds1) <;;; (dt_con d2 ds2) dashv G2

  where "Sig 'en' G1 'vdash' ds1 '<;;;' ds2 'dashv' G2" := (sub_ds Sig G1 ds1 ds2 G2).

  Hint Constructors sub sub_d sub_ds.
  
  Scheme sub_mut_ind := Induction for sub Sort Prop
    with sub_s_mut_ind := Induction for sub_d Sort Prop
    with sub_ss_mut_ind := Induction for sub_ds Sort Prop.

  Combined Scheme sub_mutind from sub_mut_ind, sub_s_mut_ind, sub_ss_mut_ind.


  Inductive closed : nat -> var -> Prop :=
  | cl_concrete : forall n x, closed n (Var x)
  | cl_abstract : forall n x, n <> x ->
                         closed n (Abs x).

  Inductive closed_t : nat -> ty -> Prop :=
  | cl_top : forall n, closed_t n top
  | cl_bot : forall n, closed_t n bot
  | cl_sel : forall n p L, closed_p n p ->
                      closed_t n (sel p L)
  | cl_str : forall n ds, closed_ds (S n) ds ->
                     closed_t n (str ds)

  with
  closed_d : nat -> decl_ty -> Prop :=
  | cl_upper : forall n L t, closed_t n t ->
                        closed_d n (type L ext t)
  | cl_lower : forall n L t, closed_t n t ->
                        closed_d n (type L sup t)
  | cl_value : forall n l t, closed_t n t ->
                        closed_d n (val l oft t)

  with
  closed_ds : nat -> decl_tys -> Prop :=
  | cl_nil : forall n, closed_ds n dt_nil
  | cl_cons : forall n d ds, closed_d n d ->
                        closed_ds n ds ->
                        closed_ds n (dt_con d ds)

  with
  closed_p : nat -> exp -> Prop :=
  | cl_var : forall n x, closed n x ->
                    closed_p n (v_ x)
  | cl_loc : forall n i, closed_p n (i_ i)
  | cl_cast : forall n p t, closed_p n p ->
                       closed_t n t ->
                       closed_p n (p cast t).
  
  Reserved Notation "Sig 'en' G 'vdash' e 'hasType' t" (at level 80).
  Reserved Notation "Sig 'en' G 'vdash' d 'hasType_d' s" (at level 80).
  Reserved Notation "Sig 'en' G 'vdash' ds 'hasType_ds' ss" (at level 80).

  
  
  Inductive typing : env -> env -> exp -> ty -> Prop :=
  | t_var : forall  Sig G n t, n mapsto t elem G ->
                        Sig en G vdash (c_ n) hasType t
                          
  | t_loc : forall  Sig G i t, i mapsto t elem Sig ->
                        Sig en G vdash (i_ i) hasType t

  | t_cast : forall Sig G e t t', Sig en G vdash e hasType t'->
                           Sig en G vdash t' <; t dashv G ->
                           Sig en G vdash e cast t hasType t

  | t_fn : forall Sig G t1 e t2, Sig en t1::G vdash ([c_ (length G) /e 0] e) hasType ([c_ (length G) /t 0] t2) ->
                          Sig en G vdash (fn t1 in_exp e off t2) hasType (t1 arr t2)

  | t_app : forall Sig G e e' t1 t2 t', Sig en G vdash e hasType (t1 arr t2) ->
                                 Sig en G vdash e' hasType t' ->
                                 Sig en G vdash t' <; t1 dashv G ->
                                 closed_t 0 t2 ->
                                 Sig en G vdash (e_app e e') hasType t2

  | t_app_path : forall Sig G e p t1 t2 t', Sig en G vdash e hasType (t1 arr t2) ->
                                     Sig en G vdash p pathType t' ->
                                     Sig en G vdash t' <; t1 dashv G ->
                                     Sig en G vdash (e_app e p) hasType ([p cast t1 /t 0] t2)

  | t_new : forall Sig G ds ss, Sig en (str ss)::G vdash ([c_ length G /ds 0] ds) hasType_ds ([c_ length G /ss 0] ss) ->
                         Sig en G vdash new ds hasType str ss

  | t_acc_path : forall Sig G p l t, Sig en G vdash p ni (val l oft t) ->
                              Sig en G vdash (e_acc p l) hasType t

  | t_acc_closed : forall Sig G e l t t', Sig en G vdash e hasType t' ->
                                   Sig en G vdash (val l oft t) cont t' ->
                                   closed_t 0 t ->
                                   Sig en G vdash (e_acc e l) hasType t

  where "Sig 'en' G 'vdash' e 'hasType' t" := (typing Sig G e t)

  with
  typing_d : env -> env -> decl -> decl_ty -> Prop :=
  | td_upper : forall Sig G L t, Sig en G vdash (type L exte t) hasType_d (type L ext t)
  | td_lower : forall Sig G L t, Sig en G vdash (type L supe t) hasType_d (type L sup t)
  | td_val : forall Sig G l e t' t, Sig en G vdash e hasType t' ->
                             Sig en G vdash t' <; t dashv G ->
                             Sig en G vdash (val l assgn e oft t) hasType_d (val l oft t)

  where "Sig 'en' G 'vdash' d 'hasType_d' s" := (typing_d Sig G d s)

  with
  typing_ds : env -> env -> decls -> decl_tys -> Prop :=
  | td_nil : forall Sig G, Sig en G vdash d_nil hasType_ds dt_nil
  | td_con : forall Sig G d ds s ss, Sig en G vdash d hasType_d s ->
                              Sig en G vdash ds hasType_ds ss ->
                              Sig en G vdash (d_con d ds) hasType_ds (dt_con s ss)

  where "Sig 'en' G 'vdash' ds 'hasType_ds' ss" := (typing_ds Sig G ds ss).

  Hint Constructors typing typing_d typing_ds.

  Scheme typing_mut_ind := Induction for typing Sort Prop
    with typing_d_mut_ind := Induction for typing_d Sort Prop
    with typing_ds_mut_ind := Induction for typing_ds Sort Prop.

  Combined Scheme typing_mutind from typing_mut_ind, typing_d_mut_ind, typing_ds_mut_ind.

  Reserved Notation "u 'hasType_u' Sig" (at level 80).

  Inductive store_typing : mu -> env -> Prop :=
  | t_nil : nil hasType_u nil
  | t_con : forall t Sig e u, Sig en nil vdash e hasType t ->
                       u hasType_u Sig ->
                       (e::u) hasType_u (t::Sig)

  where "u 'hasType_u' Sig" := (store_typing u Sig).

  Reserved Notation "Sig 'en' G 'vdash' e 'mem' d" (at level 80).
  
  Inductive member : env -> env -> exp -> decl_ty -> Prop :=
  | mem_path : forall Sig G p d, Sig en G vdash p ni d ->
                          Sig en G vdash p mem d
  | mem_exp : forall Sig G e t d, Sig en G vdash e hasType t ->
                           Sig en G vdash d cont t ->
                           closed_d 0 d ->
                           Sig en G vdash e mem d
                           
  where "Sig 'en' G 'vdash' e 'mem' d" := (member Sig G e d).
  

  Inductive is_value : exp -> Prop :=
  | v_loc : forall i, is_value (i_ i)
  | v_fn : forall t1 e t2, is_value (fn t1 in_exp e off t2)
  | v_cast : forall v t, is_value v ->
                    is_value (v cast t).

  Inductive is_value_d : decl -> Prop :=
  | v_lower : forall L t, is_value_d (type L exte t)
  | v_upper : forall L t, is_value_d (type L supe t)
  | v_value : forall l v t, is_value v ->
                       is_value_d (val l assgn v oft t).

  Inductive is_value_ds : decls -> Prop :=
  | v_nil : is_value_ds d_nil
  | v_con : forall d ds, is_value_d d ->
                    is_value_ds ds ->
                    is_value_ds (d_con d ds).

  Notation "u 'bar' e" := (u, e)(at level 80).
  Reserved Notation "p1 'reduce' p2" (at level 80).
  Reserved Notation "p1 'reduce_d' p2" (at level 80).
  Reserved Notation "p1 'reduce_ds' p2" (at level 80).

  (*Inductive mapsto : mu -> exp -> decls -> Prop :=
  | map_loc : forall u i ds, get i u = Some (new ds) ->
                        mapsto u (i_ i) ds
  | map_cast : forall u v t ds, mapsto u v ds ->
                           mapsto u (v cast t) ds.*)

  Inductive in_ds : decl -> decls -> Prop :=
  | ind_head : forall d ds, in_ds d ds
  | ind_tail : forall d ds d', in_ds d ds ->
                          in_ds d (d_con d' ds).

  Inductive reduction : (mu * exp) -> (mu * exp) -> Prop :=
  | r_new : forall u ds, is_value_ds ds ->
                    (u bar new ds) reduce (u ++ (new ds::nil) bar i_ 0)
                                 
  | r_app : forall u t1 e t2 v, is_value v ->
                           (u bar e_app (fn t1 in_exp e off t2) v) reduce (u bar [v cast t1 /e 0] (e cast t2))

  | r_app_cast : forall u v t1 t2 v', is_value v ->
                                 is_value v' ->
                                 (u bar e_app (v cast (t1 arr t2)) v') reduce (u bar ((e_app v (v' cast t1)) cast ([v' /t 0] t2)))

  | r_acc : forall u i l ds e t, i mapsto (new ds) elem u ->
                            in_ds (val l assgn e oft t) ds ->
                            (u bar e_acc (i_ i) l) reduce (u bar [i_ i /e 0] e)

  | r_acc_cast : forall u Sig v t l t', is_value v ->
                                 u hasType_u Sig ->
                                 Sig en nil vdash v cast t ni (val l oft t') ->
                                 (u bar e_acc (v cast t) l) reduce (u bar ((e_acc v l) cast t'))

  | r_new_ctx : forall u ds u' ds', u bar ds reduce_ds (u' bar ds') ->
                               u bar new ds reduce (u' bar new ds')

  | r_app_ctx_1 : forall u e1 e2 u' e', u bar e1 reduce (u' bar e') ->
                                   u bar e_app e1 e2 reduce (u' bar e_app e' e2)

  | r_app_ctx_2 : forall u e1 e2 u' e', u bar e2 reduce (u' bar e') ->
                                   u bar e_app e1 e2 reduce (u' bar e_app e1 e')

  | r_acc_ctx : forall u e l u' e', u bar e reduce (u' bar e') ->
                               (u bar e_acc e l) reduce (u' bar (e_acc e' l))

  | r_cast_ctx : forall u e t u' e', (u bar e) reduce (u' bar e') -> 
                                (u bar (e cast t)) reduce (u' bar (e' cast t))
      

  where "p1 'reduce' p2" := (reduction p1 p2)
                              
  with
  reduction_d : (mu * decl) -> (mu * decl) -> Prop :=
  | r_val : forall u e u' e' l t, u bar e reduce (u' bar e') ->
                             u bar (val l assgn e oft t) reduce_d (u' bar (val l assgn e' oft t))

  where "p1 'reduce_d' p2" := (reduction_d p1 p2)

  with
  reduction_ds : (mu * decls) -> (mu * decls) -> Prop :=
  | r_head : forall u d ds u' d', u bar d reduce_d (u' bar d') ->
                             u bar (d_con d ds) reduce_ds (u' bar (d_con d' ds))

  | r_tail : forall u d ds u' ds', u bar ds reduce_ds (u' bar ds') ->
                              u bar (d_con d ds) reduce_ds (u' bar (d_con d ds'))

  where "p1 'reduce_ds' p2" := (reduction_ds p1 p2).

  

  Reserved Notation "Sig 'en' G 'vdash' t 'wf_t'" (at level 80).
  Reserved Notation "Sig 'en' G 'vdash' d 'wf_s'" (at level 80).
  Reserved Notation "Sig 'en' G 'vdash' ds 'wf_ss'" (at level 80).
  Reserved Notation "Sig 'en' G 'vdash' e 'wf_e'" (at level 80).
  Reserved Notation "Sig 'en' G 'vdash' d 'wf_d'" (at level 80).
  Reserved Notation "Sig 'en' G 'vdash' ds 'wf_ds'" (at level 80).

  Definition distinct (ss : decl_tys) : Prop :=
    forall s1 s2, in_dty s1 ss ->
             in_dty s2 ss ->
             id_t s1 = id_t s2 ->
             s1 = s2.

  Inductive wf_ty : env -> env -> ty -> Prop :=
  | wf_top : forall Sig G, Sig en G vdash top wf_t
                      
  | wf_bot : forall Sig G, Sig en G vdash bot wf_t
                      
  | wf_arr : forall Sig G t1 t2, Sig en G vdash t1 wf_t ->
                          Sig en t1::G vdash t2 wf_t ->
                          Sig en G vdash (t1 arr t2) wf_t

  | wf_sel_upper : forall Sig G p L t, Sig en G vdash p wf_e ->
                                is_path p ->
                                Sig en G vdash p ni (type L ext t) ->
                                Sig en G vdash (sel p L) wf_t

  | wf_sel_lower : forall Sig G p L t, Sig en G vdash p wf_e ->
                                is_path p ->
                                Sig en G vdash p ni (type L sup t) ->
                                Sig en G vdash (sel p L) wf_t

  | wf_str : forall Sig G ss, Sig en (str ss)::G vdash ([c_ length G /ss 0] ss) wf_ss ->
                       Sig en G vdash (str ss) wf_t

  where "Sig 'en' G 'vdash' t 'wf_t'" := (wf_ty Sig G t)

  with
  wf_decl_ty : env -> env -> decl_ty -> Prop :=
  | wft_upper : forall Sig G L t, Sig en G vdash t wf_t ->
                          Sig en G vdash (type L ext t) wf_s

  | wft_lower : forall Sig G L t, Sig en G vdash t wf_t ->
                          Sig en G vdash (type L sup t) wf_s

  | wft_value : forall Sig G l t, Sig en G vdash t wf_t ->
                           Sig en G vdash (val l oft t) wf_s

  where "Sig 'en' G 'vdash' s 'wf_s'" := (wf_decl_ty Sig G s)

  with
  wf_decl_tys : env -> env -> decl_tys -> Prop :=
  | wft_nil : forall Sig G, Sig en G vdash dt_nil wf_ss
  | wft_con : forall Sig G s ss, Sig en G vdash s wf_s ->
                          Sig en G vdash ss wf_ss ->
                          (forall s', in_dty s' ss ->
                                 id_t s' <> id_t s) ->
                          Sig en G vdash (dt_con s ss) wf_ss

  where "Sig 'en' G 'vdash' ss 'wf_ss'" := (wf_decl_tys Sig G ss)

  with
  wf_exp : env -> env -> exp -> Prop :=
  | wf_var : forall Sig G n, n < length G ->
                      Sig en G vdash (c_ n) wf_e

  | wf_loc : forall Sig G i, i < length Sig ->
                      Sig en G vdash (i_ i) wf_e

  | wf_fn : forall Sig G t1 e t2, Sig en G vdash t1 wf_t ->
                           Sig en t1::G vdash ([c_ length G /e 0] e) wf_e ->
                           Sig en t1::G vdash ([c_ length G /t 0] t2) wf_t ->
                           Sig en t1::G vdash ([c_ length G /e 0] e) hasType ([c_ length G /t 0] t2) ->
                           Sig en G vdash fn t1 in_exp e off t2 wf_e

  | wf_app : forall Sig G e e' t1 t2, Sig en G vdash e wf_e ->
                               Sig en G vdash e' wf_e ->
                               Sig en G vdash e hasType (t1 arr t2) ->
                               Sig en G vdash e' hasType t1 ->
                               Sig en G vdash (e_app e e') wf_e

  | wf_acc : forall Sig G e l t', Sig en G vdash e wf_e ->
                           Sig en G vdash e mem (val l oft t') ->
                           Sig en G vdash e_acc e l wf_e

  | wf_cast : forall Sig G e t t', Sig en G vdash e wf_e ->
                            Sig en G vdash t wf_t ->
                            Sig en G vdash e hasType t' ->
                            Sig en G vdash t' <; t dashv G ->
                            Sig en G vdash e cast t wf_e

  | wf_new : forall Sig G ds ss, Sig en G vdash new ds hasType str ss ->
                          Sig en (str ss)::G vdash ([c_ length G /ds 0] ds) wf_ds ->
                          Sig en G vdash new ds wf_e

  where "Sig 'en' G 'vdash' e 'wf_e'" := (wf_exp Sig G e)

  with
  wf_decl : env -> env -> decl -> Prop :=
  | wfe_upper : forall Sig G L t, Sig en G vdash t wf_t ->
                           Sig en G vdash (type L exte t) wf_d

  | wfe_lower : forall Sig G L t, Sig en G vdash t wf_t ->
                           Sig en G vdash (type L supe t) wf_d

  | wfe_value : forall Sig G l e t, Sig en G vdash e wf_e ->
                             Sig en G vdash t wf_t ->
                             Sig en G vdash (val l assgn e oft t) wf_d

  where "Sig 'en' G 'vdash' d 'wf_d'" := (wf_decl Sig G d)

  with
  wf_decls : env -> env -> decls -> Prop :=
  | wfe_nil : forall Sig G, Sig en G vdash d_nil wf_ds
                       
  | wfe_con : forall Sig G d ds, Sig en G vdash d wf_d ->
                          Sig en G vdash ds wf_ds ->
                          (forall d', in_d d ds ->
                                 id_d d' <> id_d d) ->
                          Sig en G vdash (d_con d ds) wf_ds

  where "Sig 'en' G 'vdash' ds 'wf_ds'" := (wf_decls Sig G ds).

  Reserved Notation "Sig 'evdash' G 'wf_env'" (at level 80).

  Inductive wf_environment : env -> env -> Prop :=
  | wf_nil : forall Sig, Sig evdash nil wf_env
  | wf_con : forall Sig t G, Sig en G vdash t wf_t ->
                      Sig evdash G wf_env ->
                      Sig evdash t::G wf_env

  where "Sig 'evdash' G 'wf_env'" := (wf_environment Sig G).

  Reserved Notation "Sig 'wf_st'" (at level 80).

  Inductive wf_store_typing : env -> Prop :=
  | wfst_nil : nil wf_st
  | wfst_con : forall Sig ds, Sig en nil vdash str ds wf_t ->
                       Sig wf_st ->
                       str ds::Sig wf_st
  where "Sig 'wf_st'" := (wf_store_typing Sig).

  (*get & mapsto*)
  
  Lemma get_empty :
    forall {A : Type} (G : list A) n, G = nil -> get n G = None.
  Proof.
    intros A G n; induction n as [| n']; 
      crush.
  Qed.

  Hint Resolve (get_empty (A:=ty)).
  Hint Rewrite (get_empty (A:=ty)).

  
  Lemma get_map :
    forall {A : Type} (G : list A) n t, get n G = Some t ->
             forall {B : Type} (f : A -> B), get n (map f G) = Some (f t).
  Proof.
    intros A G; induction G as [|t' G']; intros.

    rewrite get_empty in H; crush.

    destruct n as [|n']; crush.
  Qed.

  Hint Resolve (get_map (A:=ty)).
  Hint Rewrite (get_map (A:=ty)).

  
  Lemma get_cons :
    forall {A : Type} n G (t1 t2 : A), get (S n) (t1::G) = Some t2 ->
                                  get n G = Some t2.
  Proof.
    intros A n; induction n as [|n']; intros; crush.
  Qed.

  Hint Resolve (get_cons (A:=ty)).
  Hint Rewrite (get_cons (A:=ty)).
  

  Lemma get_some_index :
    forall A G n (t : A), get n G = Some t ->
                     n < length G.
  Proof.
    intros A G ; induction G as [|t' G'] ; intros.

    rewrite get_empty in H; inversion H; auto.

    destruct n as [|n']; crush.
    simpl in H; inversion H; subst.
    apply gt_n_S.
    apply IHG' with (t:=t); auto.
  Qed.
  
  Lemma get_app :
    forall A G G' n (t : A), get n G = Some t ->
                        get n (G++G') = Some t.
  Proof.
    intros A G; induction G; intros; simpl.
    rewrite get_empty in H; inversion H; auto.

    destruct n as [|n']; auto.

    simpl; simpl in H; auto.
  Qed.

  Hint Resolve get_app.
  
  Lemma get_dec :
    forall A (G : list A) n, {n < length G /\ exists t, get n G = Some t} + {n >= length G /\ get n G = None}.
  Proof.
    intros A G; induction G as [|t' G']; intros.

    right; rewrite get_empty; split; crush.

    destruct n as [|n'];
      [left; crush; exists t'; auto|simpl].

    destruct (IHG' n') as [Hdec|Hdec];
      [left|right]; crush.
  Qed.

  Lemma get_some_app :
    forall A (G1 G2 : list A) n, {(n < length G1) /\ get n (G1 ++ G2) = get n G1} +
               {n >= length G1 /\ get n (G1 ++ G2) = get (n - length G1) G2}.
  Proof.
    intros A G1; induction G1 as [|t' G1']; intros; simpl;
    [right; split;
     [| rewrite <- minus_n_O]; crush|].

    destruct n as [|n'];
      [crush|destruct (IHG1' G2 n') as [Hdec|Hdec]; crush].
  Qed.

  Lemma get_app_l :
    forall A (G1 G2 : list A) n, n < length G1 ->
                            get n (G1++G2) = get n G1.
  Proof.  
    intros A G1; induction G1 as [|t' G1']; intros; auto.
    
    simpl in H.
    inversion H.

    simpl in H.
    destruct n as [|n']; crush.
  Qed.

  Hint Resolve get_app_l.

  Lemma get_app_r :
    forall A (G1 G2 : list A) n, n >= length G1 ->
                            get n (G1++G2) = get (n - length G1) G2.
  Proof.  
    intros A G1; induction G1 as [|t' G1']; intros; simpl; auto.

    rewrite <- minus_n_O; auto.

    destruct n as [|n']; auto.
    unfold ge in H; simpl in H.
    apply le_n_0_eq in H; inversion H.

    unfold ge in H.
    simpl in H; apply le_S_n in H.
    apply (IHG1' G2) in H; auto.
  Qed.

  Hint Resolve get_app_r.


  (*Right Jump/Raise/Substitution*)

  Lemma raise_rjump_distr_mutind :
    (forall t i n m, ((t [i] rjump_t n) raise_t m) = ((t raise_t m) [i] rjump_t n)) /\
    (forall s i n m, ((s [i] rjump_s n) raise_s m) = ((s raise_s m) [i] rjump_s n)) /\
    (forall ss i n m, ((ss [i] rjump_ss n) raise_ss m) = ((ss raise_ss m) [i] rjump_ss n)) /\
    (forall e i n m, ((e [i] rjump_e n) raise_e m) = ((e raise_e m) [i] rjump_e n)) /\
    (forall d i n m, ((d [i] rjump_d n) raise_d m) = ((d raise_d m) [i] rjump_d n)) /\
    (forall ds i n m, ((ds [i] rjump_ds n) raise_ds m) = ((ds raise_ds m) [i] rjump_ds n)).
  Proof.
    apply type_exp_mutind; intros;
      try solve [crush].

    destruct v as [r|r]; auto.
    
  Qed.

  Lemma raise_rjump_distr_type :
    (forall t i n m, ((t [i] rjump_t n) raise_t m) = ((t raise_t m) [i] rjump_t n)).
  Proof.
    destruct raise_rjump_distr_mutind; crush.
  Qed.

  Lemma raise_rjump_distr_decl_ty :
    (forall s i n m, ((s [i] rjump_s n) raise_s m) = ((s raise_s m) [i] rjump_s n)).
  Proof.
    destruct raise_rjump_distr_mutind; crush.
  Qed.

  Lemma raise_rjump_distr_decl_tys :
    (forall ss i n m, ((ss [i] rjump_ss n) raise_ss m) = ((ss raise_ss m) [i] rjump_ss n)).
  Proof.
    destruct raise_rjump_distr_mutind; crush.
  Qed.

  Lemma raise_rjump_distr_exp :
    (forall e i n m, ((e [i] rjump_e n) raise_e m) = ((e raise_e m) [i] rjump_e n)).
  Proof.
    destruct raise_rjump_distr_mutind; crush.
  Qed.

  Lemma raise_rjump_distr_decl :
    (forall d i n m, ((d [i] rjump_d n) raise_d m) = ((d raise_d m) [i] rjump_d n)).
  Proof.
    destruct raise_rjump_distr_mutind; crush.
  Qed.

  Lemma raise_rjump_distr_decls :
    (forall ds i n m, ((ds [i] rjump_ds n) raise_ds m) = ((ds raise_ds m) [i] rjump_ds n)).
  Proof.
    destruct raise_rjump_distr_mutind; crush.
  Qed.
    

  Lemma rjump_subst_distr_mutind :
    (forall t p n i m, (([p /t n] t) [i] rjump_t m) = [(p [i] rjump_e m) /t n] (t [i] rjump_t m)) /\ 
    (forall s p n i m, (([p /s n] s) [i] rjump_s m) = [(p [i] rjump_e m) /s n] (s [i] rjump_s m)) /\
    (forall ss p n i m, (([p /ss n] ss) [i] rjump_ss m) = [(p [i] rjump_e m) /ss n] (ss [i] rjump_ss m)) /\
    (forall e p n i m, (([p /e n] e) [i] rjump_e m) = [(p [i] rjump_e m) /e n] (e [i] rjump_e m)) /\
    (forall d p n i m, (([p /d n] d) [i] rjump_d m) = [(p [i] rjump_e m) /d n] (d [i] rjump_d m)) /\
    (forall ds p n i m, (([p /ds n] ds) [i] rjump_ds m) = [(p [i] rjump_e m) /ds n] (ds [i] rjump_ds m)).
  Proof.
    apply type_exp_mutind; intros;
      try solve [simpl;
                 rewrite raise_rjump_distr_exp;
                 crush];
      try solve [crush].

    simpl.
    destruct v as [r|r]; auto; simpl.
    destruct (Nat.eq_dec n r) as [Heq|Heq];
      subst;
      [rewrite <- beq_nat_refl; auto|].
    destruct (Nat.eqb_neq n r) as [Htemp Hbeq];
      apply Hbeq in Heq;
      rewrite Heq; auto.
  Qed.

  Lemma rjump_subst_distr_type :
    (forall t p n i m, (([p /t n] t) [i] rjump_t m) = [(p [i] rjump_e m) /t n] (t [i] rjump_t m)).
  Proof.
    destruct rjump_subst_distr_mutind; crush.
  Qed.

  Lemma rjump_subst_distr_decl_ty :
    (forall s p n i m, (([p /s n] s) [i] rjump_s m) = [(p [i] rjump_e m) /s n] (s [i] rjump_s m)).
  Proof.
    destruct rjump_subst_distr_mutind; crush.
  Qed.

  Lemma rjump_subst_distr_decl_tys :
    (forall ss p n i m, (([p /ss n] ss) [i] rjump_ss m) = [(p [i] rjump_e m) /ss n] (ss [i] rjump_ss m)).
  Proof.
    destruct rjump_subst_distr_mutind; crush.
  Qed.

  Lemma rjump_subst_distr_exp :
    (forall e p n i m, (([p /e n] e) [i] rjump_e m) = [(p [i] rjump_e m) /e n] (e [i] rjump_e m)).
  Proof.
    destruct rjump_subst_distr_mutind; crush.
  Qed.

  Lemma rjump_subst_distr_decl :
    (forall d p n i m, (([p /d n] d) [i] rjump_d m) = [(p [i] rjump_e m) /d n] (d [i] rjump_d m)).
  Proof.
    destruct rjump_subst_distr_mutind; crush.
  Qed.

  Lemma rjump_subst_distr_decls :
    (forall ds p n i m, (([p /ds n] ds) [i] rjump_ds m) = [(p [i] rjump_e m) /ds n] (ds [i] rjump_ds m)).
  Proof.
    destruct rjump_subst_distr_mutind; crush.
  Qed.

  Lemma in_dty_rjump :
    forall d ds, in_dty d ds -> forall i n, in_dty (d [i] rjump_s n) (ds [i] rjump_ss n).
  Proof.
    intros d ds Hin; induction Hin; intros.

    simpl; apply in_head_dty.

    simpl; apply in_tail_dty; auto.
  Qed.
        
  
  Lemma closed_subst_type :
    forall n t, closed_t n t -> forall e, ([e /t n] t) = t.
  Proof.
  Admitted.

  Lemma path_typing_uniqueness :
    forall Sig G p t, Sig en G vdash p pathType t ->
               forall t', Sig en G vdash p pathType t' ->
                     t' = t.
  Proof.
    intros Sig G p t Htyp;
      induction Htyp; intros t' Htyp;
        try solve [inversion Htyp; subst; rewrite H3 in H; inversion H; auto].
    inversion Htyp; auto.
  Qed.

  (*Weakening*)

  Lemma mapping_weakening :
    forall G r t, r mapsto t elem G ->
             forall G1 G2,
               G = G1 ++ G2 ->
               forall i n G',
                 i = length G2 ->
                 n = length G' ->
                 (r [i] rjump_n n) mapsto (t [i] rjump_t n) elem ((G1 [i] rjump_env n) ++ G' ++ (G2 [i] rjump_env n)).
  Proof.
    intros; subst.

    unfold mapping.

    rewrite rev_app_distr.
    unfold right_jump_n.
    destruct (le_gt_dec (length G2) r);
      [rewrite leb_correct|
       rewrite leb_correct_conv]; auto.
    rewrite get_app_r; unfold right_jump_env.
    rewrite rev_length, app_length, map_length, Nat.sub_add_distr.

    rewrite <- Nat.add_sub_assoc;
      [rewrite Nat.sub_diag, plus_0_r|auto].
    rewrite <- map_rev.
    unfold mapping in H.
    rewrite rev_app_distr in H.
    rewrite get_app_r, rev_length in H.
    apply get_map with (f:=(fun t0 : ty => t0 [length G2]rjump_t length G')) in H; auto.

    rewrite rev_length; crush.
    rewrite rev_length, app_length, map_length; crush.

    rewrite get_app_l;
      [|unfold right_jump_env;
        rewrite rev_length, app_length, map_length;
        crush].
    unfold right_jump_env.
    rewrite rev_app_distr, get_app_l;
      [|rewrite rev_length, map_length; auto].
    rewrite <- map_rev.
    unfold mapping in H.
    rewrite rev_app_distr in H.
    rewrite get_app_l in H;
      [|rewrite rev_length; auto].
    apply get_map with (f:=(fun t0 : ty => t0 [length G2]rjump_t length G')) in H; auto.
    
  Qed.

  Lemma typing_p_weakening :
    forall Sig G p t, Sig en G vdash p pathType t ->
               forall G1 G2, G = G1 ++ G2 ->
                        forall i n G', i = length G2 ->
                                  n = length G' ->
                                  (Sig [i] rjump_env n) en (G1 [i] rjump_env n) ++ G' ++ (G2 [i] rjump_env n) vdash (p [i] rjump_e n) pathType (t [i] rjump_t n).
  Proof.

    intros; induction H.
    
    simpl.
    apply pt_var.

    apply mapping_weakening with (G:=G); crush.

    simpl.
    apply pt_loc.
    apply get_map with (f:=fun (t : ty) => t [i] rjump_t n) in H.
    rewrite map_rev in H.
    crush.

    crush.
    
  Qed.

  Lemma has_contains_weakening_mutind :
    (forall Sig G p d, Sig en G vdash p ni d ->
                forall G1 G2,
                  G = G1 ++ G2 ->
                  forall i n G',
                    i = length G2 ->
                    n = length G' ->
                    (Sig [i] rjump_env n) en (G1 [i] rjump_env n) ++ G' ++ (G2 [i] rjump_env n) vdash (p [i] rjump_e n) ni (d [i] rjump_s n)) /\
    (forall Sig G t d, Sig en G vdash d cont t ->
                forall G1 G2,
                  G = G1 ++ G2 ->
                  forall i n G',
                    i = length G2 ->
                    n = length G' ->
                    (Sig [i] rjump_env n) en (G1 [i] rjump_env n) ++ G' ++ (G2 [i] rjump_env n) vdash (d [i] rjump_s n) cont (t [i] rjump_t n)).
  Proof.
    apply has_contains_mutind; intros.

    simpl.
    rewrite rjump_subst_distr_decl_ty.
    apply has_path with (t:=t [i] rjump_t n); auto.
    apply typing_p_weakening with (G:=G1 ++ G2); subst; auto.

    simpl; apply cont_struct.
    apply in_dty_rjump; auto.

    rewrite rjump_subst_distr_decl_ty; simpl.
    apply cont_upper; crush.
  Qed.

  Lemma has_weakening :
    (forall Sig G p d, Sig en G vdash p ni d ->
                forall G1 G2,
                  G = G1 ++ G2 ->
                  forall i n G',
                    i = length G2 ->
                    n = length G' ->
                    (Sig [i] rjump_env n) en (G1 [i] rjump_env n) ++ G' ++ (G2 [i] rjump_env n) vdash (p [i] rjump_e n) ni (d [i] rjump_s n)).
  Proof.
    destruct has_contains_weakening_mutind; crush.
  Qed.

  Lemma contains_weakening :
    (forall Sig G p d, Sig en G vdash p ni d ->
                forall G1 G2,
                  G = G1 ++ G2 ->
                  forall i n G',
                    i = length G2 ->
                    n = length G' ->
                    (Sig [i] rjump_env n) en (G1 [i] rjump_env n) ++ G' ++ (G2 [i] rjump_env n) vdash (p [i] rjump_e n) ni (d [i] rjump_s n)).
  Proof.
    destruct has_contains_weakening_mutind; crush.
  Qed.

  Lemma sub_weakening_mutind :
    (forall Sig G1 t1 t2 G2,
        Sig en G1 vdash t1 <; t2 dashv G2 ->
        forall G3 G4 G5 G6 G G',
          G1 = G3 ++ G4 ->
          G2 = G5 ++ G6 ->
          forall i n,
            i = length G4 -> i = length G6 ->
            n = length G -> n = length G' ->
            (Sig [i] rjump_env n) en (G3 [i] rjump_env n) ++ G ++ (G4 [i] rjump_env n) vdash (t1 [i] rjump_t n) <; (t2 [i] rjump_t n) dashv (G5 [i] rjump_env n) ++ G' ++ (G6 [i] rjump_env n)) /\
    
    (forall Sig G1 s1 s2 G2,
        Sig en G1 vdash s1 <;; s2 dashv G2 ->
        forall G3 G4 G5 G6 G G',
          G1 = G3 ++ G4 ->
          G2 = G5 ++ G6 ->
          forall i n,
            i = length G4 -> i = length G6 ->
            n = length G -> n = length G' ->
            (Sig [i] rjump_env n) en (G3 [i] rjump_env n) ++ G ++ (G4 [i] rjump_env n) vdash (s1 [i] rjump_s n) <;; (s2 [i] rjump_s n) dashv (G5 [i] rjump_env n) ++ G' ++ (G6 [i] rjump_env n)) /\
      
    (forall Sig G1 ss1 ss2 G2,
        Sig en G1 vdash ss1 <;;; ss2 dashv G2 ->
        forall G3 G4 G5 G6 G G',
          G1 = G3 ++ G4 ->
          G2 = G5 ++ G6 ->
          forall i n,
            i = length G4 -> i = length G6 ->
            n = length G -> n = length G' ->
            (Sig [i] rjump_env n) en (G3 [i] rjump_env n) ++ G ++ (G4 [i] rjump_env n) vdash (ss1 [i] rjump_ss n) <;;; (ss2 [i] rjump_ss n) dashv (G5 [i] rjump_env n) ++ G' ++ (G6 [i] rjump_env n)).
  Proof.
    apply sub_mutind; intros;
      try solve [crush].
    
    (*s-upper*)
    simpl; apply s_upper with (t1:=t1 [i] rjump_t n); auto.
    apply has_weakening with (G1:=G3)(G2:=G4)(i:=i)(n:=n)(G':=G) in h; auto.
    
    (*s-lower*)
    simpl; apply s_lower with (t2:=t2 [i] rjump_t n); auto.
    apply has_weakening with (G1:=G5)(G2:=G6)(i:=i)(n:=n)(G':=G') in h; auto.

    simpl; apply s_struct with (i:=length (G3 ++ G ++ G4)).
    repeat (rewrite app_length);
      unfold right_jump_env;
      repeat (rewrite map_length);
      auto.
    assert (Hleng : length G3 = length G5);
      [subst;
       repeat rewrite app_length in e0;
       rewrite H3 in e0;
       crush|].
    repeat (rewrite app_length);
      unfold right_jump_env;
      repeat (rewrite map_length);
      rewrite Hleng, <- H2, H3, <- H4, H5; auto.
    assert (Hsub : (Sig [i0]rjump_env n) en (((str ds1)::G3) [i0]rjump_env n) ++ G ++ (G4 [i0]rjump_env n) vdash
                               ([v_ Var i /ss 0] ds1) [i0]rjump_ss n <;;; ([v_ Var i /ss 0] ds2) [i0]rjump_ss n
                               dashv (((str ds2)::G5) [i0]rjump_env n) ++ G' ++ (G6 [i0]rjump_env n)).
    apply H; auto.
    subst; auto.
    subst; auto.
    repeat (rewrite rjump_subst_distr_decl_tys in Hsub).
    assert (Hleng : i0 <= i);
      [rewrite e, H2, H0, app_length; crush|].
    apply Nat.leb_le in Hleng.
    simpl in Hsub;
      unfold right_jump_n in Hsub;
      rewrite Hleng in Hsub.
    repeat rewrite app_length.
    assert ((length G3 + (length G + length G4)) = (length G + (length G3 + length G4))); [crush|].
    rewrite H6, <- app_length, <- H0, <- e, <- H4, plus_comm.
    crush.
  Qed.

  Lemma sub_weakening_exp :
    (forall Sig G1 t1 t2 G2,
        Sig en G1 vdash t1 <; t2 dashv G2 ->
        forall G3 G4 G5 G6 G G',
          G1 = G3 ++ G4 ->
          G2 = G5 ++ G6 ->
          forall i n,
            i = length G4 -> i = length G6 ->
            n = length G -> n = length G' ->
            (Sig [i] rjump_env n) en (G3 [i] rjump_env n) ++ G ++ (G4 [i] rjump_env n) vdash (t1 [i] rjump_t n) <; (t2 [i] rjump_t n) dashv (G5 [i] rjump_env n) ++ G' ++ (G6 [i] rjump_env n)).
  Proof.
    destruct sub_weakening_mutind; crush.
  Qed.

  Lemma sub_weakening_decl :
    
    (forall Sig G1 s1 s2 G2,
        Sig en G1 vdash s1 <;; s2 dashv G2 ->
        forall G3 G4 G5 G6 G G',
          G1 = G3 ++ G4 ->
          G2 = G5 ++ G6 ->
          forall i n,
            i = length G4 -> i = length G6 ->
            n = length G -> n = length G' ->
            (Sig [i] rjump_env n) en (G3 [i] rjump_env n) ++ G ++ (G4 [i] rjump_env n) vdash (s1 [i] rjump_s n) <;; (s2 [i] rjump_s n) dashv (G5 [i] rjump_env n) ++ G' ++ (G6 [i] rjump_env n)).
  Proof.
    destruct sub_weakening_mutind; crush.
  Qed.

  Lemma sub_weakening_decls :
      
    (forall Sig G1 ss1 ss2 G2,
        Sig en G1 vdash ss1 <;;; ss2 dashv G2 ->
        forall G3 G4 G5 G6 G G',
          G1 = G3 ++ G4 ->
          G2 = G5 ++ G6 ->
          forall i n,
            i = length G4 -> i = length G6 ->
            n = length G -> n = length G' ->
            (Sig [i] rjump_env n) en (G3 [i] rjump_env n) ++ G ++ (G4 [i] rjump_env n) vdash (ss1 [i] rjump_ss n) <;;; (ss2 [i] rjump_ss n) dashv (G5 [i] rjump_env n) ++ G' ++ (G6 [i] rjump_env n)).
  Proof.
    destruct sub_weakening_mutind; crush.
  Qed.

  Lemma typing_weakening_mutind :
    (forall Sig G e t, Sig en G vdash e hasType t ->
                forall G1 G2,
                  G = G1 ++ G2 ->
                  forall G' i n,
                    i = length G2 ->
                    n = length G' ->
                    (Sig [i] rjump_env n) en (G1 [i] rjump_env n) ++ G' ++ (G2 [i] rjump_env n) vdash (e [i] rjump_e n) hasType (t [i] rjump_t n)) /\
      
    (forall Sig G d s, Sig en G vdash d hasType_d s ->
                forall G1 G2,
                  G = G1 ++ G2 ->
                  forall G' i n,
                    i = length G2 ->
                    n = length G' ->
                    (Sig [i] rjump_env n) en (G1 [i] rjump_env n) ++ G' ++ (G2 [i] rjump_env n) vdash (d [i] rjump_d n) hasType_d (s [i] rjump_s n)) /\
    
    (forall Sig G ds ss, Sig en G vdash ds hasType_ds ss ->
                  forall G1 G2,
                    G = G1 ++ G2 ->
                    forall G' i n,
                      i = length G2 ->
                      n = length G' ->
                      (Sig [i] rjump_env n) en (G1 [i] rjump_env n) ++ G' ++ (G2 [i] rjump_env n) vdash (ds [i] rjump_ds n) hasType_ds (ss [i] rjump_ss n)).
  Proof.
    apply typing_mutind; intros;
      try solve [crush].

    (*t-var*)
    apply t_var, mapping_weakening with (G:=G); auto.

    (*t-loc*)
    apply t_loc.
    apply get_map with (f:=fun (t0 : ty) => t0 [i0] rjump_t n) in e.
    rewrite map_rev in e; auto.

    (*t-cast*)
    simpl; apply t_cast with (t':=t' [i] rjump_t n); auto.
    apply sub_weakening_exp with (G1:=G1++G2)(G2:=G1++G2); subst; auto.

    (*t-arr*)
    
  Qed.
    
  Lemma typing_p_wf :
    forall Sig G p t, Sig en G vdash p pathType t ->
               Sig en G vdash p wf_e ->
               Sig evdash G wf_env ->
               Sig wf_st ->
               Sig en G vdash t wf_t.
  Proof.
    intros.

    inversion H; subst.

    
    
  Qed.

  Lemma member_uniqueness_mutind :
    (forall Sig G p d, Sig en G vdash p ni d ->
                Sig en G vdash p wf_e ->
                forall d', Sig en G vdash p ni d' ->
                      id_t d' = id_t d ->
                      d' = d) /\
    (forall Sig G t d, Sig en G vdash d cont t ->
                Sig en G vdash t wf_t ->
                forall d', Sig en G vdash d' cont t ->
                      id_t d' = id_t d ->
                      d' = d).
  Proof.
    apply has_contains_mutind; intros.

    inversion H1; subst.
    apply path_typing_uniqueness with (t:=t) in H3; auto; subst.
    apply H in H4; subst; auto.
    admit. (*typing_p wf*)
    admit. (*subst preserves id*)

    admit. (*wf decl_tys distinct*)
    
    inversion H2; subst.
    apply H in H8; inversion H8; subst; auto.
    apply H0 in H10; subst; auto.
    admit. (*member wf*)
    admit. (*subst preserves id*)
    inversion H1; auto.
    rewrite H4; auto.
  Qed.

  
  Lemma type_uniqueness_decl :
    (forall Sig G d s, Sig en G vdash d hasType_d s ->
                forall G' S' s', S' en G' vdash d hasType_d s' ->
                            s' = s).
  Proof.
    intros.
    induction H;
      try solve [inversion H0; auto].
  Qed.

  Lemma type_uniqueness_decls :
    (forall Sig G ds ss, Sig en G vdash ds hasType_ds ss ->
                forall G' S' ss', S' en G' vdash ds hasType_ds ss' ->
                             ss' = ss).
  Proof.
    intros Sig G ds ss Htyp.
    induction Htyp; intros;
      try solve [inversion H; auto].
    inversion H0; subst.
    apply type_uniqueness_decl with (Sig:=Sig)(G:=G)(s:=s) in H5; auto; subst.
    apply IHHtyp in H7; subst; auto.
  Qed.

  Lemma type_uniqueness_type :
    (forall Sig G e t, Sig en G vdash e hasType t ->
                forall t', Sig en G vdash e hasType t' ->
                      t' = t).
  Proof.
    intros Sig G e t Htyp;
      induction Htyp; intros;
        try solve [inversion H0; rewrite H4 in H; inversion H; auto];
        try solve [inversion H0; auto];
        try solve [inversion H; auto].

    (*t-app*)
    inversion H1; subst;
    apply IHHtyp1 in H4; inversion H4; subst; auto.
    rewrite closed_subst_type; auto.

    (*t-app-path*)
    inversion H1; subst;
    apply IHHtyp in H4; inversion H4; subst; auto.
    rewrite closed_subst_type; auto.

    (*t-new*)
    inversion H0; subst.
    apply type_uniqueness_decls with (Sig:=Sig)(G:=str ss :: G)(ss:=ss) in H4;
      subst; auto.

    (*t-path*)
    

  Qed.
    
    
  Theorem preservation :
    (forall Sig G e t, Sig en G vdash e hasType t ->
                forall u u' e' S, u' hasType_u S ++ Sig ->
                             u bar e reduce (u' bar e') ->
                             S ++ Sig en G vdash e' hasType t) /\
    (forall Sig G d s, Sig en G vdash d hasType_d s ->
                forall u u' d' S, u' hasType_u S ++ Sig ->
                             u bar d reduce_d (u' bar d') ->
                             S ++ Sig en G vdash d' hasType_d s) /\
   (forall Sig G ds ss, Sig en G vdash ds hasType_ds ss ->
                 forall u u' ds' S, u' hasType_u S ++ Sig ->
                               u bar ds reduce_ds (u' bar ds') ->
                               S ++ Sig en G vdash ds' hasType_ds ss).
  
  Proof.
    apply typing_mutind; intros;
      try solve [inversion H0];
      try solve [inversion H1].

    inversion H1; subst.
    apply t_cast with (t':=t'); auto.

    apply H with (u:=u)(u':=u'); auto.

    admit. (*weakening*)

    inversion H2; subst.

    (*r_app*)
    inversion t; subst.
    rewrite closed_subst_type; auto.
    apply t_cast with (t':=).
    
    admit. (*r_app*)
    admit. (*r_app_cast*)
    admit. (*r_app_ctx1*)
    admit. (*r_app_ctx2*)
    admit. (**)
    
  Qed.
    
  
  

  Inductive ge_var : var -> nat -> Prop :=
  | ge_concrete : forall r n, n <= r ->
                         ge_var (c_ r) n
  | ge_abstract : forall r n, ge_var (a_ r) n.

  Inductive ge_type : ty -> nat -> Prop :=
  | ge_top : forall n, ge_type top n
  | ge_bot : forall n, ge_type bot n
  | ge_arr : forall n t1 t2, ge_type t1 n ->
                        ge_type t2 (S n) ->
                        ge_type (t1 arr t2) n
  | ge_sel : forall p l n, ge_var p n ->
                      ge_type (sel p l) n
  | ge_str : forall ds n, ge_decl_tys ds (S n) ->
                     ge_type (str ds) n

  with
  ge_decl_ty : decl_ty -> nat -> Prop :=
  | ge_low_d : forall l t n, ge_type t n ->
                        ge_decl_ty (type l sup t) n
  | ge_upp_d : forall l t n, ge_type t n ->
                        ge_decl_ty (type l ext t) n
  | ge_val_d : forall l t n, ge_type t n ->
                        ge_decl_ty (val l ofv t) n

  with
  ge_decl_tys : decl_tys -> nat -> Prop :=
  | ge_nil_dt : forall n, ge_decl_tys dt_nil n 
  | ge_con_dt : forall n d ds, ge_decl_ty d n ->
                          ge_decl_tys ds n -> 
                          ge_decl_tys (dt_con d ds) n.

  Hint Constructors ge_type ge_decl_ty ge_decl_tys ge_var.

  Scheme ge_ty_mutind := Induction for ge_type Sort Prop
    with ge_decl_ty_mutind := Induction for ge_decl_ty Sort Prop
    with ge_decl_tys_mutind := Induction for ge_decl_tys Sort Prop.

  Combined Scheme ge_mutind from ge_ty_mutind, ge_decl_ty_mutind, ge_decl_tys_mutind.

  Inductive ge_env : env -> nat -> Prop :=
  | ge_nil : forall n, ge_env nil n
  | ge_cons : forall t G n, ge_type t n ->
                       ge_env G n ->
                       ge_env (t::G) n.

  (*there exists a variable in t, d or p that is less than n*)
                      
  

  Reserved Notation "n 'notin_t' t" (at level 80).
  Reserved Notation "n 'notin_dt' d" (at level 80).
  Reserved Notation "n 'notin_dts' p" (at level 80).
  Reserved Notation "n 'notin_v' v" (at level 80).

  Inductive notin_var : nat -> var -> Prop :=
  | ni_abs : forall n m, n notin_v (a_ m)
  | ni_con : forall n m, n <> m ->
                    n notin_v (c_ m)
                      where "n 'notin_v' p" := (notin_var n p).
  
  Inductive notin_ty : nat -> ty -> Prop :=
  | ni_top : forall n, n notin_t top
  | ni_bot : forall n, n notin_t bot
  | ni_arr : forall n t1 t2, n notin_t t1 ->
                          (S n) notin_t t2 ->
                          n notin_t (t1 arr t2)
  | ni_sel : forall n x l, n notin_v x ->
                      n notin_t (sel x l)
  | ni_str : forall n ds, (S n) notin_dts ds ->
                     n notin_t (str ds)
                       where "n 'notin_t' t" := (notin_ty n t)

  with
  notin_decl_ty : nat -> decl_ty -> Prop :=
  | ni_low_dt : forall n l t, n notin_t t ->
                         n notin_dt (type l sup t)
  | ni_upp_dt : forall n l t, n notin_t t ->
                         n notin_dt (type l ext t)
  | ni_val_dt : forall n l t, n notin_t t ->
                         n notin_dt (val l ofv t)
                           where "n 'notin_dt' d" := (notin_decl_ty n d)

  with
  notin_decl_tys : nat -> decl_tys -> Prop :=
  | ni_nil_dt : forall n, n notin_dts dt_nil
  | ni_con_dt : forall n d ds, n notin_dt d ->
                          n notin_dts ds ->
                          n notin_dts (dt_con d ds)
                          where "n 'notin_dts' d" := (notin_decl_tys n d)

  (*with
  notin_path : nat -> path -> Prop :=
  | ni_abs : forall n m, n notin_p (a_ m)
  | ni_con : forall n m, n <> m ->
                    n notin_p (c_ m)
  | ni_cast : forall n p t, n notin_p p ->
                       n notin_t t ->
                       n notin_p (p cast t)
                         where "n 'notin_p' p" := (notin_path n p)*).

  Hint Constructors notin_var notin_ty notin_decl_ty notin_decl_tys.

  Scheme notin_ty_mutind := Induction for notin_ty Sort Prop
    with notin_decl_ty_mutind := Induction for notin_decl_ty Sort Prop
    with notin_decl_tys_mutind := Induction for notin_decl_tys Sort Prop.

  Combined Scheme notin_mutind from notin_ty_mutind, notin_decl_ty_mutind, notin_decl_tys_mutind.

  Reserved Notation "n 'notin_e' G" (at level 80).

  Inductive notin_env : nat -> env -> Prop :=
  | ni_nil : forall n, n notin_e nil
  | ni_cons_O : forall G t, O notin_e (t::G)
  | ni_cons_S : forall n G t, n notin_t t ->
                         n notin_e G ->
                         (S n) notin_e (t::G)
                         where "n 'notin_e' G" := (notin_env n G).

  Reserved Notation "G 'vdash' t 'wf_t'" (at level 80).
  Reserved Notation "G 'vdash' d 'wf_d'" (at level 80).
  Reserved Notation "G 'vdash' ds 'wf_ds'" (at level 80).
  Reserved Notation "G 'vdash' p 'wf_v'" (at level 80).

  Inductive closed_v : var -> nat -> Prop :=
  | concrete_closed : forall r n, closed_v (c_ r) n
  | abstract_closed : forall r n, r <= n ->
                             closed_v (a_ r) n.

  Inductive closed_ty : ty -> nat -> Prop :=
  | top_closed : forall n, closed_ty top n
  | bot_closed : forall n, closed_ty bot n
  | arr_closed : forall t1 t2 n, closed_ty t1 n ->
                            closed_ty t2 (S n) ->
                            closed_ty (t1 arr t2) n
  | sel_closed : forall v l n, closed_v v n ->
                          closed_ty (sel v l) n
  | str_closed : forall ds n, closed_dts ds (S n) ->
                         closed_ty (str ds) n

  with
  closed_dt : decl_ty -> nat -> Prop :=
  | lower_closed : forall l t n, closed_ty t n ->
                            closed_dt (type l sup t) n
  | upper_closed : forall l t n, closed_ty t n ->
                            closed_dt (type l ext t) n
  | value_closed : forall f t n, closed_ty t n ->
                            closed_dt (val f ofv t) n

  with
  closed_dts : decl_tys -> nat -> Prop :=
  | nil_closed : forall n, closed_dts dt_nil n
  | con_closed : forall d ds n, closed_dt d n ->
                           closed_dts ds n ->
                           closed_dts (dt_con d ds) n.

  Hint Constructors closed_v closed_ty closed_dt closed_dts.

  Inductive closed_env : env -> nat -> Prop :=
  | empty_closed : forall n, closed_env nil n
  | cons_closed : forall t G n, closed_ty t n ->
                           closed_env G n ->
                           closed_env (t::G) n.

  Hint Constructors closed_env.

  Inductive wf_var : env -> var -> Prop :=
  | wf_variable : forall G r, r < length G ->
                         G vdash c_ r wf_v
                           
                           where "G 'vdash' v 'wf_v'" := (wf_var G v).
  
  Inductive wf_ty : env -> ty -> Prop := 
  | wf_top : forall G, G vdash top wf_t
  | wf_bot : forall G, G vdash bot wf_t
  | wf_arr : forall G t1 t2, G vdash t1 wf_t ->
                        (t1)::G vdash t2 wf_t ->
                        0 notin_t t2 ->
                        G vdash (t1 arr t2)  wf_t
  | wf_sel_lower : forall G x l t, G vdash x ni (type l sup t) ->
                              G vdash x wf_v ->
                              G vdash (sel x l) wf_t
  | wf_sel_upper : forall G x l t, G vdash x ni (type l ext t) ->
                              G vdash x wf_v ->
                              G vdash (sel x l) wf_t
  | wf_struct : forall G ds, (str ds)::G vdash ([ c_ O /dts O] ds) wf_ds ->
                        0 notin_dts ds ->
                        G vdash (str ds) wf_t

  where "G 'vdash' t 'wf_t'" := (wf_ty G t)

  with
  wf_decl_ty : env -> decl_ty -> Prop :=
  | wf_low : forall G l t, G vdash t wf_t ->
                      G vdash (type l sup t) wf_d
  | wf_upp : forall G l t, G vdash t wf_t ->
                      G vdash (type l ext t) wf_d
  | wf_val : forall G l t, G vdash t wf_t ->
                      G vdash (val l ofv t) wf_d

  where "G 'vdash' d 'wf_d'" := (wf_decl_ty G d)

  with
  wf_decl_tys : env -> decl_tys -> Prop :=
  | wf_nil : forall G, G vdash dt_nil wf_ds
  | wf_con : forall G d ds, G vdash d wf_d ->
                       G vdash ds wf_ds ->
                       (forall d', in_dty d' ds -> id d' <> id d) ->
                       G vdash (dt_con d ds) wf_ds

  where "G 'vdash' d 'wf_ds'" := (wf_decl_tys G d)

  (*with
  wf_var : env -> path -> Prop :=
  | wf_var : forall G r, r < length G ->
                    G vdash c_ r wf_p
  | wf_cast : forall G p t, G vdash p wf_p ->
                       G vdash t wf_t ->
                       G vdash p cast t wf_p

                         where "G 'vdash' p 'wf_p'" := (wf_path G p)*).

  Hint Constructors wf_ty wf_decl_ty wf_decl_tys.

  Reserved Notation "G 'wf_e'" (at level 80).
  
  Inductive wf_env : env -> Prop :=
  | wf_nil_env : nil wf_e
  | wf_con_env : forall G t, G vdash t wf_t ->
                        G wf_e ->
                        t::G wf_e

  where "G 'wf_e'" := (wf_env G).
  
  Scheme wf_ty_mutind := Induction for wf_ty Sort Prop
    with wf_decl_ty_mutind := Induction for wf_decl_ty Sort Prop
    with wf_decl_tys_mutind := Induction for wf_decl_tys Sort Prop.

  Combined Scheme wf_mutind from wf_ty_mutind, wf_decl_ty_mutind, wf_decl_tys_mutind.

 (* Lemma lt_not_ge_mutind :
    (forall t n, (lt_type t n -> ~ ge_type t n)) /\
    (forall d n, (lt_decl d n -> ~ ge_decl d n)) /\
    (forall p n, (lt_path p n -> ~ ge_path p n)).
  Proof.
    apply type_mutind; intros; intro Hcontra.
    
    inversion H0; subst; apply H in H2; inversion Hcontra; subst; auto.
    
    inversion H0; subst; apply H in H4; inversion Hcontra; subst; auto.

    inversion H.

    inversion H.
    
    inversion H0; subst; apply H in H4; inversion Hcontra; subst; auto.
    
    inversion H0; subst; apply H in H4; inversion Hcontra; subst; auto.

    destruct v as [x|x].
    inversion Hcontra; inversion H; crush.

    inversion H.
    
    inversion H1; inversion Hcontra; subst.
    apply H in H5; auto.
    apply H0 in H5; auto.
  Qed.

  Lemma not_lt_ge_mutind :
    (forall t n, (~ lt_type t n -> ge_type t n)) /\
    (forall d n, (~ lt_decl d n -> ge_decl d n)) /\
    (forall p n, (~ lt_path p n -> ge_path p n)).
  Proof.
    apply type_mutind; crush.

    destruct v as [r|r]; auto.

    destruct (ge_dec r n); auto.
    apply not_ge in n0; crush.
  Qed.

  Lemma lt_implies_in_mutind :
    (forall t n, lt_type t n -> exists m, in_type m t /\ m < n) /\
    (forall d n, lt_decl d n -> exists m, in_decl m d /\ m < n) /\
    (forall p n, lt_path p n -> exists m, in_path m p /\ m < n).
  Proof.
    apply type_mutind; intros.

    inversion H0; subst.
    destruct (H (S n)) as [m Hin]; auto;
      destruct Hin as [Hin1 Hin2].
  Qed.
  
  
  Lemma ge_subst :
    (forall t p' x n, ge_type ([p' /t x] t) n -> ge_type t n) /\
    (forall d p' x n, ge_decl ([p' /d x] d) n -> ge_decl d n) /\
    (forall p p' x n, ge_path ([p' /p x] p) n -> ge_path p n).
  Proof.
    apply type_mutind; crush.

    apply ge_str.
    inversion H0; subst.
    apply H in H2; auto.

    apply ge_sel.
    inversion H0; subst.
    apply H in H4; auto.

    apply ge_upper.
    inversion H0; subst.
    apply H in H4; auto.

    apply ge_lower.
    inversion H0; subst.
    apply H in H4; auto.

    destruct v as [r|r]; auto.

    apply ge_cast;
    inversion H1; subst.
    apply H in H4; auto.
    apply H0 in H6; auto.    
  Qed.
  


    

  Lemma wf_ge_O_mutind :
    (forall G t, G vdash t wf_t -> ge_type t O) /\
    (forall G d, G vdash d wf_d -> ge_decl d O) /\
    (forall G p, G vdash p wf_p -> ge_path p O).
  Proof.
    apply wf_mutind; crush.

    apply ge_subst in H;
      apply ge_str.
    apply not_lt_ge_mutind.
    intro Hcontra.
    
  Qed.*)

  Reserved Notation "p1 'equiv' p2" (at level 80).

  (*Inductive path_equiv : path -> path -> Prop :=
  | peq_refl : forall n, v_ n equiv v_ n
  | peq_cast_1 : forall p1 p2 t, p1 equiv p2 ->
                            p1 cast t equiv p2
  | peq_cast_2 : forall p1 p2 t, p1 equiv p2 ->
                            p1 equiv (p2 cast t)
                               where "p1 'equiv' p2" := (path_equiv p1 p2).

  Hint Constructors path_equiv.*)

  (*Lemma equiv_sym :
    forall p1 p2, p1 equiv p2 -> p2 equiv p1.
  Proof.
    intros p1 p2 Heq; induction Heq; auto.
  Qed.

  Hint Resolve equiv_sym.

  Lemma equiv_refl :
    forall p, p equiv p.
  Proof.
    intro p; induction p as [n | p' t]; auto.
  Qed.

  Hint Resolve equiv_refl.*)
    
  (*Lemma equiv_cast :
    forall p1 p2, p1 equiv p2 ->
             forall p1' p2' t1 t2, p1 = (p1' cast t1) ->
                              p2 = (p2' cast t2) ->
                              p1' equiv p2'.
  Proof.
    intro p1; induction p1; intros; subst; crush.

    inversion H; crush.

    
    
  Qed.
   *)

  (*Lemma equiv_uncast :
    forall p1 p2, p1 equiv p2 ->
             forall p t, p2 = (p cast t) ->
                    p1 equiv p.
  Proof.
    intros p1 p2 Heq; induction Heq; crush.
    assert (Hequiv : p1 equiv p); [apply IHHeq with (t:=t0); auto|]; crush.
  Qed.

  Hint Resolve equiv_uncast.

  Lemma equiv_trans :
    forall p1 p2, p1 equiv p2 ->
             forall p3, p2 equiv p3 ->
                   p1 equiv p3.
  Proof.
    intros p1 p2 Heq; induction Heq; intros; crush.
    apply IHHeq.
    apply equiv_sym in H.
    apply equiv_uncast with (p:=p2)(t:=t) in H; auto.
  Qed.

  Hint Resolve equiv_trans.
  Hint Rewrite equiv_trans.*)
  
  Inductive struct_equiv_var : var -> var -> Prop :=
  | seq_abs : forall r, struct_equiv_var (a_ r) (a_ r)
  | seq_con : forall r1 r2, struct_equiv_var (c_ r1) (c_ r2).

  Inductive struct_equiv_type : ty -> ty -> Prop :=
  | seq_top : struct_equiv_type top top
  | seq_bot : struct_equiv_type bot bot
  | seq_arr : forall t1 t2 t1' t2', struct_equiv_type t1 t1' ->
                               struct_equiv_type t2 t2' ->
                               struct_equiv_type (t1 arr t2) (t1' arr t2')
  | seq_sel : forall p1 p2 l, struct_equiv_var p1 p2 ->
                         struct_equiv_type (sel p1 l) (sel p2 l)
  | seq_str : forall ds ds', struct_equiv_decl_tys ds ds' ->
                        struct_equiv_type (str ds') (str ds')

  with
  struct_equiv_decl_ty : decl_ty -> decl_ty -> Prop :=
  | seq_low : forall t1 t2 l, struct_equiv_type t1 t2 ->
                         struct_equiv_decl_ty (type l sup t1) (type l sup t2)
  | seq_upp : forall t1 t2 l, struct_equiv_type t1 t2 ->
                         struct_equiv_decl_ty (type l ext t1) (type l ext t2)
  | seq_val : forall t1 t2 l, struct_equiv_type t1 t2 ->
                         struct_equiv_decl_ty (val l ofv t1) (val l ofv t2)

  with
  struct_equiv_decl_tys : decl_tys -> decl_tys -> Prop :=
  | seq_lower : struct_equiv_decl_tys dt_nil dt_nil
  | seq_upper : forall d1 d2 ds1 ds2, struct_equiv_decl_ty d1 d2 ->
                                 struct_equiv_decl_tys ds1 ds2 ->
                                 struct_equiv_decl_tys (dt_con d1 ds1) (dt_con d2 ds2)

  (*with
  struct_equiv_path : path -> path -> Prop :=
  | seq_abs : forall r, struct_equiv_path (a_ r) (a_ r)
  | seq_con : forall r1 r2, struct_equiv_path (c_ r1) (c_ r2)
  | seq_cast : forall p1 t1 p2 t2, struct_equiv_path p1 p2 ->
                              struct_equiv_type t1 t2 ->
                              struct_equiv_path (p1 cast t1) (p2 cast t2)*).

  Reserved Notation "G1 'vdash' t1 '<;' t2 'dashv' G2" (at level 80).
  Reserved Notation "G1 'vdash' d1 '<;;' d2 'dashv' G2" (at level 80).
  Reserved Notation "G1 'vdash' d1 '<;;;' d2 'dashv' G2" (at level 80).

  Hint Constructors struct_equiv_type struct_equiv_decl_ty struct_equiv_decl_tys struct_equiv_var.
                                             

  Inductive sub : env -> ty -> ty -> env -> Prop :=
  | s_top : forall G t G', G vdash t <; top dashv G'
  | s_bot : forall G t G', G vdash bot <; t dashv G'
  | s_arr : forall G t1 t2 t1' t2' G', G' vdash t1' <; t1 dashv G ->
                                  t1::G vdash t2 <; t2' dashv t1'::G' ->
                                  G vdash (t1 arr t2) <; (t1' arr t2') dashv G'
  | s_refl : forall G x l G', G vdash (sel x l) <; (sel x l) dashv G'
  | s_lower : forall G x l s t G', G' vdash x ni (type l sup s) ->
                              G vdash t <; s dashv G' ->
                              G vdash t <; (sel x l) dashv G'
  | s_upper : forall G x l u t G', G vdash x ni (type l ext u) ->
                              G vdash u <; t dashv G'->
                              G vdash (sel x l) <; t dashv G'
  | s_struct : forall G ds1 ds2 G', 
                 (str ds1)::G vdash ds1 <;;; ds2 dashv (str ds2)::G'  ->
                 G vdash (str ds1) <; (str ds2) dashv G'
                              
  where "G1 'vdash' t1 '<;' t2 'dashv' G2" := (sub G1 t1 t2 G2)

  with
  sub_d : env -> decl_ty -> decl_ty -> env -> Prop :=
  | sd_low : forall G l t1 t2 G', G vdash t2 <; t1 dashv G' ->
                             G vdash (type l sup t1) <;; (type l sup t2) dashv G'
  | sd_upp : forall G l t1 t2 G', G vdash t1 <; t2 dashv G' ->
                             G vdash (type l ext t1) <;; (type l ext t2) dashv G'
  | sd_val : forall G l t1 t2 G', G vdash t1 <; t2 dashv G' ->
                             G vdash (val l ofv t1) <;; (val l ofv t2) dashv G'

                              where "G1 'vdash' d1 '<;;' d2 'dashv' G2" := (sub_d G1 d1 d2 G2)

  with
  sub_ds : env -> decl_tys -> decl_tys -> env -> Prop :=
  | sd_nil : forall G G', G vdash dt_nil <;;; dt_nil dashv G'
  | sd_con : forall G d1 ds1 d2 ds2 G', G vdash d1 <;; d2 dashv G' -> 
                                   G vdash ds1 <;;; ds2 dashv G' ->
                                   G vdash (dt_con d1 ds1) <;;; (dt_con d2 ds2) dashv G'

                                     where "G1 'vdash' d1 '<;;;' d2 'dashv' G2" := (sub_ds G1 d1 d2 G2).

  Scheme sub_ty_mutind := Induction for sub Sort Prop
    with sub_decl_ty_mutind := Induction for sub_d Sort Prop
    with sub_decl_tys_mutind := Induction for sub_ds Sort Prop.

  Combined Scheme sub_mutind from sub_ty_mutind, sub_decl_ty_mutind, sub_decl_tys_mutind.

  Hint Constructors sub sub_d sub_ds.

  
 (* Lemma get_empty :
    forall n, get n nil = None.
  Proof.
    intro n; induction n as [| n'];
      crush.
  Qed.

  Hint Resolve nth_empty.
  Hint Rewrite nth_empty.*)



  Lemma get_shift :
    forall G' G n, get n G = get (n + (length G')) (G'++G).
  Proof.
    intro G'; induction G' as [|t'' G'']; intros; simpl.

    rewrite <- plus_n_O; auto.

    rewrite <- plus_n_Sm; simpl; auto.
  Qed.

  Hint Rewrite get_shift.
  Hint Resolve get_shift.

  Lemma get_length :
    forall G n t, n = length G -> get n (G++t::nil) = Some t.
  Proof.
    intro G; induction G as [|t' G'];
      intros; crush.
  Qed.

  Hint Resolve get_length.
    
  (*Lemma get_length :
    forall G n t, n = length G -> get n (t::G) = Some t.
  Proof.
    intros; subst.
    unfold get; simpl.
    rewrite <- rev_length; auto.
  Qed.*)

  (*Lemma get_app_r :
    forall G1 G2 n, n < length G2 ->
               get n (G1++G2) = get n G2.
  Proof.
    intros.
    unfold get; rewrite rev_app_distr.
    apply nth_app_l.
    rewrite rev_length; auto.
  Qed.*)

  (*Lemma get_app_l :
    forall G1 G2 n, n >= length G2 ->
               get n (G1++G2) = get (n - length G2) G1.
  Proof.  
    intros; unfold get.
    rewrite rev_app_distr.
    rewrite <- rev_length.
    rewrite <- rev_length in H.
    apply nth_app_r; auto.
  Qed.*)
    
  (*Lemma get_cons :
    forall G t n, n < length G ->
             get n (t::G) = get n G.
  Proof.
    intros;
      assert (Happ : t::G = (t::nil)++G); auto;
        rewrite Happ; apply get_app_r; auto.    
  Qed.*)

  Lemma get_cons_dec :
    forall G n t1 t2, get n (G++(t1::nil)) = Some t2 ->
                 ((n < length G) /\ get n G = Some t2) \/ ((n = length G) /\ t1 = t2).
  Proof.
    intro G; induction G as [|t' G']; intros;
    destruct n as [|n']; simpl; simpl in H.

    inversion H; subst; auto.

    rewrite get_empty in H; inversion H.

    inversion H; subst; left; split; crush.
    
    apply IHG' in H.
    destruct H as [H|H]; destruct H as [Heq Hnth];  [left|right]; split; auto.
    crush.
  Qed.

  Hint Resolve get_cons_dec.

  Lemma get_in :
    forall G n t, get n G = Some t ->
             In t G.
  Proof.
    intro G; induction G as [|t' G']; intros.

    rewrite get_empty in H; inversion H.

    destruct n as [|n'].
    simpl in H; inversion H; subst; crush.
    simpl in H; apply IHG' in H; apply in_cons; auto.
  Qed.
    
(*  Lemma get_cons_dec :
    forall G n t1 t2, get n (t1::G) = Some t2 ->
                 (n < length G /\ get n G = Some t2) \/ (n = length G /\ t1 = t2).
  Proof.
    intros; unfold get; unfold get in H.
    rewrite <- rev_length.
    simpl in H; apply nth_cons_dec; auto.
  Qed.
 *)
  
  (*Lemma get_in :
    forall G n t, get n G = Some t ->
             In t G.
  Proof.
    intros; unfold get in H; apply nth_in in H.
    apply in_rev; auto.
  Qed.
   *)
  

  Lemma rshift_concrete :
    forall n m, ((Var n) rshift_v m) = Var (n - m).
  Proof.
    intros; destruct m as [|m']; simpl; crush.
  Qed.

  Lemma rshift_abstract :
    forall n m, ((Abs n) rshift_v m) = Abs n.
  Proof.
    intros; destruct m as [|m']; simpl; crush.
  Qed.

  Lemma lshift_concrete :
    forall n m, ((Var n) lshift_v m) = Var (n + m).
  Proof.
    intros; destruct m as [|m']; simpl; crush.
  Qed.

  Lemma lshift_abstract :
    forall n m, ((Abs n) lshift_v m) = Abs n.
  Proof.
    intros; destruct m as [|m']; simpl; crush.
  Qed.

  Hint Rewrite rshift_concrete rshift_abstract lshift_concrete lshift_abstract.
  Hint Resolve rshift_concrete rshift_abstract lshift_concrete lshift_abstract.

  Lemma ge_lt_n_var :
    forall x n, ge_var x n -> forall m, m < n -> ge_var x m.
  Proof.
    intros; destruct x as [r|r]; crush.
    inversion H;
    apply ge_concrete; crush.
  Qed.

  Hint Rewrite ge_lt_n_var.
  Hint Resolve ge_lt_n_var.

  Lemma ge_lt_n_mutind :
    (forall t n, ge_type t n -> forall m, m < n -> ge_type t m) /\
    (forall d n, ge_decl_ty d n -> forall m, m < n -> ge_decl_ty d m) /\
    (forall ds n, ge_decl_tys ds n -> forall m, m < n -> ge_decl_tys ds m).
  Proof.
    apply ge_mutind; crush.
    inversion g; crush.
  Qed.

  Lemma ge_lt_n_type :
    (forall t n, ge_type t n -> forall m, m < n -> ge_type t m).
  Proof.
    destruct ge_lt_n_mutind; crush.
  Qed.

  Lemma ge_lt_n_decl_ty :
    (forall d n, ge_decl_ty d n -> forall m, m < n -> ge_decl_ty d m).
  Proof.
    destruct ge_lt_n_mutind; crush.
  Qed.

  Lemma ge_lt_n_decl_tys :
    (forall ds n, ge_decl_tys ds n -> forall m, m < n -> ge_decl_tys ds m).
  Proof.
    destruct ge_lt_n_mutind; crush.
  Qed.

  Hint Resolve ge_lt_n_type ge_lt_n_decl_ty ge_lt_n_decl_tys.
  Hint Rewrite ge_lt_n_type ge_lt_n_decl_ty ge_lt_n_decl_tys.

  Lemma ge_notin_Sn_var :
    forall v n, ge_var v n ->
           n notin_v v ->
           ge_var v (S n).
  Proof.
    intros.
    inversion H; inversion H0; crush.
  Qed.

  Hint Rewrite ge_notin_Sn_var.
  Hint Resolve ge_notin_Sn_var.

  Lemma ge_notin_Sn_mutind :
    (forall t n, ge_type t n ->
            n notin_t t ->
            ge_type t (S n)) /\
    (forall d n, ge_decl_ty d n ->
            n notin_dt d ->
            ge_decl_ty d (S n)) /\
    (forall ds n, ge_decl_tys ds n ->
            n notin_dts ds ->
            ge_decl_tys ds (S n)).
  Proof.
    apply type_mutind; intros; auto.

    inversion H0; inversion H1; subst; crush.

    inversion H; inversion H0; subst; crush.

    inversion H1; inversion H2; subst; crush.

    inversion H0; inversion H1; subst; crush.

    inversion H0; inversion H1; crush.

    inversion H0; inversion H1; crush.

    inversion H1; inversion H2; crush.

  Qed.

  Lemma ge_notin_Sn_type :
    (forall t n, ge_type t n ->
            n notin_t t ->
            ge_type t (S n)).
  Proof.
    destruct ge_notin_Sn_mutind; crush.
  Qed.

  Lemma ge_notin_Sn_decl_ty :
    (forall d n, ge_decl_ty d n ->
            n notin_dt d ->
            ge_decl_ty d (S n)).
  Proof.
    destruct ge_notin_Sn_mutind; crush.
  Qed.

  Lemma ge_notin_Sn_decl_tys :
    (forall ds n, ge_decl_tys ds n ->
            n notin_dts ds ->
            ge_decl_tys ds (S n)).
  Proof.
    destruct ge_notin_Sn_mutind; crush.
  Qed.

  Hint Resolve ge_notin_Sn_type ge_notin_Sn_decl_ty ge_notin_Sn_decl_tys.
  Hint Rewrite ge_notin_Sn_type ge_notin_Sn_decl_ty ge_notin_Sn_decl_tys.

  Lemma ge_implies_notin_var :
    forall v n, ge_var v n ->
           forall m, m < n ->
                m notin_v v.
  Proof.
    intros.
    inversion H; crush.
  Qed.

  Hint Rewrite ge_implies_notin_var.
  Hint Resolve ge_implies_notin_var.

  Lemma ge_implies_notin_mutind :
    (forall t n, ge_type t n ->
            forall m, m < n ->
                 m notin_t t) /\
    (forall d n, ge_decl_ty d n ->
            forall m, m < n ->
                 m notin_dt d) /\
    (forall ds n, ge_decl_tys ds n ->
            forall m, m < n ->
                 m notin_dts ds).
  Proof.
    apply ge_mutind; crush.
    apply ni_sel.
    apply ge_implies_notin_var with (n := n); auto.
  Qed.

  Lemma ge_implies_notin_type :
    (forall t n, ge_type t n ->
            forall m, m < n ->
                 m notin_t t).
  Proof.
    destruct ge_implies_notin_mutind; crush.
  Qed.

  Lemma ge_implies_notin_decl_ty :
    (forall d n, ge_decl_ty d n ->
            forall m, m < n ->
                 m notin_dt d).
  Proof.
    destruct ge_implies_notin_mutind; crush.
  Qed.

  Lemma ge_implies_notin_decl_tys :
    (forall ds n, ge_decl_tys ds n ->
            forall m, m < n ->
                 m notin_dts ds).
  Proof.
    destruct ge_implies_notin_mutind; crush.
  Qed.

  Hint Resolve ge_implies_notin_type ge_implies_notin_decl_ty ge_implies_notin_decl_tys.
  Hint Rewrite ge_implies_notin_type ge_implies_notin_decl_ty ge_implies_notin_decl_tys.

  Lemma ge_shift_var :
    forall v n, ge_var v n -> forall m, ge_var (v lshift_v m) n.
  Proof.
    intros; inversion H; crush.
  Qed.
  
  Lemma ge_shift_mutind :
    (forall t n, ge_type t n -> forall m, ge_type (t lshift_t m) n) /\
    (forall d n, ge_decl_ty d n -> forall m, ge_decl_ty (d lshift_dt m) n) /\
    (forall ds n, ge_decl_tys ds n -> forall m, ge_decl_tys (ds lshift_dts m) n).
  Proof.
    apply ge_mutind; crush.
    apply ge_sel.
    apply ge_shift_var; auto.
  Qed.

  Lemma ge_shift_type :
    (forall t n, ge_type t n -> forall m, ge_type (t lshift_t m) n).
  Proof.
    destruct ge_shift_mutind; crush.
  Qed.

  Lemma ge_shift_decl_ty :
    (forall d n, ge_decl_ty d n -> forall m, ge_decl_ty (d lshift_dt m) n).
  Proof.
    destruct ge_shift_mutind; crush.
  Qed.

  Lemma ge_shift_decl_tys :
    (forall ds n, ge_decl_tys ds n -> forall m, ge_decl_tys (ds lshift_dts m) n).
  Proof.
    destruct ge_shift_mutind; crush.
  Qed.

  Hint Rewrite ge_shift_type ge_shift_decl_ty ge_shift_decl_tys.
  Hint Resolve ge_shift_type ge_shift_decl_ty ge_shift_decl_tys.
  
  Lemma shift_var_add :
    forall x n m, (x rshift_v n rshift_v m) = (x rshift_v (n + m)).
  Proof.
    intros; destruct x as [n'|n']; destruct n; destruct m; crush.    
  Qed.

  Hint Resolve shift_var_add.
    
  Lemma rshift_assoc_mutind :
    (forall t n m, (t rshift_t n rshift_t m) = (t rshift_t (n + m))) /\
    (forall d n m, (d rshift_dt n rshift_dt m) = (d rshift_dt (n + m))) /\
    (forall ds n m, (ds rshift_dts n rshift_dts m) = (ds rshift_dts (n + m))).
  Proof.
    apply type_mutind; intros; crush.
    rewrite shift_var_add; auto.
  Qed.

  Lemma rshift_assoc_type :
    (forall t n m, (t rshift_t n rshift_t m) = (t rshift_t (n + m))).
  Proof.
    destruct rshift_assoc_mutind; auto.
  Qed.
    
  Lemma rshift_assoc_decl_ty :
    (forall d n m, (d rshift_dt n rshift_dt m) = (d rshift_dt (n + m))).
  Proof.
    destruct rshift_assoc_mutind; crush.
  Qed.
    
  Lemma rshift_assoc_decl_tys :
    (forall p n m, (p rshift_dts n rshift_dts m) = (p rshift_dts (n + m))).
  Proof.
    destruct rshift_assoc_mutind; crush.
  Qed.
    
  Hint Resolve rshift_assoc_type rshift_assoc_decl_ty rshift_assoc_decl_tys.
  Hint Rewrite rshift_assoc_type rshift_assoc_decl_ty rshift_assoc_decl_tys.

  Lemma le_minus_plus :
    forall r n m, n <= r -> r - n + m = r + m - n.
  Proof.
    intro r; induction r as [|r']; crush.

    destruct n as [|n']; auto.

    rewrite IHr'; crush.
  Qed.

  Lemma lt_minus :
    forall m n p, m <= n ->
             n < p + m ->
             n - m < p.
  Proof.
    intro m; induction m as [|m']; intros; crush.
  Qed.

  Lemma rlshift_comm_var :
    forall v n m, ge_var v n -> (v rshift_v n lshift_v m) = (v lshift_v m rshift_v n).
  Proof.
    intros.
    inversion H; crush.
  Qed.
            
  Lemma rlshift_comm_mutind :
    (forall t n m, ge_type t n -> (t rshift_t n lshift_t m) = (t lshift_t m rshift_t n)) /\
    (forall d n m, ge_decl_ty d n -> (d rshift_dt n lshift_dt m) = (d lshift_dt m rshift_dt n)) /\
    (forall ds n m, ge_decl_tys ds n -> (ds rshift_dts n lshift_dts m) = (ds lshift_dts m rshift_dts n)).
  Proof.
    apply type_mutind; crush.

    rewrite H; auto;
    inversion H0; subst.
    apply ge_lt_n_decl_tys with (n:=S n); auto.

    inversion H; subst.
    rewrite rlshift_comm_var; auto.

    inversion H1; subst.
    rewrite H, H0; crush.
    apply ge_lt_n_type with (n:= S n); auto. 

    inversion H0; subst.
    rewrite H; crush.

    inversion H0; subst.
    rewrite H; crush.

    inversion H0; subst.
    rewrite H; crush.
    
    inversion H1; subst.
    rewrite H; auto; rewrite H0; auto.
  Qed.

            
  Lemma rlshift_comm_type :
    (forall t n m, ge_type t n -> (t rshift_t n lshift_t m) = (t lshift_t m rshift_t n)).
  Proof.
    destruct rlshift_comm_mutind; crush.
  Qed.
            
  Lemma rlshift_comm_decl_ty :
    (forall d n m, ge_decl_ty d n -> (d rshift_dt n lshift_dt m) = (d lshift_dt m rshift_dt n)).
  Proof.
    destruct rlshift_comm_mutind; crush.
  Qed.
            
  Lemma rlshift_comm_decl_tys :
    (forall ds n m, ge_decl_tys ds n -> (ds rshift_dts n lshift_dts m) = (ds lshift_dts m rshift_dts n)).
  Proof.
    destruct rlshift_comm_mutind; crush.
  Qed.

  Hint Rewrite rlshift_comm_type rlshift_comm_decl_ty rlshift_comm_decl_tys. 
  Hint Resolve rlshift_comm_type rlshift_comm_decl_ty rlshift_comm_decl_tys.

  Lemma lrshift_n_var :
    forall v n, (v lshift_v n rshift_v n) = v.
  Proof.
    intros; destruct v; crush.
   Qed.

  Lemma lrshift_n_mutind :
    (forall t n, (t lshift_t n rshift_t n) = t) /\
    (forall d n, (d lshift_dt n rshift_dt n) = d) /\
    (forall ds n, (ds lshift_dts n rshift_dts n) = ds).
  Proof.
    apply type_mutind; crush.
    destruct v as [r|r]; crush.
    rewrite <- Nat.add_sub_assoc; auto.
    assert (Htemp : n - n = 0); [crush|rewrite Htemp; rewrite <- plus_n_O; auto].
  Qed.

  Lemma lrshift_n_type :
    (forall t n, (t lshift_t n rshift_t n) = t).
  Proof.
    destruct lrshift_n_mutind; crush.
  Qed.

  Lemma lrshift_n_decl_ty :
    (forall d n, (d lshift_dt n rshift_dt n) = d).
  Proof.
    destruct lrshift_n_mutind; crush.
  Qed.

  Lemma lrshift_n_decl_tys :
    (forall ds n, (ds lshift_dts n rshift_dts n) = ds).
  Proof.
    destruct lrshift_n_mutind; crush.
  Qed.
  
  (*Lemma typing_weakening  :
    forall G p t, G vdash p hasType t ->
             forall G', G'++G vdash (p rshift_p (length G')) hasType (t rshift_t (length G')).
  Proof.
    intros G p t Htyp;
    induction Htyp; intros; crush.

    rewrite shift_add_type.
    apply t_var.

    rewrite <- get_shift; auto.
  Qed.
  
  Hint Resolve typing_weakening.*)
   

  Lemma shift_comm_mutind :
    (forall t n m, (t rshift_t n rshift_t m) = (t rshift_t m rshift_t n)) /\
    (forall d n m, (d rshift_dt n rshift_dt m) = (d rshift_dt m rshift_dt n)) /\
    (forall p n m, (p rshift_dts n rshift_dts m) = (p rshift_dts m rshift_dts n)).

  Proof.
    apply type_mutind; crush.

    rewrite shift_var_add, shift_var_add, plus_comm; auto.
  Qed.

  Lemma shift_comm_type :
    (forall t n m, (t rshift_t n rshift_t m) = (t rshift_t m rshift_t n)).
  Proof.
    destruct shift_comm_mutind; crush.
  Qed.

  Lemma shift_comm_decl_ty :
    (forall d n m, (d rshift_dt n rshift_dt m) = (d rshift_dt m rshift_dt n)).
  Proof.
    destruct shift_comm_mutind; crush.
  Qed.

  Lemma shift_comm_decl_tys :
    (forall ds n m, (ds rshift_dts n rshift_dts m) = (ds rshift_dts m rshift_dts n)).
  Proof.
    destruct shift_comm_mutind; crush.
  Qed.
      
  Hint Resolve shift_comm_decl_tys shift_comm_type shift_comm_decl_ty.

  Lemma rshift_subst_var :
    forall  y x n m, ([x /v n] y rshift_v m) = [x rshift_v m /v n] (y rshift_v m).
  Proof.
    intros; destruct y; crush.
    destruct (eq_nat_dec n n0); subst;
    [rewrite <- beq_nat_refl; auto|
     rewrite <- Nat.eqb_neq in n1;
       rewrite n1].
    crush.
  Qed.
    
  Lemma rshift_subst_mutind :
    (forall t x n m, ge_var x m -> ([x /t n] t rshift_t m) = [x rshift_v m /t n] (t rshift_t m)) /\
    (forall d x n m, ge_var x m -> ([x /dt n] d rshift_dt m) = [x rshift_v m /dt n] (d rshift_dt m)) /\
    (forall ds x n m, ge_var x m -> ([x /dts n] ds rshift_dts m) = [x rshift_v m /dts n] (ds rshift_dts m)).
  Proof.
    apply type_mutind; intros; try solve [crush].

    
    destruct x; [|crush]. 
    simpl; rewrite H.
    rewrite rshift_concrete.
    rewrite rshift_concrete.
    inversion H0; subst.
    rewrite minus_Sn_m; auto.
    inversion H0; crush.

    simpl; rewrite rshift_subst_var; auto.

    simpl.
    rewrite H, H0; auto.
    destruct x as [r|r]; simpl; crush.
    destruct m as [|l]; simpl.
    assert (Htmp : r - 0 = r); [rewrite minus_n_O; auto|rewrite Htmp; clear Htmp; auto].

    rewrite minus_Sn_m, Nat.sub_succ; auto.
    inversion H1; auto.

    inversion H1; auto.
    
  Qed.
    
  Lemma shift_subst_type :
    (forall t x n m, ge_var x m -> ([x /t n] t rshift_t m) = [x rshift_v m /t n] (t rshift_t m)).
  Proof.
    destruct rshift_subst_mutind; crush.
  Qed.
    
  Lemma shift_subst_decl_ty :
    (forall d x n m, ge_var x m -> ([x /dt n] d rshift_dt m) = [x rshift_v m /dt n] (d rshift_dt m)).
  Proof.
    destruct rshift_subst_mutind; crush.
  Qed.
    
  Lemma shift_subst_decl_tys :
    (forall ds x n m, ge_var x m -> ([x /dts n] ds rshift_dts m) = [x rshift_v m /dts n] (ds rshift_dts m)).
  Proof.
    destruct rshift_subst_mutind; crush.
  Qed.
  
(*  
  Lemma shift_typing :
    forall G p t, G vdash p hasType t ->
             forall G1 G2 t', G = G1++t'::G2 ->
                         (t' shift_t length G1)::(dec_env (length G2) G1)++G2 vdash 
   
*)
  
  (*Lemma has_contains_weakening_mutind :
    (forall G p d, G vdash p ni d ->
              (forall G', G'++G vdash (p rshift_p length G') ni (d rshift_d length G'))) /\
    (forall G t d, G vdash d cont t ->
              (forall G', G'++G vdash (d rshift_d length G') cont (t rshift_t length G'))).
  Proof.
    apply has_contains_mutind; crush.

    rewrite shift_subst_decl. apply h_path with (t:=t rshift_t length G'); auto.

    apply c_select with (l':=l')(t:=t rshift_t length G'); auto.
  Qed.


  Lemma has_weakening :
    (forall G p d, G vdash p ni d ->
              (forall G', G'++G vdash (p rshift_p length G') ni (d rshift_d length G'))).
  Proof.
    destruct has_contains_weakening_mutind; auto.
  Qed.

  Lemma contains_weakening :
    (forall G t d, G vdash d cont t ->
              (forall G', G'++G vdash (d rshift_d length G') cont (t rshift_t length G'))).
  Proof.
    destruct has_contains_weakening_mutind; auto.
  Qed.
    
  Hint Resolve has_weakening contains_weakening.*)

  Lemma ljump_concrete :
    forall m n i, ((Var m) [i] ljump_v n) = Var (m [i] ljump_n n).
  Proof.
    intros; unfold left_jump_v; destruct i; destruct n; crush.
  Qed.

  (*Lemma rjump_concrete :
    forall m n i, ((Var m) [i] rjump_dts n) = Var (m [i] rjump_n n).
  Proof.
    intros; unfold right_jump_v; destruct i; destruct n; crush.
  Qed.*)

  Lemma ljump_abstract :
    forall m n i, ((Abs m) [i] ljump_v n) = Abs m.
  Proof.
    intros; unfold left_jump_v; destruct i; destruct n; crush.
  Qed.

  (*Lemma rjump_abstract :
    forall m n i, ((Abs m) [i] rjump_v n) = Abs m.
  Proof.
    intros; unfold right_jump_v; destruct i; destruct n; crush.
  Qed.*)

  Hint Resolve ljump_concrete (*rjump_concrete*) ljump_abstract (*rjump_abstract*).
  Hint Rewrite ljump_concrete (*rjump_concrete*) ljump_abstract (*rjump_abstract*).  

  (*Lemma right_jump_left_jump_nat :
    forall r n i, ((r [i] ljump_n n) [i] rjump_n n) = r.
  Proof.
    intros; crush.
    unfold left_jump_n;
      unfold right_jump_n.

    destruct i as [i'|]; crush.
    destruct (lt_dec r i') as [Hlt1|Hlet1];
      [destruct (Nat.ltb_lt r i') as [Htemp Hltb1]; clear Htemp|
       destruct (Nat.ltb_nlt r i') as [Htemp Hltb1]; clear Htemp];
    rewrite Hltb1; auto.

    rewrite Hltb1; auto.
    destruct (Nat.ltb_nlt (r + n) i') as [Htemp Hltb2]; clear Htemp;
      rewrite Hltb2; crush.
  Qed.
  
  Hint Resolve right_jump_left_jump_nat.
  Hint Rewrite right_jump_left_jump_nat.*)

  (*Lemma right_jump_left_jump_var :
    forall x n i, ((x [i] ljump_v n) [i] rjump_v n) = x.
  Proof.
    intros;
    destruct x; crush.
  Qed.

  Hint Resolve right_jump_left_jump_var.
  Hint Rewrite right_jump_left_jump_var.*)

  Lemma l_jump_None :
    forall r n, (r [None] ljump_n n) = r.
  Proof.
    intros; crush.
  Qed.

  (*Lemma r_jump_None :
    forall r n, (r [None] rjump_n n) = r.
  Proof.
    intros; crush.
  Qed.*)

  Hint Rewrite l_jump_None (*r_jump_None*).
  Hint Resolve l_jump_None (*r_jump_None*).

  Lemma l_jump_None_var :
    forall x n, (x [None] ljump_v n) = x.
  Proof.
    intros; crush.
    destruct x as [m|m]; simpl; auto.
  Qed.

  Hint Rewrite l_jump_None_var.
  Hint Resolve l_jump_None_var.

  Lemma l_jump_None_mutind :
    (forall t n, (t [None] ljump_t n) = t) /\
    (forall d n, (d [None] ljump_dt n) = d) /\
    (forall ds n, (ds [None] ljump_dts n) = ds).
  Proof.
    apply type_mutind; intros; crush.
  Qed.

  Lemma l_jump_None_type :
    (forall t n, (t [None] ljump_t n) = t).
  Proof.
    destruct l_jump_None_mutind; crush.
  Qed.

  Lemma l_jump_None_decl_ty :
    (forall d n, (d [None] ljump_dt n) = d).
  Proof.
    destruct l_jump_None_mutind; crush.
  Qed.

  Lemma l_jump_None_decl_tys :
    (forall ds n, (ds [None] ljump_dts n) = ds).
  Proof.
    destruct l_jump_None_mutind; crush.
  Qed.

  Hint Rewrite l_jump_None_type l_jump_None_decl_ty l_jump_None_decl_tys.
  Hint Resolve l_jump_None_type l_jump_None_decl_ty l_jump_None_decl_tys.

  (*Lemma r_jump_None_var :
    forall x n, (x [None] rjump_v n) = x.
  Proof.
    intros; crush.
    destruct x as [m|m]; simpl; auto.
  Qed.

  Hint Rewrite r_jump_None_var.
  Hint Resolve r_jump_None_var.*)

  (*Lemma r_jump_None_mutind :
    (forall t n, (t [None] rjump_t n) = t) /\
    (forall d n, (d [None] rjump_d n) = d) /\
    (forall p n, (p [None] rjump_p n) = p).
  Proof.
    apply type_mutind; intros; crush.
  Qed.

  Lemma r_jump_None_type :
    (forall t n, (t [None] rjump_t n) = t).
  Proof.
    destruct r_jump_None_mutind; crush.
  Qed.

  Lemma r_jump_None_decl :
    (forall d n, (d [None] rjump_d n) = d).
  Proof.
    destruct r_jump_None_mutind; crush.
  Qed.

  Lemma r_jump_None_path :
    (forall p n, (p [None] rjump_p n) = p).
  Proof.
    destruct r_jump_None_mutind; crush.
  Qed.

  Hint Rewrite r_jump_None_type r_jump_None_decl r_jump_None_path.
  Hint Resolve r_jump_None_type r_jump_None_decl r_jump_None_path.*)

  Lemma l_jump_None_env :
    forall G n, (G [None] ljump_e n) = G.
  Proof.
    intro G; induction G as [|t' G']; intros; crush.
  Qed.

  (*Lemma r_jump_None_env :
    forall G n, (G [None] rjump_e n) = G.
  Proof.
    intro G; induction G as [|t' G']; intros; crush.
  Qed.*)

  Hint Rewrite l_jump_None_env (*r_jump_None_env*).
  Hint Resolve l_jump_None_env (*r_jump_None_env*).


  (*Lemma l_r_jump_inv_mutind :
    (forall t n i, ((t [i] ljump_t n) [i] rjump_t n) = t) /\
    (forall d n i, ((d [i] ljump_d n) [i] rjump_d n) = d) /\
    (forall p n i, ((p [i] ljump_p n) [i] rjump_p n) = p).
  Proof.
    apply type_mutind; intros; crush.
  Qed.

  Lemma l_r_jump_inv_type :
    (forall t n i, ((t [i] ljump_t n) [i] rjump_t n) = t).
  Proof.
    destruct l_r_jump_inv_mutind; crush.
  Qed.

  Lemma l_r_jump_inv_decl :
    (forall d n i, ((d [i] ljump_d n) [i] rjump_d n) = d).
  Proof.
    destruct l_r_jump_inv_mutind; crush.
  Qed.

  Lemma l_r_jump_inv_path :
    (forall p n i, ((p [i] ljump_p n) [i] rjump_p n) = p).
  Proof.
    destruct l_r_jump_inv_mutind; crush.
  Qed.

  Lemma l_r_jump_inv_env :
    forall G n i, ((G [i] ljump_e n) [i] rjump_e n) = G.
  Proof.
    intro G; induction G as [|t' G']; intros; auto.

    simpl;
      rewrite l_r_jump_inv_type;
      rewrite IHG'; auto.
  Qed.*)

  (*inc and dec of optional naturals*)

  Lemma inc_O :
    forall i, inc i 0 = i.
  Proof.
    destruct i; crush.
  Qed.

  Lemma dec_O :
    forall i, dec i 0 = i.
  Proof.
    destruct i; crush.    
  Qed.

  Hint Resolve inc_O dec_O.
  Hint Rewrite inc_O dec_O.

  Lemma dec_add :
    forall i n m, dec (dec i n) m = dec i (n + m).
  Proof.
    intros i n;
    destruct i as [i'|];
    [intros; simpl; destruct (lt_dec i' n) as [Hlt|Hlt]|crush].

    destruct (Nat.ltb_lt i' n) as [Htemp Hltb1]; clear Htemp;
    rewrite Hltb1; auto.
    destruct (Nat.ltb_lt i' (n + m)) as [Htemp Hltb2]; clear Htemp;
    rewrite Hltb2; crush.

    destruct (Nat.ltb_nlt i' n) as [Htemp Hltb1]; clear Htemp;
    rewrite Hltb1; auto; simpl.
    destruct (lt_dec (i' - n) m) as [Hlt2|Hlt2].
    destruct (Nat.ltb_lt i' (n + m)) as [Htemp Hltb2]; clear Htemp;
    rewrite Hltb2; [|crush].
    destruct (Nat.ltb_lt (i' - n) m) as [Htemp Hltb3]; clear Htemp;
    rewrite Hltb3; crush.
    
    destruct (Nat.ltb_nlt i' (n + m)) as [Htemp Hltb2]; clear Htemp;
    rewrite Hltb2; [|crush].
    destruct (Nat.ltb_nlt (i' - n) m) as [Htemp Hltb3]; clear Htemp;
    rewrite Hltb3; crush.    
  Qed.

  Lemma inc_add :
    forall i n m, inc (inc i n) m = inc i (n + m).
  Proof.
    intro i; destruct i as [i'|]; crush.
  Qed.

  Hint Resolve inc_add dec_add.
  Hint Rewrite inc_add dec_add.

  Lemma dec_inc_n :
    forall i n, dec (inc i n) n = i.
  Proof.
    intro i; destruct i as [i'|]; crush.

    destruct (Nat.ltb_nlt (i' + n) n) as [Htemp Hltb]; clear Htemp;
      rewrite Hltb; crush.
  Qed.

  Hint Rewrite dec_inc_n.
  Hint Resolve dec_inc_n.

    
  (*------------------------------------------------*)

  Lemma ljump_app :
    forall G1 G2 i m, ((G1 ++ G2) [i] ljump_e m) = (G1 [i] ljump_e m) ++ (G2 [dec i  (length G1)] ljump_e m).
  Proof.
    intro G1; induction G1 as [|t G1']; intros; [crush|].
    simpl.
    rewrite IHG1'; simpl.
    destruct i as [i'|]; crush.
    destruct (lt_dec i' 1) as [Hlt1|Hlt1];
      [destruct (Nat.ltb_lt i' 1) as [Htemp Hltb1]; clear Htemp;
       rewrite Hltb1|
       destruct (Nat.ltb_nlt i' 1) as [Htemp Hltb1]; clear Htemp;
       rewrite Hltb1]; crush.
    destruct (Nat.ltb_lt i' (S (length G1'))) as [Htemp Hltb2]; clear Htemp;
      rewrite Hltb2; crush.
    destruct (lt_dec i' (S (length G1'))) as [Hlt2|Hlt2].
    destruct (Nat.ltb_lt i' (S (length G1'))) as [Htemp Hltb2]; clear Htemp;
      rewrite Hltb2; auto.
    destruct (Nat.ltb_lt (i' - 1) (length G1')) as [Htemp Hltb3]; clear Htemp;
      rewrite Hltb3; crush.

    destruct (Nat.ltb_nlt i' (S (length G1'))) as [Htemp Hltb2]; clear Htemp;
      rewrite Hltb2; auto.
    destruct (Nat.ltb_nlt (i' - 1) (length G1')) as [Htemp Hltb3]; clear Htemp;
      rewrite Hltb3; crush.
    rewrite <- Nat.sub_add_distr; crush.
  Qed.

  Lemma ljump_inc_n :
    forall i r n, ((S r) [inc i 1] ljump_n n) = S (r [i] ljump_n n).
  Proof.
    intro i; destruct i as [i'|]; crush.
    destruct (lt_dec r i') as [Hlt1|Hlt1];
      [destruct (Nat.ltb_lt r i') as [Htemp Hltb1]; clear Htemp;
       destruct (Nat.ltb_lt (S r) (i' + 1)) as [Htemp Hltb2]; clear Htemp;
       rewrite Hltb1; auto;
       rewrite Hltb2; crush|
      destruct (Nat.ltb_nlt r i') as [Htemp Hltb1]; clear Htemp;
       destruct (Nat.ltb_nlt (S r) (i' + 1)) as [Htemp Hltb2]; clear Htemp;
       rewrite Hltb1; auto;
       rewrite Hltb2; crush].
Qed.    
  
  Lemma get_ljump :
    forall G1 G2 G r, get r (G1 ++ G2) = get (r [Some (length G1)] ljump_n (length G)) (G1 ++ G ++ G2).
  Proof.
    intro G1; induction G1 as [|t' G1']; intros; simpl; auto.

    destruct r as [|r']; crush.
    rewrite IHG1' with (G:=G).
    destruct (lt_dec r' (length G1')) as [Hlt1|Hlt1];
      [destruct (Nat.ltb_lt r' (length G1')) as [Htemp Hltb1]; clear Htemp;
       destruct (Nat.ltb_lt (S r') (S (length G1'))) as [Htemp Hltb2]; clear Htemp;
       rewrite Hltb1, Hltb2; crush|
       destruct (Nat.ltb_nlt r' (length G1')) as [Htemp Hltb1]; clear Htemp;
       destruct (Nat.ltb_nlt (S r') (S (length G1'))) as [Htemp Hltb2]; clear Htemp;
       rewrite Hltb1, Hltb2; crush].
  Qed.

  Lemma dec_S_S :
    forall i n, dec (Some (S i)) (S n) = dec (Some i) n.
  Proof.
    intros; crush.
  Qed.

  Hint Rewrite dec_S_S.
  Hint Resolve dec_S_S.

  Lemma get_ljump_alt :
    forall G1 G2 n t, get n (G1 ++ G2) = Some t ->
                 forall G i m, m = length G ->
                          i = Some (length G1) ->
                          get (n [i] ljump_n m) ((G1 [dec i  1] ljump_e m) ++ G ++ G2) = Some (t [dec i (S n)] ljump_t m).
  Proof.
    intro G1; induction G1 as [|t' G1']; intros; subst.
    simpl; rewrite <- get_shift; crush.

    destruct n as [|n'].
    simpl; rewrite <- minus_n_O; auto.
    simpl in H; inversion H; subst; auto.

    assert (Hleng : length (t'::G1') = S (length G1'));
      [auto|rewrite Hleng; clear Hleng].
    rewrite dec_S_S, dec_S_S.
    rewrite <- (IHG1' G2) with (G:=G)(n:=n'); simpl; auto.
    rewrite <- minus_n_O.
    destruct (lt_dec n' (length G1')) as [Hlt1|Hlt1];
      [destruct (Nat.ltb_lt n' (length G1')) as [Htemp Hltb1]; clear Htemp;
       rewrite Hltb1; auto;
       destruct (Nat.ltb_lt (S n') (S (length G1'))) as [Htemp Hltb2]; clear Htemp;
       rewrite Hltb2|
       destruct (Nat.ltb_nlt n' (length G1')) as [Htemp Hltb1]; clear Htemp;
       rewrite Hltb1; auto;
       destruct (Nat.ltb_nlt (S n') (S (length G1'))) as [Htemp Hltb2]; clear Htemp;
       rewrite Hltb2]; crush.
  Qed.

  Lemma ljump_lshift_var :
    forall v n i m, ((v lshift_v (S m)) [i] ljump_v n) = ((v [dec i (S m)] ljump_v n) lshift_v (S (m [i] ljump_n n))).
  Proof.
    intros; crush.
    destruct v as [r|r]; crush.

    destruct i as [i'|]; auto.

    simpl.
    destruct (lt_dec m i') as [Hlt1|Hlt1];
      [destruct (Nat.ltb_lt m i') as [Htemp Hltb1]; clear Htemp;
       rewrite Hltb1; [|auto]|
       destruct (Nat.ltb_nlt m i') as [Htemp Hltb1]; clear Htemp;
       rewrite Hltb1; [|auto]]; simpl.
    destruct (Nat.ltb_nlt i' (S m)) as [Htemp Hltb2]; clear Htemp;
      rewrite Hltb2; [|crush].
    simpl.
    destruct (lt_dec (S (m + r)) i') as [Hlt2|Hlt2].
    destruct (Nat.ltb_lt (S (m + r)) i') as [Htemp Hltb3]; clear Htemp;
    rewrite Hltb3; [|auto].
    destruct (Nat.ltb_lt r (i' - S m)) as [Htemp Hltb4]; clear Htemp;
    rewrite Hltb4; crush.

    destruct (Nat.ltb_nlt (S (m + r)) i') as [Htemp Hltb3]; clear Htemp;
    rewrite Hltb3; [|auto].
    destruct (Nat.ltb_nlt r (i' - S m)) as [Htemp Hltb4]; clear Htemp;
    rewrite Hltb4; crush.

    destruct (Nat.ltb_lt i' (S m)) as [Htemp Hltb2]; clear Htemp;
    rewrite Hltb2; [|crush].
    simpl.

    destruct (Nat.ltb_nlt (S (m + r)) i') as [Htemp Hltb3]; clear Htemp;
      rewrite Hltb3; crush.    
  Qed.

  Hint Rewrite ljump_lshift_var.
  Hint Resolve ljump_lshift_var.


  Lemma ljump_rshift_var :
    forall v n i m, ge_var v m -> ((v rshift_v (m)) [i] ljump_v n) = ((v [inc i (m)] ljump_v n) rshift_v m).
  Proof.
    intros; crush.
    destruct v as [r|r]; crush.

    destruct i as [i'|]; auto.

    simpl.

    destruct (lt_dec (r - m) i') as [Hlt|Hlt].
    destruct (Nat.ltb_lt (r - m) i') as [Htemp Hltb1]; clear Htemp;
      rewrite Hltb1; auto.
    destruct (Nat.ltb_lt r (i' + m)) as [Htemp Hltb2]; clear Htemp;
      rewrite Hltb2; crush.

    destruct (Nat.ltb_nlt (r - m) i') as [Htemp Hltb1]; clear Htemp;
      rewrite Hltb1; auto.
    destruct (Nat.ltb_nlt r (i' + m)) as [Htemp Hltb2]; clear Htemp;
    rewrite Hltb2.
    inversion H; subst; rewrite le_minus_plus; auto.

    inversion H; subst; intro Hcontra.
    apply lt_minus in Hcontra; auto.
  Qed.

  Lemma ljump_rshift_mutind :
    (forall t n i m, ge_type t m -> ((t rshift_t m) [i] ljump_t n) = ((t [inc i m] ljump_t n) rshift_t m)) /\
    (forall d n i m, ge_decl_ty d m -> ((d rshift_dt m) [i] ljump_dt n) = ((d [inc i m] ljump_dt n) rshift_dt m)) /\
    (forall ds n i m, ge_decl_tys ds m -> ((ds rshift_dts m) [i] ljump_dts n) = ((ds [inc i m] ljump_dts n) rshift_dts m)).
  Proof.
    apply type_mutind; intros; auto.

    simpl.
    rewrite H;
      [rewrite inc_add;
        rewrite inc_add;
        rewrite Nat.add_comm; auto|
       inversion H0; subst].
    apply ge_lt_n_decl_tys with (n:=S m); auto.

    simpl; rewrite ljump_rshift_var; auto.
    inversion H; auto.

    simpl; rewrite H, H0; 
    [rewrite inc_add, inc_add;
      rewrite plus_comm; auto| |];
    inversion H1; subst; crush.
    apply ge_lt_n_type with (n:=S m); auto.

    simpl; rewrite H;
    inversion H0; subst; crush.

    simpl; rewrite H;
    inversion H0; subst; crush.

    simpl; rewrite H;
    inversion H0; subst; crush.

    simpl; rewrite H, H0;
    inversion H1; subst; crush.
  Qed.

  Lemma ljump_rshift_type :
    (forall t n i m, ge_type t m -> ((t rshift_t m) [i] ljump_t n) = ((t [inc i m] ljump_t n) rshift_t m)).
  Proof.
    destruct ljump_rshift_mutind; crush.
  Qed.

  Lemma ljump_rshift_decl_ty :
    (forall d n i m, ge_decl_ty d m -> ((d rshift_dt m) [i] ljump_dt n) = ((d [inc i m] ljump_dt n) rshift_dt m)).
  Proof.
    destruct ljump_rshift_mutind; crush.
  Qed.

  Lemma ljump_rshift_decl_tys :
    (forall ds n i m, ge_decl_tys ds m -> ((ds rshift_dts m) [i] ljump_dts n) = ((ds [inc i m] ljump_dts n) rshift_dts m)).
  Proof.
    destruct ljump_rshift_mutind; crush.
  Qed.

  Lemma ge_n_implies_jump_shift_var :
    forall x i m, ge_var x i -> (x [Some i] ljump_v m) = (x lshift_v m).
  Proof.
    intros.
    inversion H; subst; [|crush].
    simpl.
    destruct (Nat.ltb_nlt r i) as [Htemp Hltb]; clear Htemp;
    rewrite Hltb; [|crush]; auto.
  Qed.
    
  
  Lemma ge_n_implies_jump_shift :
    (forall t i m, ge_type t i -> (t [Some i] ljump_t m) = (t lshift_t m)) /\
    (forall d i m, ge_decl_ty d i -> (d [Some i] ljump_dt m) = (d lshift_dt m)) /\
    (forall ds i m, ge_decl_tys ds i -> (ds [Some i] ljump_dts m) = (ds lshift_dts m)).
  Proof.
    apply type_mutind; crush.

    rewrite H; auto.
    inversion H0; subst.
    rewrite plus_comm; auto.

    rewrite ge_n_implies_jump_shift_var; auto.
    inversion H; subst; auto.

    rewrite H, H0; auto;
    inversion H1; subst; auto.
    rewrite plus_comm; auto.

    rewrite H; auto.
    inversion H0; subst; auto.
    
    inversion H0; subst.
    rewrite H; auto.

    inversion H0; subst;
    rewrite H; auto.

    inversion H1; subst;
    rewrite H, H0; auto.

  Qed.
  
  Lemma ge_n_implies_jump_shift_type :
    (forall t i m, ge_type t i -> (t [Some i] ljump_t m) = (t lshift_t m)).
  Proof.
    destruct ge_n_implies_jump_shift; crush.
  Qed.
  
  Lemma ge_n_implies_jump_shift_decl_ty :
    (forall d i m, ge_decl_ty d i -> (d [Some i] ljump_dt m) = (d lshift_dt m)).
  Proof.
    destruct ge_n_implies_jump_shift; crush.
  Qed.
  
  Lemma ge_n_implies_jump_shift_decl_tys :
    (forall ds i m, ge_decl_tys ds i -> (ds [Some i] ljump_dts m) = (ds lshift_dts m)).
  Proof.
    destruct ge_n_implies_jump_shift; crush.
  Qed.

  Lemma ge_type_in_env :
    forall G n, ge_env G n -> forall t, In t G -> ge_type t n.
  Proof.
    intro G; induction G as [|t' G']; intros.
    inversion H0.

    inversion H0; subst.
    inversion H; auto.

    apply IHG'; auto.
    inversion H; auto.
  Qed.
  
  Lemma lshift_add_mutind :
    (forall t n m, (t lshift_t n lshift_t m) = (t lshift_t (n + m))) /\
    (forall d n m, (d lshift_dt n lshift_dt m) = (d lshift_dt (n + m))) /\
    (forall ds n m, (ds lshift_dts n lshift_dts m) = (ds lshift_dts (n + m))). 
  Proof.
    apply type_mutind; crush.
    destruct v as [x|x]; crush.
    rewrite plus_assoc; auto.
  Qed.

  Lemma lshift_add_type :
    (forall t n m, (t lshift_t n lshift_t m) = (t lshift_t (n + m))). 
  Proof.
    destruct lshift_add_mutind; crush.
  Qed.

  Lemma lshift_add_decl_ty :
    (forall d n m, (d lshift_dt n lshift_dt m) = (d lshift_dt (n + m))). 
  Proof.
    destruct lshift_add_mutind; crush.
  Qed.

  Lemma lshift_add_decl_tys :
    (forall ds n m, (ds lshift_dts n lshift_dts m) = (ds lshift_dts (n + m))). 
  Proof.
    destruct lshift_add_mutind; crush.
  Qed.

  Hint Resolve lshift_add_decl_tys lshift_add_type lshift_add_decl_ty.
  Hint Rewrite lshift_add_decl_tys lshift_add_type lshift_add_decl_ty.

  Lemma lshift_subst_var :
    forall y v x n, (([v /v x] y) lshift_v n) = [v lshift_v n /v x] (y lshift_v n).
  Proof.
    intros.
    destruct y as [r|r]; crush.

    destruct (Nat.eq_dec x r); subst.
    rewrite <- beq_nat_refl; auto.
    destruct (Nat.eqb_neq x r) as [Htemp Hneqb]; clear Htemp;
    rewrite Hneqb; auto.
  Qed.
  
  Lemma lshift_subst_mutind :
    (forall t v x n, (([v /t x] t) lshift_t n) = [v lshift_v n /t x] (t lshift_t n)) /\
    (forall d v x n, (([v /dt x] d) lshift_dt n) = [v lshift_v n /dt x] (d lshift_dt n)) /\
    (forall ds v x n, (([v /dts x] ds) lshift_dts n) = [v lshift_v n /dts x] (ds lshift_dts n)).
  Proof.
    apply type_mutind; crush.
    assert (Htemp : S n = n + 1); crush.

    destruct v as [m|m]; crush.
    rewrite lshift_subst_var; auto.

    destruct v as [r|r]; crush.
  Qed.
  
  Lemma lshift_subst_type :
    (forall t v x n, (([v /t x] t) lshift_t n) = [v lshift_v n /t x] (t lshift_t n)).
  Proof.
    destruct lshift_subst_mutind; crush.
  Qed.
  
  Lemma lshift_subst_decl_ty :
    (forall d v x n, (([v /dt x] d) lshift_dt n) = [v lshift_v n /dt x] (d lshift_dt n)).
  Proof.
    destruct lshift_subst_mutind; crush.
  Qed.
  
  Lemma lshift_subst_decl_tys :
    (forall ds v x n, (([v /dts x] ds) lshift_dts n) = [v lshift_v n /dts x] (ds lshift_dts n)).
  Proof.
    destruct lshift_subst_mutind; crush.
  Qed.
  
  (*Lemma ljump_subst_mutind :
    (forall t p x i n, (([p /t x] t) [i] ljump_t n) = [p [i] ljump_p n /t x] (t [i] ljump_t n)) /\
    (forall d p x i n, (([p /d x] d) [i] ljump_d n) = [p [i] ljump_p n /d x] (d [i] ljump_d n)) /\
    (forall p p' x i n, (([p' /p x] p) [i] ljump_p n) = [p' [i] ljump_p n /p x] (p [i] ljump_p n)).
  Proof.
    apply type_mutind; crush.
    assert (Htemp : S n = n + 1); crush.

    destruct v as [m|m]; crush.
    destruct (Nat.eq_dec x m) as [|Heq]; subst.
    destruct (Nat.eqb_eq m m) as [Htemp Heqb]; rewrite Heqb; auto.
    destruct (Nat.eqb_neq x m) as [Htemp Hneqb]; rewrite Hneqb; crush.
  Qed.
  
  Lemma ljump_subst_type :
  Proof.
    destruct lshift_subst_mutind; crush.
  Qed.
  
  Lemma ljump_subst_decl :
  Proof.
    destruct lshift_subst_mutind; crush.
  Qed.
  
  Lemma ljump_subst_path :
  Proof.
    destruct lshift_subst_mutind; crush.
  Qed.*)

  (*Lemma struct_equiv_refl :
    (forall t, struct_equiv_type t t) /\
    (forall d, struct_equiv_decl d d) /\
    (forall p, struct_equiv_path p p).
  Proof.
    apply type_mutind; crush.

    
    
    destruct v; crush.
  Qed.*)

  (*
  Lemma subst_implies_equality :
    (forall t1 t2 p n, ([p /t n] t1) = ([p /t n] t2) ->
                  n notin_t t1 ->
                  n notin_t t2 ->
                  struct_equiv_type t1 t2 ->
                  t1 = t2) /\
    (forall d1 d2 p n, ([p /d n] d1) = ([p /d n] d2) -> 
                  n notin_d d1 ->
                  n notin_d d2 ->
                  struct_equiv_decl d1 d2 ->
                  d1 = d2) /\
    (forall p1 p2 p n, ([p /p n] p1) = ([p /p n] p2) -> 
                  n notin_p p1 ->
                  n notin_p p2 ->
                  struct_equiv_path p1 p2 ->
                  p1 = p2).
  Proof.
    apply type_mutind;
      try destruct t2;
      try destruct d2;
      try destruct p2; crush.

    inversion H2; inversion H3; inversion H4; subst; apply H in H1; crush.

    inversion H1; inversion H2; inversion H3; subst; apply H in H4; crush.

    inversion H1; inversion H2; inversion H3; subst; apply H in H0; crush.

    inversion H1; inversion H2; inversion H3; subst; apply H in H0; crush.

    destruct v as [x|x];
      destruct v0 as [y|y];
      [|inversion H2|
       inversion H2|]; auto.
    destruct (Nat.eq_dec n x) as [Heq1|Heq1];
      destruct (Nat.eq_dec n y) as [Heq2|Heq2]; subst; [crush| | |]; auto.
    inversion H2; crush.
    inversion H2; crush.
                    
    destruct (Nat.eqb_neq n x) as [Htemp Heqb1]; clear Htemp;
      rewrite Heqb1 in H; auto.
    destruct (Nat.eqb_neq n y) as [Htemp Heqb2]; clear Htemp;
      rewrite Heqb2 in H; auto.

    inversion H2.

    inversion H2.

    inversion H4.

    inversion H2; inversion H3; inversion H4; subst;
      apply H in H5; apply H0 in H1; crush.
  Qed.
*)  
  Lemma ljump_lshift_mutind :
    (forall t, ge_type t 0 ->
            (forall m i n, ((t lshift_t (S m)) [i] ljump_t n) = ((t [dec i (S m)] ljump_t n) lshift_t (S (m [i] ljump_n n))))) /\
    (forall d, ge_decl_ty d 0 ->
            (forall m i n, ((d lshift_dt (S m)) [i] ljump_dt n) = ((d [dec i (S m)] ljump_dt n) lshift_dt (S (m [i] ljump_n n))))) /\
    (forall ds, ge_decl_tys ds 0 ->
            (forall m i n, ((ds lshift_dts (S m)) [i] ljump_dts n) = ((ds [dec i (S m)] ljump_dts n) lshift_dts (S (m [i] ljump_n n))))).
  Proof.
    apply type_mutind; intros; auto.

    simpl; rewrite H.
    inversion H0; subst.

    destruct i as [i'|]; simpl; auto.
    destruct (lt_eq_lt_dec i' m) as [Hlt|Hlt];
      [destruct Hlt as [Hlt|Hlt]|]; subst.
    
    destruct (Nat.ltb_lt i' (S m)) as [Htemp Hltb1]; clear Htemp;
    rewrite Hltb1; auto; simpl.
    destruct (Nat.ltb_lt (i' + 1) (S m)) as [Htemp Hltb2]; clear Htemp;
    rewrite Hltb2; [|crush].
    destruct (Nat.ltb_nlt m i') as [Htemp Hltb3]; clear Htemp;
    rewrite Hltb3; [|crush].
    destruct (Nat.ltb_nlt m (i' + 1)) as [Htemp Hltb4]; clear Htemp;
    rewrite Hltb4; crush.

    destruct (Nat.ltb_nlt (m + 1) (S m)) as [Htemp Hltb1]; clear Htemp;
    rewrite Hltb1; [|crush].
    destruct (Nat.ltb_nlt m m) as [Htemp Hltb2]; clear Htemp;
    rewrite Hltb2; [|crush].
    destruct (Nat.ltb_lt m (S m)) as [Htemp Hltb3]; clear Htemp;
    rewrite Hltb3; auto; simpl.
    destruct (Nat.ltb_lt m (m + 1)) as [Htemp Hltb4]; clear Htemp;
    rewrite Hltb4; [|crush].
    assert (Htemp : m + 1 - S m = 0); [crush|rewrite Htemp; clear Htemp].

    rewrite l_jump_None_decl_tys.
    rewrite ge_n_implies_jump_shift_decl_tys.
    rewrite lshift_add_decl_tys;
    assert (n + S m = S (m + n)); crush.
    
    apply ge_lt_n_decl_tys with (n:=1); auto.

    destruct (Nat.ltb_nlt (i' + 1) (S m)) as [Htemp Hltb1]; clear Htemp;
    rewrite Hltb1; [|crush].
    destruct (Nat.ltb_nlt i' (S m)) as [Htemp Hltb2]; clear Htemp;
    rewrite Hltb2; [simpl|crush].
    destruct (Nat.ltb_lt m i') as [Htemp Hltb3]; clear Htemp;
    rewrite Hltb3; auto.
    destruct (Nat.ltb_lt m (i' + 1)) as [Htemp Hltb4]; clear Htemp;
    rewrite Hltb4; [|crush].
    assert (Htemp : i' + 1 - S m = i' - S m + 1); [crush|rewrite Htemp; auto].
    
    inversion H0; subst; apply ge_lt_n_decl_tys with (n:=1); auto.    

    assert (Htemp : ((sel v l lshift_t S m) [i] ljump_t n) = (sel ((v lshift_v S m) [i] ljump_v n) l));
      [auto| rewrite Htemp; rewrite ljump_lshift_var; auto].

    simpl; rewrite H, H0.

    destruct i as [i'|]; simpl; auto.
    destruct (lt_eq_lt_dec i' m) as [Hlt|Hlt];
      [destruct Hlt as [Hlt|Hlt]|]; subst.
    
    destruct (Nat.ltb_lt i' (S m)) as [Htemp Hltb1]; clear Htemp;
    rewrite Hltb1; auto; simpl.
    destruct (Nat.ltb_lt (i' + 1) (S m)) as [Htemp Hltb2]; clear Htemp;
    rewrite Hltb2; [|crush].
    destruct (Nat.ltb_nlt m i') as [Htemp Hltb3]; clear Htemp;
    rewrite Hltb3; [|crush].
    destruct (Nat.ltb_nlt m (i' + 1)) as [Htemp Hltb4]; clear Htemp;
    rewrite Hltb4; crush.

    destruct (Nat.ltb_nlt (m + 1) (S m)) as [Htemp Hltb1]; clear Htemp;
    rewrite Hltb1; [|crush].
    destruct (Nat.ltb_nlt m m) as [Htemp Hltb2]; clear Htemp;
    rewrite Hltb2; [|crush].
    destruct (Nat.ltb_lt m (S m)) as [Htemp Hltb3]; clear Htemp;
    rewrite Hltb3; auto; simpl.
    destruct (Nat.ltb_lt m (m + 1)) as [Htemp Hltb4]; clear Htemp;
    rewrite Hltb4; [|crush].
    assert (Htemp : m + 1 - S m = 0); [crush|rewrite Htemp; clear Htemp].
    
    rewrite ge_n_implies_jump_shift_type.
    rewrite lshift_add_type;
      assert (n + S m = S (m + n)); crush.
        
    apply ge_lt_n_type with (n:=1); auto.
    inversion H1; auto.

    destruct (Nat.ltb_nlt (i' + 1) (S m)) as [Htemp Hltb1]; clear Htemp;
    rewrite Hltb1; [|crush].
    destruct (Nat.ltb_nlt i' (S m)) as [Htemp Hltb2]; clear Htemp;
    rewrite Hltb2; [simpl|crush].
    destruct (Nat.ltb_lt m i') as [Htemp Hltb3]; clear Htemp;
    rewrite Hltb3; auto.
    destruct (Nat.ltb_lt m (i' + 1)) as [Htemp Hltb4]; clear Htemp;
    rewrite Hltb4; [|crush].
    assert (Htemp : i' + 1 - S m = i' - S m + 1); [crush|rewrite Htemp; auto].
    
    inversion H1; subst; apply ge_lt_n_type with (n:=1); auto. 
    inversion H1; auto.

    inversion H0; subst; simpl; rewrite H; crush.

    inversion H0; subst; simpl; rewrite H; crush.

    inversion H0; subst; simpl; rewrite H; crush.
    
    inversion H1; subst; simpl; rewrite H, H0; crush.
    
    (*if i < m then dec (inc i 1) (S m) = None = inc (dec i (S m)) 1 
               and m [inc i 1] n = m + n = m [i] n    
      if i = m then dec (inc i 1) (S m) = Some 0
               and  inc (dec i (S m)) = None
               and m [inc i 1] n = m , m [i] n = m + n
               but if d is well-formed then all concrete references in d are greater than O
               which means that the jump of n is equivalent to a shift of n.
               which gives us the equality we need
      if i > m then we get equality immediately
     *)
  Qed.
  
  Lemma ljump_lshift_type :
    (forall t, ge_type t 0 ->
            (forall m i n, ((t lshift_t (S m)) [i] ljump_t n) = ((t [dec i (S m)] ljump_t n) lshift_t (S (m [i] ljump_n n))))).
  Proof.
    destruct ljump_lshift_mutind; crush.
  Qed.
  
  Lemma ljump_lshift_decl_ty :
    (forall d, ge_decl_ty d 0 ->
            (forall m i n, ((d lshift_dt (S m)) [i] ljump_dt n) = ((d [dec i (S m)] ljump_dt n) lshift_dt (S (m [i] ljump_n n))))).
  Proof.
    destruct ljump_lshift_mutind; crush.
  Qed.
  
  Lemma ljump_lshift_decl_tys :
    (forall ds, ge_decl_tys ds 0 ->
            (forall m i n, ((ds lshift_dts (S m)) [i] ljump_dts n) = ((ds [dec i (S m)] ljump_dts n) lshift_dts (S (m [i] ljump_n n))))).
  Proof.
    destruct ljump_lshift_mutind; crush.
  Qed.

  Lemma lshift_ljump :
    forall x n i m, ((x [i] ljump_n n) + m) = ((x + m) [inc i m] ljump_n n).
  Proof.

    crush.
    destruct i as [i'|]; crush.

    destruct (lt_dec x i') as [Hlt|Hnlt].
    destruct (Nat.ltb_lt x i') as [Htemp Hltb1]; clear Htemp;
    rewrite Hltb1; auto.
    destruct (Nat.ltb_lt (x + m) (i' + m)) as [Htemp Hltb2]; clear Htemp;
    rewrite Hltb2; crush.

    destruct (Nat.ltb_nlt x i') as [Htemp Hnltb1]; clear Htemp;
    rewrite Hnltb1; auto.
    destruct (Nat.ltb_nlt (x + m) (i' + m)) as [Htemp Hnltb2]; clear Htemp;
    rewrite Hnltb2; crush.
  Qed.


  Lemma lshift_ljump_var :
    forall v n i m, ((v [i] ljump_v n) lshift_v m) = ((v lshift_v m) [inc i m] ljump_v n).
  Proof.
    intro v; destruct v as [x|x]; crush.
    rewrite lshift_ljump; auto.
  Qed.

  Hint Resolve lshift_ljump_var lshift_ljump.
  Hint Rewrite lshift_ljump_var lshift_ljump.

  Lemma lshift_ljump_mutind :
    (forall t n i m, ((t [i] ljump_t n) lshift_t m) = ((t lshift_t m) [inc i m] ljump_t n)) /\
    (forall d n i m, ((d [i] ljump_dt n) lshift_dt m) = ((d lshift_dt m) [inc i m] ljump_dt n)) /\
    (forall ds n i m, ((ds [i] ljump_dts n) lshift_dts m) = ((ds lshift_dts m) [inc i m] ljump_dts n)).
  Proof.
    apply type_mutind; crush.

    assert (m + 1 = S m); crush.
    assert (m + 1 = S m); crush.
  Qed.

  Lemma lshift_ljump_type :
    (forall t n i m, ((t [i] ljump_t n) lshift_t m) = ((t lshift_t m) [inc i m] ljump_t n)).
  Proof.
    destruct lshift_ljump_mutind; crush.
  Qed.

  Lemma lshift_ljump_decl_ty :
    (forall d n i m, ((d [i] ljump_dt n) lshift_dt m) = ((d lshift_dt m) [inc i m] ljump_dt n)).
  Proof.
    destruct lshift_ljump_mutind; crush.
  Qed.

  Lemma lshift_ljump_decl_tys :
    (forall ds n i m, ((ds [i] ljump_dts n) lshift_dts m) = ((ds lshift_dts m) [inc i m] ljump_dts n)).
  Proof.
    destruct lshift_ljump_mutind; crush.
  Qed.
    
  
  Lemma ljump_t_in_env :
    forall G n t, get n G = Some t ->
             forall i m, get n (G [i] ljump_e m) = Some (t [dec i n] ljump_t m).
  Proof.
    intro G; induction G as [|t' G']; crush.

    destruct n as [|n']; crush.
    rewrite IHG' with (t:=t); auto.

    rewrite dec_add; crush.
  Qed.

  Lemma jump_lt_n :
    forall r i n, r < i -> (r [Some i] ljump_n n) = r.
  Proof.
    intros; destruct (Nat.ltb_lt r i) as [Htemp Hltb];
    simpl; rewrite Hltb; crush.
  Qed.

  Lemma jump_nlt_n :
    forall r i n, ~ r < i -> (r [Some i] ljump_n n) = r + n.
  Proof.
    intros; destruct (Nat.ltb_nlt r i) as [Htemp Hltb];
    simpl; rewrite Hltb; crush.
  Qed.

  Hint Rewrite jump_lt_n jump_nlt_n.
  Hint Resolve jump_lt_n jump_nlt_n.

  Lemma jump_env_length :
    forall G i n, length (G [i] ljump_e n) = length G.
  Proof.
    intro G; induction G as [|t' G']; crush.
  Qed.

  Hint Rewrite jump_env_length.
  Hint Resolve jump_env_length.
  
  Lemma typing_weakening :
    forall G p t, G vdash p hasType t ->
             ge_env G 0 ->
             forall G1 G2, G = G1++G2 ->
                      forall G' i n, i = Some (length G1) ->
                                n = length G' ->
                                (G1 [dec i 1] ljump_e n) ++ G' ++ G2 vdash (p [i] ljump_v n) hasType (t [i] ljump_t n).
  Proof.
    intros G p t Htyp; induction Htyp; intros; subst.

    rewrite ljump_lshift_type; auto.
    apply t_var.

    destruct (lt_dec n (length G1)) as [Hlt|Hlt];
      [rewrite jump_lt_n|
       rewrite jump_nlt_n]; auto.

    rewrite get_app_l.
    rewrite ljump_t_in_env with (t:=t); auto.
    assert (Htemp : dec (dec (Some (length G1)) 1) n =
                    dec (Some (length G1)) (S n)); [simpl|rewrite Htemp; auto].
    destruct G1 as [|t' G1'];
      [inversion Hlt|simpl].
    rewrite <- minus_n_O.
    destruct (lt_dec (length G1') n) as [Hlt2|Hlt2];
      [destruct (Nat.ltb_lt (length G1') n) as [Htemp Hltb2];
        clear Htemp; rewrite Hltb2; [|auto];
        destruct (Nat.ltb_lt (S (length G1')) (S n)) as [Htemp Hltb3];
        clear Htemp; rewrite Hltb3; [|crush]|]; auto.
    
    
    rewrite <- get_app_l with (G2:=G2); auto.
    
    rewrite jump_env_length; auto.
    
    rewrite get_app_r; [|crush].
    rewrite jump_env_length.
    simpl.
    destruct (Nat.ltb_lt (length G1) (S n)) as [Htemp Hltb1]; clear Htemp;
    rewrite Hltb1; [|crush].
    rewrite l_jump_None_type.
    rewrite get_app_r in  H; [|crush].
    rewrite get_shift with (G':=G') in H.
    assert (Htemp : n - length G1 + length G' = n + length G' - length G1);
      [crush|rewrite Htemp in H; auto].

    apply ge_type_in_env with (G:=G1++G2); auto.
    apply get_in with (n:=n); auto.
  Qed.

  Hint Resolve typing_weakening.
  Hint Rewrite typing_weakening.

  Lemma ge_get :
    forall G m, ge_env G m -> forall n t, get n G = Some t ->
                               ge_type t m.
  Proof.
    intro G; induction G as [|t' G']; intros; [crush|].
    destruct n as [|n'].
    inversion H; subst.
    simpl in H0; inversion H0; subst; auto.
    apply IHG' with (n:=n'); auto.
    inversion H; auto.
  Qed.

  Lemma typing_weakening_actual :
    forall G v t, G vdash v hasType t ->
             ge_env G 0 ->
             forall G' n, n = length G' ->
                     G' ++ G vdash (v lshift_v n) hasType (t lshift_t n).
  Proof.
    intros.
    assert (Hge : ge_type t 0); [inversion H; subst; apply ge_get with (m:=0) in H2; auto|].
    apply typing_weakening with (p:=v)(t:=t)(G1:=nil)(G2:=G)(G':=G')(i:=Some 0)(n:=length G') in H0; auto.
    simpl in H0.
    rewrite ge_n_implies_jump_shift_type in H0;
    rewrite ge_n_implies_jump_shift_var in H0; subst; auto.
    destruct v; crush.
    destruct v; crush.
  Qed.
    
    

  (*Inductive equiv_top : env -> ty -> Prop :=
  | eq_top : forall G, equiv_top G top
  | eq_low : forall G x l t, G vdash x ni (type l sup t) ->
                        equiv_top G t -> 
                        equiv_top G (sel x l).

  Hint Constructors equiv_top.

  Lemma sub_top_equiv :
    forall G1 t1 t2 G2, G1 vdash t1 <; t2 dashv G2 -> t1 = top -> equiv_top G2 t2.
  Proof.
    intros.  induction H.
    auto.
    inversion H0.
    inversion H0.
    inversion H0.
    apply eq_low with (t:=s); auto.
    inversion H0.
    inversion H0.
  Qed.

  Lemma sub_equiv_top_all :
    forall G t, equiv_top G t -> forall G' t', G' vdash t' <; t dashv G.
  Proof.
    intros G t Hequiv; induction Hequiv; intros; [crush|subst].
    apply s_lower with (s:=t); auto.
  Qed.

  Inductive equiv_bot : env -> ty -> Prop :=
  | eq_bot : forall G, equiv_bot G bot
  | eq_upp : forall G x l t, G vdash x ni (type l ext t) ->
                        equiv_bot G t -> 
                        equiv_bot G (sel x l).

  Hint Constructors equiv_bot.

  Lemma sub_bot_equiv :
    forall G1 t1 t2 G2, G1 vdash t1 <; t2 dashv G2 -> t2 = bot -> equiv_bot G1 t1.
  Proof.
    intros.  induction H.
    inversion H0.
    auto.
    inversion H0.
    inversion H0.
    inversion H0.
    apply eq_upp with (t:=u); auto.
    inversion H0.
  Qed.

  Lemma sub_equiv_bot_all :
    forall G t, equiv_bot G t -> forall G' t', G vdash t <; t' dashv G'.
  Proof.
    intros G t Hequiv; induction Hequiv; intros; [crush|subst].
    apply s_upper with (u:=t); auto.
  Qed.*)

  Lemma ljump_subst_var :
    forall y v x i n, (([v /v x] y) [i] ljump_v n) = [v  [i] ljump_v n /v x] (y [i] ljump_v n).
  Proof.
    intro y; destruct y as [r|r]; crush.
    destruct (Nat.eq_dec x r);
      [subst; rewrite <- beq_nat_refl; auto|
       rewrite <- Nat.eqb_neq in n0; rewrite n0]; auto.
  Qed.

  Lemma ljump_subst_mutind :
    (forall t v x i n, ge_var v 0 -> (([v /t x] t) [i] ljump_t n) = [v [i] ljump_v n /t x] (t [i] ljump_t n)) /\
    (forall d v x i n, ge_var v 0 -> (([v /dt x] d) [i] ljump_dt n) = [v [i] ljump_v n /dt x] (d [i] ljump_dt n)) /\
    (forall ds v x i n, ge_var v 0 -> (([v /dts x] ds) [i] ljump_dts n) = [v [i] ljump_v n /dts x] (ds [i] ljump_dts n)).
  Proof.
    apply type_mutind; intros; try solve [crush].

    simpl; rewrite H.

    destruct v as [r|r]; simpl; auto.
    rewrite ljump_inc_n; auto.
    inversion H0; auto.

    simpl; rewrite ljump_subst_var; auto.

    simpl; rewrite H, H0; auto.
    destruct v as [r|r]; crush.
    
    rewrite ljump_inc_n; auto.

    inversion H1; auto.
  Qed.

  Lemma ljump_subst_type :
    (forall t v x i n, ge_var v 0 -> (([v /t x] t) [i] ljump_t n) = [v [i] ljump_v n /t x] (t [i] ljump_t n)).
  Proof.
    destruct ljump_subst_mutind; crush.
  Qed.

  Lemma ljump_subst_decl_ty :
    (forall d v x i n, ge_var v 0 -> (([v /dt x] d) [i] ljump_dt n) = [v [i] ljump_v n /dt x] (d [i] ljump_dt n)).
  Proof.
    destruct ljump_subst_mutind; crush.
  Qed.

  Lemma ljump_subst_decl_tys :
    (forall ds v x i n, ge_var v 0 -> (([v /dts x] ds) [i] ljump_dts n) = [v [i] ljump_v n /dts x] (ds [i] ljump_dts n)).
  Proof.
    destruct ljump_subst_mutind; crush.
  Qed.

  Hint Rewrite ljump_subst_type ljump_subst_decl_ty ljump_subst_decl_tys.
  Hint Resolve ljump_subst_type ljump_subst_decl_ty ljump_subst_decl_tys.

  Lemma ge_lshift_var :
    forall v n m, ge_var v n ->
             ge_var (v lshift_v m) (n + m).
  Proof.
    intros; destruct v as [r|r]; inversion H; subst; crush.
  Qed.
  
  Lemma ge_lshift_mutind :
    (forall t n m, ge_type t n ->
              ge_type (t lshift_t m) (n + m)) /\
    (forall d n m, ge_decl_ty d n ->
              ge_decl_ty (d lshift_dt m) (n + m)) /\
    (forall ds n m, ge_decl_tys ds n ->
              ge_decl_tys (ds lshift_dts m) (n + m)).
  Proof.
    apply type_mutind; crush.

    inversion H0; subst; simpl; apply ge_str.
    apply H with (m := m) in H2; auto.

    inversion H; subst; simpl; apply ge_sel.
    apply ge_lshift_var; auto.

    inversion H1; subst; apply ge_arr;
    [apply H; auto|
     rewrite <- plus_Sn_m; apply H0; auto].

    inversion H0; subst; simpl; apply ge_upp_d;
    apply H; auto.

    inversion H0; subst; simpl; apply ge_low_d;
    apply H; auto.

    inversion H0; subst; simpl; apply ge_val_d;
    apply H; auto.

    inversion H1; subst; simpl; apply ge_con_dt;
    [apply H; auto|
    apply H0; auto].
  Qed.

  Lemma ge_lshift_type :
    (forall t n m, ge_type t n ->
              ge_type (t lshift_t m) (n + m)).
  Proof.
    destruct ge_lshift_mutind; crush.
  Qed.

  Lemma ge_lshift_decl_ty : 
    (forall d n m, ge_decl_ty d n ->
              ge_decl_ty (d lshift_dt m) (n + m)).
  Proof.
    destruct ge_lshift_mutind; crush.
  Qed.

  Lemma ge_lshift_decl_tys : 
    (forall ds n m, ge_decl_tys ds n ->
              ge_decl_tys (ds lshift_dts m) (n + m)).
  Proof.
    destruct ge_lshift_mutind; crush.
  Qed.

  Lemma ge_rshift_var :
    forall v n m, ge_var v n ->
             n >= m ->
             ge_var (v rshift_v m) (n - m).
  Proof.
    intros;  destruct v as [r|r]; [|crush].

    inversion H; crush.
  Qed.

  Lemma ge_rshift_mutind :
    (forall t n m, ge_type t n ->
              n >= m ->
              ge_type (t rshift_t m) (n - m)) /\
    (forall d n m, ge_decl_ty d n ->
              n >= m ->
              ge_decl_ty (d rshift_dt m) (n - m)) /\
    (forall ds n m, ge_decl_tys ds n ->
              n >= m ->
              ge_decl_tys (ds rshift_dts m) (n - m)).
  Proof.
    apply type_mutind; intros; auto.

    inversion H0; subst; simpl;
    apply ge_str.
    apply H with (m:=m) in H3; auto.
    rewrite minus_Sn_m; auto.

    apply ge_sel; apply ge_rshift_var;
    inversion H; auto.

    simpl; apply ge_arr; inversion H1; subst.
    apply H; auto.
    rewrite minus_Sn_m; [apply H0; auto|auto].
    
    inversion H0; subst; crush.

    inversion H0; subst; crush.

    inversion H0; subst; crush.

    inversion H1; crush.    
    
  Qed.

  Lemma ge_rshift_type :
    (forall t n m, ge_type t n ->
              n >= m ->
              ge_type (t rshift_t m) (n - m)).
  Proof.
    destruct ge_rshift_mutind; crush.
  Qed.

  Lemma ge_rshift_decl_ty :
    (forall d n m, ge_decl_ty d n ->
              n >= m ->
              ge_decl_ty (d rshift_dt m) (n - m)).
  Proof.
    destruct ge_rshift_mutind; crush.
  Qed.

  Lemma ge_rshift_decl_tys :
    (forall ds n m, ge_decl_tys ds n ->
              n >= m ->
              ge_decl_tys (ds rshift_dts m) (n - m)).
  Proof.
    destruct ge_rshift_mutind; crush.
  Qed.

  Hint Resolve ge_lshift_type ge_lshift_decl_ty ge_lshift_decl_tys ge_rshift_type ge_rshift_decl_ty ge_rshift_decl_tys.
  Hint Rewrite ge_lshift_type ge_lshift_decl_ty ge_lshift_decl_tys ge_rshift_type ge_rshift_decl_ty ge_rshift_decl_tys.

  Lemma ge_ljump_var :
    forall v m i n, ge_var v m ->
               ge_var (v [i] ljump_v n) m.
  Proof.
    intros; destruct v as [r|r]; crush.

    apply ge_concrete.
    destruct i as [|i']; [|rewrite l_jump_None; inversion H; auto].

    simpl.
    destruct (lt_dec r n0) as [Hlt|Hnlt].
    destruct (Nat.ltb_lt r n0) as [Htemp Hltb]; clear Htemp;
    rewrite Hltb; inversion H; auto.
    destruct (Nat.ltb_nlt r n0) as [Htemp Hltb]; clear Htemp;
    rewrite Hltb; inversion H; crush.
  Qed.

  Lemma ge_ljump_mutind :
    (forall t m i n, ge_type t m ->
                ge_type (t [i] ljump_t n) m) /\
    (forall d m i n, ge_decl_ty d m ->
                ge_decl_ty (d [i] ljump_dt n) m) /\
    (forall ds m i n, ge_decl_tys ds m ->
                ge_decl_tys (ds [i] ljump_dts n) m).
  Proof.
    apply type_mutind; intros; auto.

    apply ge_str; inversion H0; crush.

    apply ge_sel; inversion H; simpl; apply ge_ljump_var; auto.


    simpl; apply ge_arr; inversion H1; subst;
    [apply H; auto|
     apply H0; auto].

    inversion H0; crush.

    inversion H0; crush.

    inversion H0; crush.

    inversion H1; crush.
    
  Qed.

  Lemma ge_ljump_type :
    (forall t m i n, ge_type t m ->
                ge_type (t [i] ljump_t n) m).
  Proof.
    destruct ge_ljump_mutind; crush.
  Qed.

  Lemma ge_ljump_decl_ty :
    (forall d m i n, ge_decl_ty d m ->
                ge_decl_ty (d [i] ljump_dt n) m).
  Proof.
    destruct ge_ljump_mutind; crush.
  Qed.

  Lemma ge_ljump_decl_tys :
    (forall ds m i n, ge_decl_tys ds m ->
                 ge_decl_tys (ds [i] ljump_dts n) m).
  Proof.
    destruct ge_ljump_mutind; crush.
  Qed.

  Hint Rewrite ge_ljump_type ge_ljump_decl_ty ge_ljump_decl_tys.
  Hint Resolve ge_ljump_type ge_ljump_decl_ty ge_ljump_decl_tys.
  
  Lemma ge_subst_var :
    (forall y v n, ge_var y n ->
              ge_var v n ->
              forall x, ge_var ([v /v x] y) n).
  Proof.
    intros; destruct y as [r|r]; simpl; auto.
    destruct (eq_nat_dec x r);
      [subst; rewrite <- beq_nat_refl; auto |
       apply Nat.eqb_neq in n0;
         rewrite n0; auto].
  Qed.
  
  Lemma ge_subst_mutind :
    (forall t v n, ge_type t n ->
              ge_var v n ->
              forall x, ge_type ([v /t x] t) n) /\
    (forall d v n, ge_decl_ty d n ->
              ge_var v n ->
              forall x, ge_decl_ty ([v /dt x] d) n) /\
    (forall ds v n, ge_decl_tys ds n ->
               ge_var v n ->
               forall x, ge_decl_tys ([v /dts x] ds) n).
  Proof.
    apply type_mutind; intros; auto.

    simpl; apply ge_str.
    inversion H0; subst.
    apply H; auto.
    destruct v as [r|r]; 
    inversion H1; subst; crush.

    inversion H; subst; simpl;
    apply ge_sel; crush.
    apply ge_subst_var; auto.

    apply ge_arr; inversion H1; subst;
      [apply H; auto;
       apply H0; auto|
       fold subst;
         apply H0; auto;
         assert (Htmp : S n = n + 1); [crush|];
       rewrite Htmp; apply ge_lshift_var; auto].
    
    inversion H0; crush.

    inversion H0; crush.

    inversion H0; crush.

    inversion H1; crush.
  Qed.
  
  Lemma ge_subst_type :
    (forall t v n, ge_type t n ->
              ge_var v n ->
              forall x, ge_type ([v /t x] t) n).
  Proof.
    destruct ge_subst_mutind; crush.
  Qed.
  
  Lemma ge_subst_decl_ty :
    (forall d v n, ge_decl_ty d n ->
              ge_var v n ->
              forall x, ge_decl_ty ([v /dt x] d) n).
  Proof.
    destruct ge_subst_mutind; crush.
  Qed.
  
  Lemma ge_subst_decl_tys :
    (forall ds v n, ge_decl_tys ds n ->
               ge_var v n ->
               forall x, ge_decl_tys ([v /dts x] ds) n).
  Proof.
    destruct ge_subst_mutind; crush.
  Qed.

  Lemma subst_ge_var :
    forall y v x n, ge_var ([v /v x] y) n ->
               ge_var y n.
  Proof.
    intros; destruct y as [r|r]; crush.
  Qed.

  Lemma subst_ge_mutind :
    (forall t v x n, ge_type ([v /t x] t) n ->
                ge_type t n) /\
    (forall d v x n, ge_decl_ty ([v /dt x] d) n ->
                ge_decl_ty d n) /\
    (forall ds v x n, ge_decl_tys ([v /dts x] ds) n ->
                 ge_decl_tys ds n).
  Proof.
    apply type_mutind; intros; auto.

    inversion H0; subst.
    apply H in H2.
    apply ge_str; auto.

    apply ge_sel; inversion H; 
    apply subst_ge_var with (v:=v0)(x:=x); auto.

    inversion H1; subst.
    apply H in H4; apply H0 in H6; crush.

    inversion H0; subst.
    apply H in H4; crush.

    inversion H0; subst.
    apply H in H4; auto.

    inversion H0; subst.
    apply H in H4; auto.

    inversion H1; subst.
    apply H in H4;
      apply H0 in H6; crush.
  Qed.

  Lemma subst_ge_type :
    (forall t v x n, ge_type ([v /t x] t) n ->
                ge_type t n).
  Proof.
    destruct subst_ge_mutind; crush.
  Qed.

  Lemma subst_ge_decl_ty :
    (forall d v x n, ge_decl_ty ([v /dt x] d) n ->
                ge_decl_ty d n).
  Proof.
    destruct subst_ge_mutind; crush.
  Qed.

  Lemma subst_ge_decl_tys :
    (forall ds v x n, ge_decl_tys ([v /dts x] ds) n ->
                 ge_decl_tys ds n).
  Proof.
    destruct subst_ge_mutind; crush.
  Qed.
  
  Lemma ge_typing :
    forall G v t, G vdash v hasType t ->
             forall n, ge_env G n ->
                  ge_var v n ->
                  ge_type t n.
  Proof.
    intros G p t Htyp; induction Htyp; intros.

    apply get_in in H.
    apply ge_type_in_env with (n:=n0) in H; auto.
    
  Qed.

  Hint Rewrite ge_typing.
  Hint Resolve ge_typing.

  Lemma ge_in_dty :
    forall d ds, in_dty d ds ->
            forall n, ge_decl_tys ds n ->
                 ge_decl_ty d n.
  Proof.
    intros d ds Hin; induction Hin; intros.
    inversion H; subst; auto.

    inversion H; auto.
  Qed.

  Hint Resolve ge_in_dty.
  
  Lemma ge_has_contains_mutind :
    (forall G v d, G vdash v ni d ->
              forall n, ge_env G n ->
                   ge_var v n ->
                   ge_decl_ty d n) /\
    (forall G t d, G vdash d cont t ->
              forall n, ge_env G n ->
                   ge_type t n ->
                   ge_decl_ty d n).
  Proof.
    apply has_contains_mutind; intros; auto.

    apply ge_subst_decl_ty; auto.
    apply H; auto.
    apply ge_typing with (G:=G)(v:=p); auto.

    inversion H0; subst.
    assert (Htemp : n = S n - 1); [crush|rewrite Htemp ; clear Htemp].
    apply ge_rshift_decl_ty; crush.
    apply ge_in_dty with (ds:=ds); auto.

    apply H0; auto.
    inversion H2; subst.
    apply H in H6; auto.
    inversion H6; auto.
  Qed.

  Lemma ge_has :
    (forall G v d, G vdash v ni d ->
              forall n, ge_env G n ->
                   ge_var v n ->
                   ge_decl_ty d n).
  Proof.
    destruct ge_has_contains_mutind; crush.
  Qed.

  Lemma ge_contains :
    (forall G t d, G vdash d cont t ->
              forall n, ge_env G n ->
                   ge_type t n ->
                   ge_decl_ty d n).
  Proof.
    destruct ge_has_contains_mutind; crush.
  Qed.

  Lemma in_dty_ljump :
    forall d ds, in_dty d ds ->
            forall i n, in_dty (d [i] ljump_dt n) (ds [i] ljump_dts n).
  Proof.
    intros d ds Hin; induction Hin; intros.
    apply in_head_dty.
    apply in_tail_dty; crush.
  Qed.

  Hint Resolve in_dty_ljump.
  
  Lemma has_contains_weakening :
    (forall G v d, G vdash v ni d ->
              ge_env G 0 ->
              ge_var v 0 ->
              (forall G1 G2, G = G1 ++ G2 ->
                        forall G' i n, i = Some (length G1) ->
                                  n = length G' ->
                                  (G1 [dec i 1] ljump_e n) ++ G' ++ G2 vdash (v [i] ljump_v n) ni (d [i] ljump_dt n))) /\
    (forall G t d, G vdash d cont t ->
              ge_env G 0 ->
              ge_type t 0 ->
              (forall G1 G2, G = G1 ++ G2 ->
                        forall G' i n, i = Some (length G1) ->
                                  n = length G' ->
                                  (G1 [dec i 1] ljump_e n) ++ G' ++ G2 vdash (d [i] ljump_dt n) cont (t [i] ljump_t n))).
  Proof.
    apply has_contains_mutind; intros; subst.

    (*has weakening*)
    rewrite ljump_subst_decl_ty; auto.
    apply h_path with (t:=(t [Some (length G1)] ljump_t (length G'))).

    apply typing_weakening with (G:=G1++G2); auto.
    apply H; auto.
    apply ge_typing with (G:=G1++G2)(v:=p); auto.

    (*struct contains weakening*)
    simpl.
    rewrite ljump_rshift_decl_ty.
    apply c_struct1; auto.
    inversion H0; apply ge_in_dty with (ds:=ds); auto.
    
    apply c_select with (t:=t [Some (length G1)] ljump_t (length G')).
    apply H; auto.
    inversion H2; auto.
    
    apply H0; auto.
    apply ge_has with (n:=0) in h; auto.
    inversion h; auto.
    inversion H2; auto.
  Qed.
  
  Lemma has_weakening :
    (forall G v d, G vdash v ni d ->
              ge_env G 0 ->
              ge_var v 0 ->
              (forall G1 G2, G = G1 ++ G2 ->
                        forall G' i n, i = Some (length G1) ->
                                  n = length G' ->
                                  (G1 [dec i 1] ljump_e n) ++ G' ++ G2 vdash (v [i] ljump_v n) ni (d [i] ljump_dt n))).
  Proof.
    destruct has_contains_weakening; crush.
  Qed.
  
  Lemma contains_weakening :
    (forall G t d, G vdash d cont t ->
              ge_env G 0 ->
              ge_type t 0 ->
              (forall G1 G2, G = G1 ++ G2 ->
                        forall G' i n, i = Some (length G1) ->
                                  n = length G' ->
                                  (G1 [dec i 1] ljump_e n) ++ G' ++ G2 vdash (d [i] ljump_dt n) cont (t [i] ljump_t n))).
  Proof.
    destruct has_contains_weakening; crush.
  Qed.

  Hint Resolve contains_weakening has_weakening.
  Hint Rewrite contains_weakening has_weakening.

  Lemma ge_wf_mutind :
    (forall G t, G vdash t wf_t ->
            ge_type t 0) /\
    (forall G d, G vdash d wf_d ->
            ge_decl_ty d 0) /\
    (forall G ds, G vdash ds wf_ds ->
            ge_decl_tys ds 0).
  Proof.
    apply wf_mutind; crush.

    apply ge_sel; inversion w; crush.

    apply ge_sel; inversion w; crush.

    apply ge_str.
    apply subst_ge_decl_tys in H.
    apply ge_notin_Sn_decl_tys; auto.
  Qed.

  Lemma ge_wf_type :
    (forall G t, G vdash t wf_t ->
            ge_type t 0).
  Proof.
    destruct ge_wf_mutind; crush.
  Qed.

  Lemma ge_wf_decl_ty :
    (forall G d, G vdash d wf_d ->
            ge_decl_ty d 0).
  Proof.
    destruct ge_wf_mutind; crush.
  Qed.

  Lemma ge_wf_decl_tys :
    (forall G ds, G vdash ds wf_ds ->
             ge_decl_tys ds 0).
  Proof.
    destruct ge_wf_mutind; crush.
  Qed.

  Hint Resolve ge_wf_type ge_wf_decl_ty ge_wf_decl_tys.
  Hint Rewrite ge_wf_type ge_wf_decl_ty ge_wf_decl_tys.

  Lemma wf_weakening_var :
    (forall G v, G vdash v wf_v ->
            ge_env G 0 ->
            (forall G1 G2, G = G1 ++ G2 ->
                      forall G' i n, i = Some (length G1) ->
                                n = length G' ->
                                (G1 [dec i 1] ljump_e n) ++ G' ++ G2 vdash (v [i] ljump_v n) wf_v)).
  Proof.
    intros; subst.
    destruct v as [r|r]; [|inversion H].
    apply wf_variable.
    admit.
  Admitted.

  Lemma in_ljump_implies_in_dty :
    forall d ds, in_dty d ds ->
            forall i n ds', ds = (ds' [i] ljump_dts n) ->
                       exists d', d = (d' [i] ljump_dt n) /\ in_dty d' ds'.
  Proof.
    intros d ds Hin; induction Hin; intros.

    destruct ds' as [|d' ds']; inversion H; subst.
    exists d'; split; auto.
    apply in_head_dty.

    destruct ds' as [|d'' ds'']; inversion H; subst.
    destruct IHHin with (ds':=ds'')(i0:=i)(n0:=n) as [d' Ha]; auto.
    destruct Ha as [Ha Hb].
    exists d'; split; auto.
    apply in_tail_dty; auto.
  Qed.

  Lemma ljump_preserves_id :
    forall d i n, id d = id (d [i] ljump_dt n).
  Proof.
    intros; destruct d; auto.
  Qed.
    
  Lemma wf_weakening_mutind :
    (forall G t, G vdash t wf_t ->
            ge_env G 0 ->
            (forall G1 G2, G = G1 ++ G2 ->
                      forall G' i n, i = Some (length G1) ->
                                n = length G' ->
                                (G1 [dec i 1] ljump_e n) ++ G' ++ G2 vdash (t [i] ljump_t n) wf_t)) /\
    (forall G d, G vdash d wf_d ->
            ge_env G 0 ->
            (forall G1 G2, G = G1 ++ G2 ->
                      forall G' i n, i = Some (length G1) ->
                                n = length G' ->
                                (G1 [dec i 1] ljump_e n) ++ G' ++ G2 vdash (d [i] ljump_dt n) wf_d)) /\
    (forall G ds, G vdash ds wf_ds ->
             ge_env G 0 ->
             (forall G1 G2, G = G1 ++ G2 ->
                       forall G' i n, i = Some (length G1) ->
                                 n = length G' ->
                                 (G1 [dec i 1] ljump_e n) ++ G' ++ G2 vdash (ds [i] ljump_dts n) wf_ds)).
  Proof.
    apply wf_mutind; intros; subst; auto.

    apply wf_arr; fold left_jump_t.
    apply H with (G3:=G1)(G4:=G2)(G':=G')(i:=Some (length G1))(n:=length G') in H1; auto.
    assert (Hwf : ge_env (t1 :: G1 ++ G2) 0);
      [apply ge_cons; auto;
       apply ge_wf_type with (G:=G1++G2); auto|].
    apply H0 with (G3:=t1::G1)
                   (G4:=G2)
                   (G':=G')
                   (i:=Some (S (length G1)))(n:=length G') in Hwf; auto.
    simpl in Hwf.
    rewrite <- minus_n_O in Hwf.
    simpl.
    assert (Htemp : length G1 + 1 = S (length G1));
      [crush|
       rewrite Htemp; clear Htemp; auto].
    apply ge_implies_notin_type with (n:=1); auto.
    apply ge_ljump_type; auto.
    assert (Htemp : ge_type (t1 arr t2) 0);
      [apply ge_wf_type with (G:=G1++G2); auto|
       inversion Htemp; subst; auto].

    
    
    apply wf_sel_lower with (t:=t [Some (length G1)] ljump_t length G').
    apply has_weakening with (G1:=G1)
                               (G2:=G2)
                               (G':=G')
                               (i:=Some (length G1))(n:=length G') in h; auto.
    destruct x; crush.
    apply wf_weakening_var with (G:=G1++G2); auto.

    apply wf_sel_upper with (t:=t [Some (length G1)] ljump_t length G').
    apply has_weakening with (G1:=G1)
                               (G2:=G2)
                               (G':=G')
                               (i:=Some (length G1))(n:=length G') in h; auto.
    destruct x; crush.
    apply wf_weakening_var with (G:=G1++G2); auto.

    apply wf_struct; fold left_jump_d_tys.
    assert (Hwf : ge_env (str ds :: G1 ++ G2) 0);
      [apply ge_cons; auto;
       apply ge_wf_type with (G:=G1++G2); auto|].
    apply H with (G3:=(str ds)::G1)
                   (G4:=G2)
                   (G':=G')
                   (i:=Some (S (length G1)))(n:=length G') in Hwf; auto.
    simpl in Hwf.
    rewrite <- minus_n_O in Hwf.
    simpl.
    assert (Htemp : length G1 + 1 = S (length G1));
      [crush|
       rewrite Htemp;
       rewrite Htemp in Hwf; clear Htemp].
    rewrite ljump_subst_decl_tys in Hwf; auto.
    apply ge_implies_notin_decl_tys with (n:=1); auto.
    apply ge_ljump_decl_tys; auto.
    assert (Htemp : ge_type (str ds) 0);
      [apply ge_wf_type with (G:=G1++G2); auto|
       inversion Htemp; subst; auto].

    simpl; apply wf_low.
    apply H with (G3:=G1)
                   (G4:=G2)
                   (G':=G')
                   (i:=Some (length G1))(n:=length G') in H0; auto.

    simpl; apply wf_upp.
    apply H with (G3:=G1)
                   (G4:=G2)
                   (G':=G')
                   (i:=Some (length G1))(n:=length G') in H0; auto.

    simpl; apply wf_val.
    apply H with (G3:=G1)
                   (G4:=G2)
                   (G':=G')
                   (i:=Some (length G1))(n:=length G') in H0; auto.

    simpl; apply wf_con.
    apply H with (G3:=G1)
                   (G4:=G2)
                   (G':=G')
                   (i:=Some (length G1))(n:=length G') in H1; auto.
    apply H0 with (G3:=G1)
                   (G4:=G2)
                   (G':=G')
                   (i:=Some (length G1))(n:=length G') in H1; auto.
    intros; intros Hcontra.
    apply in_ljump_implies_in_dty with (i:=Some (length G1))(n:=length G')(ds':=ds) in H2; auto.
    destruct H2 as [d'' Ha]; destruct Ha as [Ha Hb].
    apply n in Hb.
    rewrite Ha in Hcontra.
    rewrite <- ljump_preserves_id in Hcontra.
    rewrite <- ljump_preserves_id in Hcontra.
    contradiction Hb.
  Qed.
  
  Lemma wf_insertion_weakening_type :
    (forall G t, G vdash t wf_t ->
            ge_env G 0 ->
            (forall G1 G2, G = G1 ++ G2 ->
                      forall G' i n, i = Some (length G1) ->
                                n = length G' ->
                                (G1 [dec i 1] ljump_e n) ++ G' ++ G2 vdash (t [i] ljump_t n) wf_t)).
  Proof.
    destruct wf_weakening_mutind; crush.
  Qed.
  
  Lemma wf_insertion_weakening_decl_ty :
    (forall G d, G vdash d wf_d ->
            ge_env G 0 ->
            (forall G1 G2, G = G1 ++ G2 ->
                      forall G' i n, i = Some (length G1) ->
                                n = length G' ->
                                (G1 [dec i 1] ljump_e n) ++ G' ++ G2 vdash (d [i] ljump_dt n) wf_d)).
  Proof.
    destruct wf_weakening_mutind; crush.
  Qed.
  
  Lemma wf_insertion_weakening_decl_tys :
    (forall G ds, G vdash ds wf_ds ->
            ge_env G 0 ->
            (forall G1 G2, G = G1 ++ G2 ->
                      forall G' i n, i = Some (length G1) ->
                                n = length G' ->
                                (G1 [dec i 1] ljump_e n) ++ G' ++ G2 vdash (ds [i] ljump_dts n) wf_ds)).
  Proof.
    destruct wf_weakening_mutind; crush.
  Qed.

  Hint Resolve wf_insertion_weakening_type wf_insertion_weakening_decl_ty wf_insertion_weakening_decl_tys.
  Hint Rewrite wf_insertion_weakening_type wf_insertion_weakening_decl_ty wf_insertion_weakening_decl_tys.

  Lemma wf_weakening_type :
    forall G t, G vdash t wf_t ->
           ge_env G 0 ->
           forall G', G'++G vdash (t lshift_t length G') wf_t.
  Proof.
    intros.
    apply wf_insertion_weakening_type with (t:=t)
                                             (G1:=nil)
                                             (G2:=G)
                                             (G':=G')
                                             (i:= Some 0)
                                             (n:=length G') in H0; auto; simpl in H0.
    rewrite ge_n_implies_jump_shift_type in H0; auto.
    apply ge_wf_type with (G:=G); auto.    
  Qed.

  Lemma wf_weakening_decl_ty :
    forall G d, G vdash d wf_d ->
           ge_env G 0 ->
           forall G', G'++G vdash (d lshift_dt length G') wf_d.
  Proof.
    intros.
    apply wf_insertion_weakening_decl_ty with (d:=d)
                                             (G1:=nil)
                                             (G2:=G)
                                             (G':=G')
                                             (i:= Some 0)
                                             (n:=length G') in H0; auto; simpl in H0.
    rewrite ge_n_implies_jump_shift_decl_ty in H0; auto.
    apply ge_wf_decl_ty with (G:=G); auto.    
  Qed.

  Lemma wf_weakening_decl_tys :
    forall G ds, G vdash ds wf_ds ->
           ge_env G 0 ->
           forall G', G'++G vdash (ds lshift_dts length G') wf_ds.
  Proof.
    intros.
    apply wf_insertion_weakening_decl_tys with (ds:=ds)
                                                 (G1:=nil)
                                                 (G2:=G)
                                                 (G':=G')
                                                 (i:= Some 0)
                                                 (n:=length G') in H0; auto; simpl in H0.
    rewrite ge_n_implies_jump_shift_decl_tys in H0; auto.
    apply ge_wf_decl_tys with (G:=G); auto.    
  Qed.

  Hint Resolve wf_weakening_type wf_weakening_decl_ty wf_weakening_decl_tys.

  Lemma sub_weakening_mutind :
    (forall G1 t1 t2 G2 , G1 vdash t1 <; t2 dashv G2 ->
                     ge_env G1 0 ->
                     ge_env G2 0 ->
                     ge_type t1 0 ->
                     ge_type t2 0 ->
                     (forall G3 G4
                        G5 G6, G1 = G3 ++ G4 ->
                               G2 = G5 ++ G6 ->
                               forall G G'
                                 i n, i = Some (length G3) ->
                                      n = length G ->
                                      i = Some (length G5) ->
                                      n = length G' ->
                                      (G3 [dec i 1] ljump_e n) ++ G ++ G4 vdash (t1 [i] ljump_t n) <;
                                                         (t2 [i] ljump_t n) dashv (G5 [dec i 1] ljump_e n) ++ G' ++ G6)) /\
    
    (forall G1 d1 d2 G2 , G1 vdash d1 <;; d2 dashv G2 ->
                     ge_env G1 0 ->
                     ge_env G2 0 ->
                     ge_decl_ty d1 0 ->
                     ge_decl_ty d2 0 ->
                     (forall G3 G4
                        G5 G6, G1 = G3 ++ G4 ->
                               G2 = G5 ++ G6 ->
                               forall G G'
                                 i n, i = Some (length G3) ->
                                      n = length G ->
                                      i = Some (length G5) ->
                                      n = length G' ->
                                      (G3 [dec i 1] ljump_e n) ++ G ++ G4 vdash (d1 [i] ljump_dt n) <;;
                                                         (d2 [i] ljump_dt n) dashv (G5 [dec i 1] ljump_e n) ++ G' ++ G6)) /\
    (forall G1 ds1 ds2 G2 , G1 vdash ds1 <;;; ds2 dashv G2 ->
                       ge_env G1 0 ->
                       ge_env G2 0 ->
                       ge_decl_tys ds1 0 ->
                       ge_decl_tys ds2 0 ->
                     (forall G3 G4
                        G5 G6, G1 = G3 ++ G4 ->
                               G2 = G5 ++ G6 ->
                               forall G G'
                                 i n, i = Some (length G3) ->
                                      n = length G ->
                                      i = Some (length G5) ->
                                      n = length G' ->
                                      (G3 [dec i 1] ljump_e n) ++ G ++ G4 vdash (ds1 [i] ljump_dts n) <;;;
                                                         (ds2 [i] ljump_dts n) dashv (G5 [dec i 1] ljump_e n) ++ G' ++ G6)).
  Proof.
    apply sub_mutind; intros; auto.

    apply s_arr; fold left_jump_t.

    apply H with (G5:=G3)(G6:=G4); auto.
    inversion H4; auto.
    inversion H3; auto.

    assert (Hrewrite1 :((t1 [i]ljump_t n) :: (G3 [dec i 1]ljump_e n)) =
                       ((t1 :: G3) [dec (inc i 1) 1] ljump_e n));
      [crush|rewrite app_comm_cons, Hrewrite1].
    assert (Hrewrite2 :((t1' [i]ljump_t n) :: (G5 [dec i 1]ljump_e n)) =
                       ((t1' :: G5) [dec (inc i 1) 1] ljump_e n));
      [crush|rewrite app_comm_cons, Hrewrite2].
    apply H0; auto;
      try solve [apply ge_cons; inversion H3; auto];
      try solve [apply ge_cons; inversion H4; auto];
      try solve [inversion H3; subst; apply ge_lt_n_type with (n:=1); auto];
      try solve [inversion H4; subst; apply ge_lt_n_type with (n:=1); auto];
      try solve [subst; auto; crush].

    apply s_refl.

    apply s_lower with (s:=s [i] ljump_t n); auto.
    apply has_weakening with (G1:=G5)(G2:=G6)(G':=G'0)(i:=i)(n:=n) in h; subst; auto.
    destruct x; crush.
    apply H; auto.
    apply ge_has with (n:=0) in h; try solve [inversion h; destruct x; crush].
    
    apply s_upper with (u:=u [i] ljump_t n); auto.
    apply has_weakening with (G1:=G3)(G2:=G4)(G':=G0)(i:=i)(n:=n) in h; simpl in h; subst; auto.
    destruct x; crush.
    apply H; auto.    
    apply ge_has with (n:=0) in h; try solve [inversion h; destruct x; crush].

    apply s_struct; fold left_jump_d_tys.
    assert (Hsub : (((str ds1)::G3) [dec (inc i 1) 1]ljump_e n) ++ G0 ++ G4 vdash ds1 [inc i 1]ljump_dts n <;;; ds2 [inc i 1]ljump_dts n
                                     dashv (((str ds2)::G5) [dec (inc i 1) 1]ljump_e n) ++ G'0 ++ G6);
      [apply H;
       try solve [apply ge_cons; auto];
       try solve [inversion H2; subst; apply ge_lt_n_decl_tys with (n:=1); auto];
       try solve [inversion H3; subst; apply ge_lt_n_decl_tys with (n:=1); auto];
       try solve [subst; auto; simpl; rewrite <- plus_n_Sm; rewrite <- plus_n_O; try (inversion H8; subst; rewrite H5); auto];
       subst; auto|rewrite dec_inc_n in Hsub; auto].

    apply sd_low; fold left_jump_t.
    apply H; subst; auto.
    inversion H3; auto.
    inversion H2; auto.

    apply sd_upp; fold left_jump_t.
    apply H; subst; auto.
    inversion H2; auto.
    inversion H3; auto.

    apply sd_val; fold left_jump_t.
    apply H; subst; auto.
    inversion H2; auto.
    inversion H3; auto.

    inversion H3; inversion H4; subst.
    apply sd_con; fold left_jump_d_ty; fold left_jump_d_tys.
    apply H; auto.
    apply H0; auto.
  Qed.

  Lemma sub_weakening_type :
    (forall G1 t1 t2 G2 , G1 vdash t1 <; t2 dashv G2 ->
                     ge_env G1 0 ->
                     ge_env G2 0 ->
                     ge_type t1 0 ->
                     ge_type t2 0 ->
                     (forall G3 G4
                        G5 G6, G1 = G3 ++ G4 ->
                               G2 = G5 ++ G6 ->
                               forall G G'
                                 i n, i = Some (length G3) ->
                                      n = length G ->
                                      i = Some (length G5) ->
                                      n = length G' ->
                                      (G3 [dec i 1] ljump_e n) ++ G ++ G4 vdash (t1 [i] ljump_t n) <;
                                                         (t2 [i] ljump_t n) dashv (G5 [dec i 1] ljump_e n) ++ G' ++ G6)).
  Proof.
    destruct sub_weakening_mutind; auto.
  Qed.
  
  Lemma sub_weakening_decl_ty :
    (forall G1 d1 d2 G2 , G1 vdash d1 <;; d2 dashv G2 ->
                     ge_env G1 0 ->
                     ge_env G2 0 ->
                     ge_decl_ty d1 0 ->
                     ge_decl_ty d2 0 ->
                     (forall G3 G4
                        G5 G6, G1 = G3 ++ G4 ->
                               G2 = G5 ++ G6 ->
                               forall G G'
                                 i n, i = Some (length G3) ->
                                      n = length G ->
                                      i = Some (length G5) ->
                                      n = length G' ->
                                      (G3 [dec i 1] ljump_e n) ++ G ++ G4 vdash (d1 [i] ljump_dt n) <;;
                                                         (d2 [i] ljump_dt n) dashv (G5 [dec i 1] ljump_e n) ++ G' ++ G6)).
  Proof.
    destruct sub_weakening_mutind; crush.
  Qed.

  Lemma sub_weakening_decl_tys :
    (forall G1 ds1 ds2 G2 , G1 vdash ds1 <;;; ds2 dashv G2 ->
                       ge_env G1 0 ->
                       ge_env G2 0 ->
                       ge_decl_tys ds1 0 ->
                       ge_decl_tys ds2 0 ->
                     (forall G3 G4
                        G5 G6, G1 = G3 ++ G4 ->
                               G2 = G5 ++ G6 ->
                               forall G G'
                                 i n, i = Some (length G3) ->
                                      n = length G ->
                                      i = Some (length G5) ->
                                      n = length G' ->
                                      (G3 [dec i 1] ljump_e n) ++ G ++ G4 vdash (ds1 [i] ljump_dts n) <;;;
                                                         (ds2 [i] ljump_dts n) dashv (G5 [dec i 1] ljump_e n) ++ G' ++ G6)).
  Proof.
    destruct sub_weakening_mutind; crush.
  Qed.


  

  Definition beq_ty_label (l1 l2 : ty_label) : bool :=
    match l1, l2 with
      | Material n, Material m => n =? m
      | Shape n, Shape m => n =? m
      | _, _ => false
    end.

  Lemma beq_ty_label_refl :
    forall l, beq_ty_label l l = true.
  Proof.
    intro l; destruct l as [n|n]; intros; crush; 
    rewrite <- beq_nat_refl; auto.
  Qed.
  
  Definition beq_label (l1 l2 : label) : bool :=
    match l1, l2 with
      | l_type l1', l_type l2' => beq_ty_label l1' l2'
      | l_def n, l_def m => n =? m
      | _, _ => false
    end.

  Lemma beq_label_refl :
    forall l, beq_label l l = true.
  Proof.
    intro l; destruct l as [n|l']; crush;
    [rewrite <- beq_nat_refl; auto|].
    
    apply beq_ty_label_refl.
  Qed.

  Lemma beq_ty_label_eq :
    forall l1 l2, beq_ty_label l1 l2 = true -> l1 = l2.
  Proof.
    intros; destruct l1, l2; crush.
    symmetry in H; apply beq_nat_eq in H; auto.
    symmetry in H; apply beq_nat_eq in H; auto.
  Qed.

  Lemma beq_label_eq :
    forall l1 l2, beq_label l1 l2 = true -> l1 = l2.
  Proof.
    intros; destruct l1; destruct l2; crush.
    symmetry in H; apply beq_nat_eq in H; auto.
    apply beq_ty_label_eq in H; subst; auto.
  Qed.

  Inductive eq_upper : env -> ty -> ty -> Prop :=
  | equ_top : forall G, eq_upper G top top
  | equ_bot : forall G, eq_upper G bot bot
  | equ_upp : forall G x l u t, G vdash x ni (type l ext u) ->
                          eq_upper G u t ->
                          eq_upper G (sel x l) t
  | equ_low : forall G x l t, G vdash x ni (type l sup t) ->
                         eq_upper G (sel x l) top
  | equ_str : forall G ds, eq_upper G (str ds) (str ds).

  Inductive eq_lower : env -> ty -> ty -> Prop :=
  | eql_top : forall G, eq_lower G top top
  | eql_bot : forall G, eq_lower G bot bot
  | eql_low : forall G x l s t, G vdash x ni (type l sup s) ->
                           eq_lower G s t ->
                           eq_lower G (sel x l) t
  | eql_upp : forall G x l t, G vdash x ni (type l ext t) ->
                         eq_lower G (sel x l) bot
  | eql_str : forall G ds, eq_lower G (str ds) (str ds).

  Hint Constructors eq_lower eq_upper.

  Lemma eq_upper_dec :
    forall G t t', eq_upper G t t' -> (t' = top) \/ (t' = bot) \/ (exists ds, t' = str ds).
  Proof.
    intros G t t' Heq; induction Heq; intros; auto.
    right; right; exists ds; auto.
  Qed.

  Lemma  sup_top_eq_lower :
    forall G1 t1 t2 G2, G1 vdash t1 <; t2 dashv G2 -> t1 = top -> eq_lower G2 t2 top.
  Proof.
    intros G1 t1 t2 G2 Hsub; induction Hsub; intros; subst; auto.

    inversion H.

    inversion H.

    inversion H.

    apply eql_low with (s:=s); auto.

    inversion H0.

    inversion H0.
  Qed.

  Lemma  sub_bot_eq_upper :
    forall G1 t1 t2 G2, G1 vdash t1 <; t2 dashv G2 -> t2 = bot -> eq_upper G1 t1 bot.
  Proof.
    intros G1 t1 t2 G2 Hsub; induction Hsub; intros; subst; auto.

    inversion H.

    inversion H.

    inversion H.

    inversion H0.

    apply equ_upp with (u:=u); auto.

    inversion H0.
  Qed.

  Lemma eq_lower_top_sub :
    forall G t t', eq_lower G t t' -> t' = top -> forall G2 t2, G2 vdash t2 <; t dashv G.
  Proof.
    intros G t t' Heq; induction Heq; intros; subst; auto.
    
    inversion H.

    apply s_lower with (s:= s); auto.

    inversion H0.

    inversion H.
    
  Qed.

  Lemma eq_upper_bot_sup :
    forall G t t', eq_upper G t t' -> t' = bot -> forall G2 t2, G vdash t <; t2 dashv G2.
  Proof.
    intros G t t' Heq; induction Heq; intros; subst; auto.
    
    inversion H.

    apply s_upper with (u:= u); auto.

    inversion H0.

    inversion H.
    
  Qed.
    
  Lemma sub_eq_upper_sub_ty :
    forall G1 t1 t,  eq_upper G1 t t1 -> forall t2 G2, G1 vdash t1 <; t2 dashv G2 -> G1 vdash t <; t2 dashv G2.
  Proof.
    intros G1 t1 t Heq; induction Heq; intros; auto.

    apply s_upper with (u:=u); auto.
    
    assert (eq_lower G2 t2 top); [apply (sup_top_eq_lower H0); auto|].
    apply (eq_lower_top_sub H1); auto.
  Qed.
    
  Lemma sub_eq_lower_sub_ty :
    forall G1 t1 t,  eq_lower G1 t t1 -> forall t2 G2, G2 vdash t2 <; t1 dashv G1 -> G2 vdash t2 <; t dashv G1.
  Proof.
    intros G1 t1 t Heq; induction Heq; intros; auto.

    apply s_lower with (s:=s); auto.
    
    assert (eq_upper G2 t2 bot); [apply (sub_bot_eq_upper H0); auto|].
    apply (eq_upper_bot_sup H1); auto.
  Qed.

  Lemma typing_unique :
    forall G x t, G vdash x hasType t -> forall t', G vdash x hasType t' -> t' = t.
  Proof.
    intros.
    inversion H; inversion H0; subst; auto.
    inversion H7; subst.
    
    rewrite H1 in H5; inversion H5; auto.
    
  Qed.

  Lemma in_dty_subst :
    forall d ds, in_dty d ds -> forall x n, in_dty ([x /dt n] d) ([x /dts n] ds).
  Proof.
    intros d ds Hin; induction Hin; intros.
    apply in_head_dty.
    apply in_tail_dty; auto.
  Qed.

  Lemma wf_dty_unique :
    forall d1 ds, in_dty d1 ds -> forall G, G vdash ds wf_ds -> forall d2, in_dty d2 ds -> id d1 = id d2 -> d1 = d2.
  Proof.
    intros d1 ds Hin; induction Hin; intros.
    inversion H; subst; auto.
    inversion H0; subst; auto.

    apply H7 in H5; contradiction H5; auto.
    
    inversion H0; subst.
    inversion H; subst.
    apply H7 in Hin; contradiction Hin.
    apply IHHin with (G:=G); auto. 
    inversion H; auto.
  Qed.

  Lemma wf_ge_O_mutind :
    (forall G t, G vdash t wf_t -> ge_type t 0) /\
    (forall G d, G vdash d wf_d -> ge_decl_ty d 0) /\
    (forall G ds, G vdash ds wf_ds -> ge_decl_tys ds 0).
  Proof.
    apply wf_mutind; intros; auto.

    apply ge_sel; destruct x; crush.

    apply ge_sel; destruct x; crush.

    apply ge_str.
    apply ge_notin_Sn_decl_tys; auto.
    apply subst_ge_decl_tys with (v:=c_ 0)(x:=0); auto.
        
  Qed.

  Lemma wf_ge_O_type :
    (forall G t, G vdash t wf_t -> ge_type t 0).
  Proof.
    destruct wf_ge_O_mutind; crush.
  Qed.

  Lemma wf_ge_O_decl_ty :
    (forall G d, G vdash d wf_d -> ge_decl_ty d 0).
  Proof.
    destruct wf_ge_O_mutind; crush.
  Qed.

  Lemma wf_ge_O_decl_tys :
    (forall G ds, G vdash ds wf_ds -> ge_decl_tys ds 0).
  Proof.
    destruct wf_ge_O_mutind; crush.
  Qed.
    

  Lemma wf_env_implies_ge_O :
    forall G, G wf_e -> ge_env G 0.
  Proof.
    intro G; induction G as [|t' G']; intros; auto.

    apply ge_nil.

    apply ge_cons.
    inversion H; subst.
    apply wf_ge_O_type with (G:=G'); auto.
    apply IHG'; inversion H; auto.
    
  Qed.
    
  Lemma wf_get_lshift :
    forall n G t, get n G = Some t -> G wf_e -> G vdash (t lshift_t (S n)) wf_t.
  Proof.
    intro n; induction n as [|n']; intros.
    destruct G as [|t' G']; simpl in H; inversion H; subst.

    inversion H0; subst.
    apply wf_weakening_type with (G':=t::nil) in H3; auto.
    apply wf_env_implies_ge_O; auto.

    destruct G as [|t' G']; simpl in H; [inversion H|].
    apply IHn' in H.
    apply wf_weakening_type with (G':=t'::nil) in H; simpl in H.
    rewrite lshift_add_type in H.
    rewrite plus_Sn_m in H;
      rewrite plus_comm in H;
      simpl in H; auto.

    apply wf_env_implies_ge_O; inversion H0; auto.
    inversion H0; auto.
  Qed.

  Lemma wf_typing :
    forall G x t, G vdash x hasType t -> G wf_e -> G vdash t wf_t.
  Proof.
    intros; destruct x; inversion H; subst.

    apply wf_get_lshift; auto.
    
  Qed.

  Lemma wf_decl_tys_unique :
    forall G ds, G vdash ds wf_ds -> forall d1 d2, in_dty d1 ds -> in_dty d2 ds -> id d1 = id d2 -> d1 = d2.
  Proof.
    intros G ds Hwf; induction Hwf; intros.
    inversion H.

    inversion H1; inversion H2; subst; [auto| | |].

    apply H0 in H9; contradiction H9; auto.
    apply H0 in H6; contradiction H6; auto.
    apply IHHwf; auto.
  Qed.

  Lemma subst_in_dty :
    forall d ds, in_dty d ds -> forall x y, in_dty ([x /dt y] d) ([x /dts y] ds).
  Proof.
    intros d ds Hin; induction Hin; intros.

    simpl; apply in_head_dty.

    simpl; apply in_tail_dty; auto.
    
  Qed.
  
  Hint Resolve subst_in_dty.

  Lemma subst_equals_var :
    (forall v1 n, ge_var v1 n -> forall v2, ge_var v2 n ->
                                 forall x, x < n -> forall m, ([c_ x /v m] v1) = ([c_ x /v m] v2) ->
                                                   v1 =v2).
  Proof.
    intros; destruct v1 as [r1|r1]; destruct v2 as [r2|r2]; crush.
    
    destruct (eq_nat_dec m r2); subst;
      [rewrite <- beq_nat_refl in H2|].
    inversion H2; subst.
    inversion H; crush.
    apply (Nat.eqb_neq) in n0;
      rewrite n0 in H2;
      inversion H2.
    
    destruct (eq_nat_dec m r1); subst;
      [rewrite <- beq_nat_refl in H2|].
    inversion H2; subst.
    inversion H0; crush.
    apply (Nat.eqb_neq) in n0;
      rewrite n0 in H2;
      inversion H2.

    destruct (eq_nat_dec m r1);
      destruct (eq_nat_dec m r2); subst;
        [rewrite <- beq_nat_refl in H2|
         rewrite <- beq_nat_refl in H2|
         rewrite <- beq_nat_refl in H2|]; auto.
    apply Nat.eqb_neq in n0; rewrite n0 in H2;
      inversion H2.
    apply Nat.eqb_neq in n0; rewrite n0 in H2;
      inversion H2.
    apply Nat.eqb_neq in n0; apply Nat.eqb_neq in n1;
      rewrite n0 in H2; rewrite n1 in H2.
      inversion H2; auto.
    
  Qed.

  Lemma subst_equals_mutind :
    (forall t1 n, ge_type t1 n -> forall t2, ge_type t2 n ->
                                  forall x, x < n -> forall m, ([c_ x /t m] t1) = ([c_ x /t m] t2) ->
                                                    t1 =t2) /\
    (forall d1 n, ge_decl_ty d1 n -> forall d2, ge_decl_ty d2 n ->
                                     forall x, x < n -> forall m, ([c_ x /dt m] d1) = ([c_ x /dt m] d2) ->
                                                       d1 = d2) /\
    (forall ds1 n, ge_decl_tys ds1 n -> forall ds2, ge_decl_tys ds2 n ->
                                         forall x, x < n -> forall m, ([c_ x /dts m] ds1) = ([c_ x /dts m] ds2) ->
                                                           ds1 =ds2).
  Proof.
    apply ge_mutind; intros.
    
    destruct t2; simpl in H1; inversion H1; auto.
    
    destruct t2; simpl in H1; inversion H1; auto.

    destruct t0; simpl in H3; inversion H3; subst.
    rewrite H with (t2:=t0_1)(m:=m)(x:=x); crush.
    rewrite H0 with (t3:=t0_2)(m:=S m)(x:=S x); crush.
    inversion H1; auto.
    inversion H1; auto.

    destruct t2; simpl in H1; inversion H1; subst.
    apply subst_equals_var with (n:=n) in H3; subst; auto.
    inversion H; auto.

    destruct t2; simpl in H2; inversion H2; subst.
    apply H in H4; subst; crush.
    inversion H0; auto.

    destruct d2; simpl in H2; inversion H2; subst.
    apply H in H5; subst; crush.
    inversion H0; auto.

    destruct d2; simpl in H2; inversion H2; subst.
    apply H in H5; subst; crush.
    inversion H0; auto.

    destruct d2; simpl in H2; inversion H2; subst.
    apply H in H5; subst; crush.
    inversion H0; auto.

    destruct ds2; simpl in H1; inversion H1; subst; auto.

    destruct ds2; simpl in H3; inversion H3; subst.
    apply H in H5; subst; crush.
    apply H0 in H6; subst; crush.
    inversion H1; auto.
    inversion H1; auto.
    
  Qed.

  Lemma subst_equals_type :
    (forall t1 n, ge_type t1 n -> forall t2, ge_type t2 n ->
                                  forall x, x < n -> forall m, ([c_ x /t m] t1) = ([c_ x /t m] t2) ->
                                                    t1 =t2).
  Proof.
    destruct subst_equals_mutind; crush.
  Qed.

  Lemma subst_equals_decl_ty :
    (forall d1 n, ge_decl_ty d1 n -> forall d2, ge_decl_ty d2 n ->
                                     forall x, x < n -> forall m, ([c_ x /dt m] d1) = ([c_ x /dt m] d2) ->
                                                       d1 = d2).
  Proof.
    destruct subst_equals_mutind; crush.
  Qed.

  Lemma subst_equals_decl_tys :
    (forall ds1 n, ge_decl_tys ds1 n -> forall ds2, ge_decl_tys ds2 n ->
                                         forall x, x < n -> forall m, ([c_ x /dts m] ds1) = ([c_ x /dts m] ds2) ->
                                                           ds1 =ds2).
  Proof.
    destruct subst_equals_mutind; crush.
  Qed.

  Lemma subst_env_cons :
    forall G t x n, ([x /t S n] t)::([(x rshift_v 1) /e n] G) = [x /e S n] (t::G).
  Proof.
    intros; simpl; auto.
  Qed.

  Lemma notin_lshift_var :
    forall v n, n notin_v v -> forall m, (n + m) notin_v (v lshift_v m).
  Proof.
    intros v n Hni; induction Hni; crush.
  Qed.

  Lemma notin_lshift_mutind :
    (forall n t, n notin_t t -> forall m, n + m notin_t (t lshift_t m)) /\
    (forall n d, n notin_dt d -> forall m, n + m notin_dt (d lshift_dt m)) /\
    (forall n ds, n notin_dts ds -> forall m, n + m notin_dts (ds lshift_dts m)).
  Proof.
    apply notin_mutind; crush.

    apply ni_sel.
    apply notin_lshift_var; auto.
  Qed.

  Lemma notin_lshift_type :
    (forall n t, n notin_t t -> forall m, n + m notin_t (t lshift_t m)).
  Proof.
    destruct notin_lshift_mutind; crush.
  Qed.

  Lemma notin_lshift_decl_ty :
    (forall n d, n notin_dt d -> forall m, n + m notin_dt (d lshift_dt m)).
  Proof.
    destruct notin_lshift_mutind; crush.
  Qed.

  Lemma notin_lshift_decl_tys :
    (forall n ds, n notin_dts ds -> forall m, n + m notin_dts (ds lshift_dts m)).
  Proof.
    destruct notin_lshift_mutind; crush.
  Qed.

  Lemma notin_subst_var :
    forall v x n, n notin_v v -> n notin_v x -> forall m, n notin_v ([x /v m] v).
  Proof.
    intros; destruct v; crush.
    destruct (eq_nat_dec m n0);
      [subst; rewrite <- beq_nat_refl; auto|].
    destruct (Nat.eqb_neq m n0) as [Htmp Hneqb];
      rewrite Hneqb; auto.
  Qed.
  
  Lemma notin_subst_mutind :
    (forall t x n, n notin_t t -> n notin_v x -> forall m, n notin_t ([x /t m] t)) /\
    (forall d x n, n notin_dt d -> n notin_v x -> forall m, n notin_dt ([x /dt m] d)) /\
    (forall ds x n, n notin_dts ds -> n notin_v x -> forall m, n notin_dts ([x /dts m] ds)).
  Proof.
    apply type_mutind; intros; auto.

    apply ni_str.
    apply H.
    inversion H0; auto.
    apply notin_lshift_var with (m:=1) in H1.
    rewrite Nat.add_1_r in H1; crush.
    
    apply ni_sel.
    apply notin_subst_var; auto.
    inversion H; auto.

    apply ni_arr; fold subst;
    inversion H1; subst; auto.
    apply H0; auto.
    rewrite <- Nat.add_1_r;
      apply notin_lshift_var; auto.

    apply ni_upp_dt; fold subst; inversion H0; auto.

    apply ni_low_dt; inversion H0; auto.

    apply ni_val_dt; inversion H0; auto.

    apply ni_con_dt; inversion H1; auto.

  Qed.
  
  Lemma notin_subst_type :
    (forall t x n, n notin_t t -> n notin_v x -> forall m, n notin_t ([x /t m] t)).
  Proof.
    destruct notin_subst_mutind; crush.
  Qed.
  
  Lemma notin_subst_decl_ty :
    (forall d x n, n notin_dt d -> n notin_v x -> forall m, n notin_dt ([x /dt m] d)).
  Proof.
    destruct notin_subst_mutind; crush.
  Qed.
  
  Lemma notin_subst_decl_tys :
    (forall ds x n, n notin_dts ds -> n notin_v x -> forall m, n notin_dts ([x /dts m] ds)).
  Proof.
    destruct notin_subst_mutind; crush.
  Qed.

  Lemma subst_env_get_le :
    forall G n t x m, n <= m -> get n G = Some t -> get n ([x /e m] G) = Some ([x rshift_v n /t m - n] t).
  Proof.
    intro G; induction G as [|t' G']; intros; [crush|].

    destruct n as [|n'].
    simpl in H0; inversion H0; subst.
    destruct m as [|m'].
    destruct x as [r|r]; simpl; auto.
    rewrite <- minus_n_O; auto.
    simpl. destruct x as [r|r]; [rewrite <- minus_n_O|]; auto.

    destruct m as [|m']; simpl.
    inversion H.

    destruct x as [r|r].
    rewrite IHG' with (t:=t); simpl; [simpl|crush|crush].
    destruct r; [crush|simpl].
    rewrite <- minus_n_O; crush.
    rewrite IHG' with (t:=t); simpl; crush.
  Qed.

  Lemma subst_env_get_gt :
    forall G n t x m, n > m -> get n G = Some t -> get n ([x /e m] G) = Some t.
  Proof.
    intro G; induction G as [|t' G']; intros; [crush|].

    destruct n as [|n'].
    inversion H.

    destruct m as [|m']; crush.
  Qed.

  Lemma rlshift_var :
    forall v n m, ge_var v n -> n <= m -> (v rshift_v n lshift_v m) =  (v lshift_v (m - n)).
  Proof.
    intros v n m Hge; induction Hge; crush.
  Qed.

  Lemma minus_1_S :
    forall n m, n - S m = n - 1 - m.
  Proof.
    crush.
  Qed.
    

  Lemma subst_env_get_gt_exists :
    forall G n t x m, get n ([x /e m] G) = Some t ->
                 m >= length G ->
                 exists t', t = ([x rshift_v n /t m - n] t').
  Proof.
    intro G; induction G as [|t' G']; intros.

    destruct m, n; simpl in H; inversion H.

    destruct n as [|n'].
    rewrite <- minus_n_O.
    exists t'.
    destruct m; crush.
    destruct x; auto.
    rewrite <- minus_n_O; auto.

    destruct m. inversion H0.
    simpl in H0.
    simpl in H.
    rewrite Nat.sub_succ.
    destruct x; simpl in H;
    apply IHG' in H; [|crush| |crush]; destruct H as [t0].
    simpl; rewrite minus_1_S.
    exists t0; rewrite H; crush.

    exists t0; rewrite H; crush.
    
  Qed.

  Lemma subst_nil :
    forall n x, ([x /e n] nil) = nil.
  Proof.
    intros; destruct n; crush.
  Qed.

  Hint Resolve subst_nil.
  Hint Rewrite subst_nil.
  
  Lemma length_subst :
    forall G x n, length ([x /e n] G) = length G.
  Proof.
    intro G; induction G as [|t' G']; intros; [crush|].
    destruct n as [|n']; crush.
  Qed.

  Lemma lshift_rshift_var :
    forall v1 v2 n, v1 = (v2 lshift_v n) ->
               (v1 rshift_v n) = v2.
  Proof.
    intros; destruct v1, v2; crush.
  Qed.

  Lemma lshift_rshift_mutind :
    (forall t1 t2 n, t1 = (t2 lshift_t n) ->
                (t1 rshift_t n) = t2) /\
    (forall d1 d2 n, d1 = (d2 lshift_dt n) ->
                (d1 rshift_dt n) = d2) /\
    (forall ds1 ds2 n, ds1 = (ds2 lshift_dts n) ->
                  (ds1 rshift_dts n) = ds2).
  Proof.
    apply type_mutind; intros;
    try (rewrite H);
    try (rewrite H0);
    try (rewrite H1);
    try (rewrite lrshift_n_type);
    try (rewrite lrshift_n_decl_ty);
    try (rewrite lrshift_n_decl_tys); auto.
  Qed.

  Lemma lshift_rshift_type :
    (forall t1 t2 n, t1 = (t2 lshift_t n) ->
                (t1 rshift_t n) = t2).
  Proof.
    destruct lshift_rshift_mutind; crush.
  Qed.

  Lemma lshift_rshift_decl_ty :
    (forall d1 d2 n, d1 = (d2 lshift_dt n) ->
                (d1 rshift_dt n) = d2).
  Proof.
    destruct lshift_rshift_mutind; crush.
  Qed.

  Lemma lshift_rshift_decl_tys :
    (forall ds1 ds2 n, ds1 = (ds2 lshift_dts n) ->
                  (ds1 rshift_dts n) = ds2).
  Proof.
    destruct lshift_rshift_mutind; crush.
  Qed.
    
  Lemma lshift_eq_subst_var :
    forall v1 x n v2 m, ([x /v n] v1) = (v2 lshift_v m) ->
                   v2 = [x rshift_v m /v n] (v1 rshift_v m).
  Proof.
    intros;
    apply lshift_rshift_var in H.
    rewrite <- H; rewrite rshift_subst_var; auto.
  Qed.

  Lemma lshift_eq_subst_mutind :
    (forall t1 x n t2 m, ge_var x m -> ([x /t n] t1) = (t2 lshift_t m) ->
                    t2 = [x rshift_v m /t n] (t1 rshift_t m)) /\
    (forall d1 x n d2 m, ge_var x m -> ([x /dt n] d1) = (d2 lshift_dt m) ->
                    d2 = [x rshift_v m /dt n] (d1 rshift_dt m)) /\
    (forall ds1 x n ds2 m, ge_var x m -> ([x /dts n] ds1) = (ds2 lshift_dts m) ->
                      ds2 = [x rshift_v m /dts n] (ds1 rshift_dts m)).
  Proof.
    apply type_mutind; intros;
    try (apply lshift_rshift_type in H1;
         rewrite <- H1);
    try (apply lshift_rshift_type in H0;
         rewrite <- H0);
    try (apply lshift_rshift_type in H2;
         rewrite <- H2);
    try (apply lshift_rshift_decl_ty in H1;
         rewrite <- H1);
    try (apply lshift_rshift_decl_tys in H0;
         rewrite <- H0);
    try (apply lshift_rshift_decl_tys in H2;
         rewrite <- H2);
    try (rewrite shift_subst_type; auto);
    try (rewrite shift_subst_decl_ty; auto);
    try (rewrite shift_subst_decl_tys; auto).

  Qed.

  Lemma lshift_eq_subst_type :
    (forall t1 x n t2 m, ge_var x m -> ([x /t n] t1) = (t2 lshift_t m) ->
                    t2 = [x rshift_v m /t n] (t1 rshift_t m)).
  Proof.
    destruct lshift_eq_subst_mutind; crush.
  Qed.

  Lemma lshift_eq_subst_decl_ty :
    (forall d1 x n d2 m, ge_var x m -> ([x /dt n] d1) = (d2 lshift_dt m) ->
                    d2 = [x rshift_v m /dt n] (d1 rshift_dt m)).
  Proof.
    destruct lshift_eq_subst_mutind; crush.
  Qed.

  Lemma lshift_eq_subst_decl_tys :
    (forall ds1 x n ds2 m, ge_var x m -> ([x /dts n] ds1) = (ds2 lshift_dts m) ->
                      ds2 = [x rshift_v m /dts n] (ds1 rshift_dts m)).
  Proof.
    destruct lshift_eq_subst_mutind; crush.
  Qed.

  Lemma sub_add :
    forall n m, n >= m -> n - m + m = n.
  Proof.
    intro n; induction n as [|n']; [crush|intros].
    destruct m as [|m']; crush.
  Qed.
  
  Lemma subst_typing :
    forall G v t, G vdash v hasType t ->
             forall x n G1 G2,
               G = ([x /e n] G1) ++ G2 ->
               S n = length G1 ->
               forall t' n' x' tx,
                 Some n' = loc v ->
                 t = ([x /t n - n'] t') ->
(*                 v = ([x /v (S n)] v') ->*)
                 G vdash x hasType tx ->
                 G2 vdash x' hasType (tx rshift_t (S n)) ->
                 ge_type tx (S n) ->
                 ([x' lshift_v n /e n] G1) ++ G2 vdash v hasType ([x' lshift_v (S n) /t n - n'] t').
  Proof.
    intros G v t Htyp; inversion Htyp; intros; subst.

    simpl in H5; inversion H5; subst.

    destruct (get_some_app ([x /e n0] G1) G2 n) as [Hget | Hget];
      destruct Hget as [Hget1 Hget2].
    
    destruct (le_lt_dec (S n0) n).

    rewrite get_app_r in H.
    rewrite length_subst in H.
    rewrite <- length_subst with (x:=x' lshift_v n0)(n:=n0) in H.
    apply t_var in H.
    symmetry in H6; apply lshift_eq_subst_type in H6.
    apply typing_weakening_actual with (G':=[x' lshift_v n0 /e n0] G1)(n:=length ([x' lshift_v n0 /e n0] G1)) in H; auto.
    rewrite lshift_concrete in H.
    rewrite lshift_add_type in H.
    rewrite sub_add in H; [|rewrite length_subst; crush].
    rewrite <- Nat.sub_succ_l in H; [|rewrite length_subst; crush].
    rewrite sub_add in H; [|rewrite length_subst; crush].
    rewrite H6 in H.
    rewrite lshift_type in H.
    SearchAbout minus.
    simpl in H.
    
    apply lshift_eq_subst_var in 
    apply get_app_r in H.
    
    destruct (subst_env_get_gt_exists ) as [t0].
    
  Qed.
    
                                      
                          

  forall G v t, G vdash v hasType t ->
           forall n, v
  [x /e n]G1++G2 vdash [x /v n]v hasType [x / n] t ->
  n = length G1 ->
  [x /e n]G1++G2 vdash x hasType tx ->
  G2 vdash x rshift_v n hasType tx rshift_t n ->
  [x /e n]G1++G2 vdash [x /v n]v hasType [x /t n] t.
  

  Lemma subst_typing :
    forall G v t, G vdash v hasType t ->
             forall n, v = (c_ n) ->
                  forall x m G1 G2 t', G = ([x /e m] G1) ++ G2 ->
                                  t = [x lshift_v 1 /e m - n] t ->
                                  n <= m ->
                                  ge_var x n ->
                                  forall x' tx, G2 vdash x hasType tx ->
                                           G2 vdash x hasType tx ->
                                           
                    n <= m ->
                         ge_var x n ->
                         forall.

  Lemma subst_typing :
    (forall G v t, G vdash v hasType t ->
              forall n, v = (c_ n) ->
                   forall x m, n <= m ->
                          ge_var x n ->
                          [x /e m] G vdash v hasType ([x lshift_v 1 /t m - n] t)).
  Proof.
    intros; inversion H; subst.
    inversion H5; subst.

    apply subst_env_get with (x:=x)(m:=m) in H3; auto.
    apply t_var in H3.
    rewrite lshift_subst_type in H3.
    rewrite rlshift_var in H3; auto.
    rewrite <- minus_Sn_m in H3; auto.
    rewrite Nat.sub_diag in H3; auto.
    
  Qed.

  Lemma subst_typng_2 :
    forall G v t, G vdash v hasType ->
             forall n, v = (c_ n) ->
                  
              
              forall x n t', t = ([x /t S n] t') ->
                        forall G1 G2, G = ([x rshift_v 1 /e n] G1) ++ G2 ->
                                 n < (length G1) ->
                                 forall x' tx, G vdash x hasType tx ->
                                          G2 vdash (x' rshift_v (length G1)) hasType (tx rshift_t (length G1)) ->
                                          ([x' rshift_v 1 /e n] G1) ++ G2 vdash v hasType ([x' /t S n] t')).
  Proof.
    intros G v t Htyp; induction Htyp; intros.

    
    
    destruct v'; inversion H1; subst.

    

    apply t_var in H.

    (*
     if get n1 (([x rshift_v 1 /e n0] G1) ++ G2) = Some t, then there exists t' st 
     get n1 (([x' rshift_v 1 /e n0] G1) ++ G2) = Some t''

     if t is in ([x rshift_v 1 /e n0] G1, then t contains a substitution. 
     This is then used in (t lshift_t S n1) = ([x /t S n0] t') to 
     associate t'' with t'.

     if (t lshift_t S n1) = ([x /t S n0] t'), then there exists some x'', n0'' t'' such that 
     t = [x''/ S n0''] t''

     then [x''/ S n0''] t'' is in *)

    apply t_var in H.
    
    
  Qed.

  Lemma wf_has_contains_mutind :
    (forall G v d, G vdash v ni d ->
              G wf_e ->
              G vdash v wf_v ->
              G vdash d wf_d) /\
    (forall G t d, G vdash d cont t ->
              G wf_e ->
              G vdash t wf_t ->
              G vdash d wf_d).
  Proof.
    
    apply has_contains_mutind; intros.

    

  Lemma subst_typing :
    (forall G v t, G vdash v hasType t ->
              forall x n t' v', t = ([x /t n] t') ->
                           v = ([x /v n] v') ->
                           forall x' tx, G vdash x hasType tx ->
                                    G vdash x' hasType tx ->
                                    n notin_e G ->
                                    G vdash ([x /v n] v) hasType ).

  Lemma subst_has_contains_mutind :
    (forall G v d, G vdash v ni d ->
              forall x n d' v', d = ([x /dt S n] d') ->
                           v = ([x /v S n] v') ->
                           forall G1 G2, G = ([x lshift_v 1 /e n] G1) ++ G1 ->
                                    n < (length G1) ->
                                    forall x' tx, G vdash x hasType tx ->
                                             G2 vdash (x' rshift_v (length G1)) hasType (tx rshift_t (length G1)) ->
                                             ([x' rshift_v 1 /e n] G1) ++ G2 vdash ([x' /v S n] v') ni ([x' /dt S n]d')) /\
    (forall G t d, G vdash d cont t ->
              forall x n d' t', d = ([x /dt S n] d') ->
                           t = ([x /t S n] t') ->
                           forall G1 G2, G = ([x lshift_v 1 /e n] G1) ++ G1 ->
                                    n < (length G1) ->
                                    forall x' tx, G vdash x hasType tx ->
                                             G2 vdash (x' rshift_v (length G1)) hasType (tx rshift_t (length G1)) ->
                                             ([x' rshift_v 1 /e n] G1) ++ G2 vdash ([x' /dt S n]d') cont ([x' /t S n] t')).
  Proof.

    apply has_contains_mutind; intros.

    apply subst_typing with (v:=p)(t:=t)(n:=n)(t':=t')in t0.
    apply h_path.
    

  Qed.
    
  
  Lemma subst_wf_mutind :
    (forall G t, G vdash t wf_t -> forall x n t', t = ([x /t S n] t') ->
                                   forall G1 G2, G = ([x rshift_v 1 /e n] G1) ++ G2 ->
                                            n < (length G1) ->
                                            forall x' tx, G vdash x hasType tx ->
                                                     G2 vdash (x' rshift_v (length G1)) hasType (tx rshift_t (length G1)) ->
                                                     ([x' rshift_v 1 /e n] G1) ++ G2 vdash ([x' /t S n]t') wf_t) /\
    
    (forall G d, G vdash d wf_d -> forall x n d', d = ([x /dt S n] d') ->
                                   forall G1 G2, G = ([x rshift_v 1 /e n] G1) ++ G2 ->
                                            n < length G1 ->
                                            forall x' tx, G vdash x hasType tx ->
                                                     G2 vdash (x' rshift_v (length G1)) hasType (tx rshift_t (length G1)) ->
                                                     ([x' rshift_v 1 /e n] G1) ++ G2 vdash ([x /dt S n]d') wf_d) /\
    
    (forall G ds, G vdash ds wf_ds -> forall x n ds', ds = ([x /dts S n] ds') ->
                                       forall G1 G2, G = ([x rshift_v 1 /e n] G1) ++ G2 ->
                                                n < length G1 ->
                                                forall x' tx, G vdash x hasType tx ->
                                                         G2 vdash (x' rshift_v (length G1)) hasType (tx rshift_t (length G1)) ->
                                                         ([x' rshift_v 1 /e n] G1) ++ G2 vdash ([x /dts S n]ds') wf_ds).
  Proof.
    apply wf_mutind; intros.

    destruct t'; simpl in H; inversion H; auto.

    destruct t'; simpl in H; inversion H; auto.

    destruct t'; simpl in H1; inversion H1; subst; auto.
    apply wf_arr; fold subst.
    apply H with (x0:=x)(tx:=tx); auto.
    rewrite app_comm_cons.
    rewrite subst_env_cons.
    assert (Htmp : ([x' /e S n0] t'1 :: G1) = [(x' lshift_v 1) rshift_v 1 /e S n0] t'1 :: G1 );
      [destruct x'; simpl; auto;
       rewrite <- minus_n_O; auto|
       rewrite Htmp].
    apply H0 with (x0:=x lshift_v 1)(tx:=tx lshift_t 1); fold left_shift_var; auto.
    rewrite lrshift_n_var; auto.
    crush.
    admit. (*typing weakening*)

    admit. (*typing weakening*)

    apply notin_subst_type; auto.
    admit.
    destruct x'; crush.

    destruct t'; inversion H; subst.
    apply wf_sel_lower with (t:=[x' /t S n] t); auto.


    
    
    SearchAbout notin_ty.
    
    
  Qed.

  Lemma subst_wf_mutind :
    (forall G t, G vdash t wf_t -> forall G1 tg G2, G = G1++tg::G2 ->
                                     forall n, n = length G1 ->
                                          n notin_e G1 ->
                                           forall t', t = ([c_ n /t n] t') ->
                                                 forall  x, G2 vdash x hasType tg ->
                                                       G1++G2 vdash [x /t n] t' wf_t) /\
    (forall G d, G vdash d wf_d -> forall G1 tg G2, G = G1++tg::G2 ->
                                     forall n, n = length G1 ->
                                          n notin_e G1 ->
                                           forall d', d = ([c_ n /dt n] d') ->
                                                 forall  x, G2 vdash x hasType tg ->
                                                       G1++G2 vdash [x /dt n] d' wf_d) /\
    (forall G ds, G vdash ds wf_ds -> forall G1 tg G2, G = G1++tg::G2 ->
                                        forall n, n = length G1 ->
                                             n notin_e G1 ->
                                             forall ds', ds = ([c_ n /dts n] ds') ->
                                                    forall  x, G2 vdash x hasType tg ->
                                                          forall i, i = Some n ->
                                                               (G1 [i] rjump_e ++G2 vdash [x /dts n] ds' wf_ds).
  Proof.

  Qed.

                             t2, t1 = ([c_ 0 /t 0] t2) ->
                                 forall t' G', G = t'::G' ->
                                          forall x, G' vdash x hasType t' ->
                                               G' vdash [x /t 0] t2 wf_t) /\
    (forall G d1, G vdash d1 wf_d -> forall d2, d1 = ([c_ 0 /dt 0] d2) ->
                                 forall t' G', G = t'::G' ->
                                          forall x, G' vdash x hasType t' ->
                                               G' vdash [x /dt 0] d2 wf_d) /\
    (forall G ds1, G vdash ds1 wf_ds -> forall ds2, ds1 = ([c_ 0 /dts 0] ds2) ->
                                 forall t' G', G = t'::G' ->
                                          forall x, G' vdash x hasType t' ->
                                               G' vdash [x /dts 0] ds2 wf_ds).

  Lemma subst_wf_mutind :
    (forall G t1, G vdash t1 wf_t -> forall t2, t1 = ([c_ 0 /t 0] t2) ->
                                 forall t' G', G = t'::G' ->
                                          forall x, G' vdash x hasType t' ->
                                               G' vdash [x /t 0] t2 wf_t) /\
    (forall G d1, G vdash d1 wf_d -> forall d2, d1 = ([c_ 0 /dt 0] d2) ->
                                 forall t' G', G = t'::G' ->
                                          forall x, G' vdash x hasType t' ->
                                               G' vdash [x /dt 0] d2 wf_d) /\
    (forall G ds1, G vdash ds1 wf_ds -> forall ds2, ds1 = ([c_ 0 /dts 0] ds2) ->
                                 forall t' G', G = t'::G' ->
                                          forall x, G' vdash x hasType t' ->
                                               G' vdash [x /dts 0] ds2 wf_ds).
  Proof.
    apply wf_mutind; intros; auto.

    destruct t2; simpl in H; inversion H; simpl; auto.

    destruct t2; simpl in H; inversion H; simpl; auto.

    destruct t0; simpl in H1; inversion H1.
    simpl; apply wf_arr.
    apply H with (t':=t'); auto.
    apply H0.
  Qed.

  Lemma has_contains_wf_mutind :
    (forall G p d, G vdash p ni d -> G wf_e -> G vdash d wf_d) /\
    (forall G t d, G vdash d cont t -> G wf_e -> G vdash t wf_t -> forall p, G vdash p hasType t -> G vdash [p /dt 0]d wf_d).
  Proof.
    apply has_contains_mutind; intros; auto.

    apply H; auto.
    apply wf_typing with (x:=p); auto.

    inversion H0; subst.
    
  Qed.

  Lemma has_contains_unique_mutind :
    (forall G x d, G vdash x ni d -> G vdash x wf_v -> G wf_e -> forall d', G vdash x ni d' -> id d' = id d -> d' = d) /\
    (forall G t d, G vdash d cont t -> G vdash t wf_t -> G wf_e -> forall d', G vdash d' cont t -> id d' = id d -> d' = d).
  Proof.
    apply has_contains_mutind; intros.

    inversion H2; subst.
    apply typing_unique with (t:=t) in H4; auto; subst.
    apply H in H5; subst; auto.
    apply wf_typing with (x:=p); auto.
    destruct d0; destruct d; simpl in H3; simpl; inversion H3; auto.

    inversion H1; subst.
    inversion H; subst.
    apply wf_decl_tys_unique with (d1:=[c_ 0 /dt 0]d0)(d2:=[c_ 0 /dt 0]d) in H4; auto.
    apply subst_equals_decl_ty with (n:=1) in H4; subst; auto.
    apply ge_in_dty with (ds:=ds); auto.
    apply ge_notin_Sn_decl_tys; auto.
    apply subst_ge_decl_tys with (v:=c_ 0)(x:=0).
    apply wf_ge_O_decl_tys with (G:=str ds ::G).
    inversion H; subst; auto.
    apply ge_in_dty with (ds:=ds); auto.
    apply ge_notin_Sn_decl_tys; auto.
    apply subst_ge_decl_tys with (v:=c_ 0)(x:=0).
    apply wf_ge_O_decl_tys with (G:=str ds ::G).
    inversion H; subst; auto.
    destruct d0; destruct d; simpl in H2; auto.

    inversion H3; subst.
    apply H in H8; auto.
    inversion H8; subst.
    apply H0 in H10; auto.
    admit. (*has_contains_wf_mutind*)
    inversion h; subst.
    inversion H6; subst.
    apply wf_variable.
    apply get_some_index with (t:=t2); auto.


  Qed.
        

  Lemma subtype_transistivity_mutind :
    (forall t2 G1 t1 G2, G1 vdash t1 <; t2 dashv G2 -> (forall t3 G3, G2 vdash t2 <; t3 dashv G3 -> G1 vdash t1 <; t3 dashv G3)) /\
    (forall d2 G1 d1 G2, G1 vdash d1 <;; d2 dashv G2 -> (forall d3 G3, G2 vdash d2 <;; d3 dashv G3 -> G1 vdash d1 <;; d3 dashv G3)) /\
    (forall ds2 G1 ds1 G2, G1 vdash ds1 <;;; ds2 dashv G2 -> (forall ds3 G3, G2 vdash ds2 <;;; ds3 dashv G3 -> G1 vdash ds1 <;;; ds3 dashv G3)).
  Proof.
    apply type_mutind; intros; auto.

    admit.
    

    
    
    inversion H0; subst; auto.
    inversion H1; subst; auto.
    admit.
    admit.
    inversion H1; subst; auto.
    admit.
    apply s_struct.
    apply H with (G2:=(str d)::G2); auto.
    

    apply sub_top_equiv in H; auto.
    apply sub_equiv_top_all; auto.

    inversion H1; subst; auto.
    apply s_arr.
    admit.
    apply H0; auto.
    
  Qed.
