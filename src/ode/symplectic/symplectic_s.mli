(*
 * OWL - OCaml Scientific and Engineering Computing
 * OWL-ODE - Ordinary Differential Equation Solvers
 *
 * Copyright (c) 2019 Ta-Chu Kao <tck29@cam.ac.uk>
 * Copyright (c) 2019 Marcello Seri <m.seri@rug.nl>
 *)

type mat = Owl_dense_matrix_s.mat

module Symplectic_Euler: Types.SolverT
  with type s = mat * mat
   and type t = mat
   and type output = mat * mat * mat

module PseudoLeapfrog: Types.SolverT
  with type s = mat * mat
   and type t = mat
   and type output = mat * mat * mat

module Leapfrog: Types.SolverT
  with type s = mat * mat
   and type t = mat
   and type output = mat * mat * mat

module Ruth3: Types.SolverT
  with type s = mat * mat
   and type t = mat
   and type output = mat * mat * mat

module Ruth4: Types.SolverT
  with type s = mat * mat
   and type t = mat
   and type output = mat * mat * mat


(* ----- helper function ----- *)

val to_state_array : 
  ?axis:int ->
  int * int ->
  mat ->
  mat ->
  mat array * mat array
