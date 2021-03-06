open Owl
open Bigarray
open Owl_ode.Types


module C = Owl_ode.Common.Make (Owl_dense_ndarray.D)

let wrap x = reshape_1 x Mat.(numel x) 

let unwrap (dim1, dim2) x = 
  genarray_of_array2 (reshape_2 (genarray_of_array1 x) dim1 dim2)

let cvode_s ~stiff ~relative_tol ~abs_tol ~(f:Mat.mat -> float -> Mat.mat) ~tspan:(t0, t1) ~y0 ~dt =
  (* make a copy of y0 so we don't overwrite it*)
  let y0 = Mat.copy y0 in
  (* rhs function that sundials understands *)
  let dim1, dim2 = Mat.shape y0 in
  let f_wrapped t y yd =
    let y = unwrap (dim1, dim2) y in
    let dy = f y t in
    Array1.blit (wrap dy) yd in
  let y = wrap y0 in
  let yvec = Nvector_serial.wrap y in
  let tolerances = Cvode.(SStolerances (relative_tol, abs_tol)) in
  let session = match stiff with
    | false -> Cvode.(init Adams Functional tolerances f_wrapped t0 yvec) 
    | true  -> Cvode.(init BDF   Functional tolerances f_wrapped t0 yvec) in
  let duration = t1 -. t0 in
  Cvode.set_stop_time session duration;
  let rec until t' t1 yvec =
    if (abs_float (t1 -. t')) > 1E-10 then
      let (t', _) = Cvode.solve_normal session t1 yvec in
      until t' t1 yvec 
    else t' in
  fun _y t ->
    let t1 = t +. dt in
    let t' = until t t1 yvec in
    let y' = Mat.copy (unwrap (dim1, dim2) y) in
    y', t'

let cvode ?(stiff=false) ?(relative_tol=1E-4) ?(abs_tol=1E-8) () =
  let cvode_s' = cvode_s ~stiff ~relative_tol ~abs_tol in
  fun f y0 tspec () ->
    let (t0, t1), dt = match tspec with
      | T1 {t0; duration; dt} -> (t0, t0+.duration), dt
      | T2 {tspan; dt} -> tspan, dt 
      | T3 _ -> raise Owl_exception.NOT_IMPLEMENTED 
    in
    (* Maybe this kind of checks should go to Common -- with an odeint equivalent
       and be used everywhere. We will just pass the step function to be used in
       the integration loop: that one will take the ~f parameter. *)
    let step = cvode_s' ~f ~tspan:(t0, t1) ~y0 ~dt in
    C.integrate ~step ~dt ~tspan:(t0, t1) y0

module Owl_Cvode = struct
  type s = Mat.mat
  type t = Mat.mat
  type output = Mat.mat * Mat.mat
  let solve = cvode ~stiff:false ()
end

module Owl_Cvode_Stiff = struct
  type s = Mat.mat
  type t = Mat.mat
  type output = Mat.mat * Mat.mat
  let solve = cvode ~stiff:true ()
end 

