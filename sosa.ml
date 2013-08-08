
type ('a, 'b) result = [
  | `Ok of 'a
  | `Error of 'b
]

module type BASIC_CHAR = sig

  type string
  type t

  val of_ocaml_char: char -> t option
  val of_int: int -> t option

  val size: t -> int
  val serialize: t -> string

  val to_string_hum: t -> String.t

end

module type BASIC_STRING = sig


  type character
  type t

  val of_character: character -> t
  val of_character_list: character list -> t

  val get: t -> index:int -> character option
  (** Get the n-th char, not necessarily bytes or bits. *)

  val set: t -> index:int -> v:character -> t option
  (** String should not be mutable. *)

  val length: t -> int

  val concat: ?sep:t -> t list -> t

  val to_ocaml_string: t -> string
  val to_string_hum: t -> string


end

open Printf

module List = ListLabels
let return x : (_, _) result = `Ok x
let fail x : (_, _) result = `Error x
let bind x f =
  match x with
  | `Ok o -> f o
  | `Error e -> fail e
let (>>=) = bind

module type NATIVE_STRING = sig

  include BASIC_STRING
    with type t = String.t
    with type character = char

  module Char: BASIC_CHAR
    with type string = t
    with type t = char

end

module Native_string : NATIVE_STRING = struct

  include StringLabels
  type character = char

  module Char = struct

    type string = t
    type t = char

    let of_ocaml_char x = Some x
    let of_int x =
      try Some (char_of_int x) with _ -> None

    let size _ = 1
    let serialize x = String.make 1 x

    let is_print t = ' ' <= t && t <= '~'
    let to_string_hum x =
      if is_print x then serialize x
      else sprintf "0x%2x" (int_of_char x)

  end

  let of_character = String.make 1
  let of_character_list cl =
    let length = List.length cl in
    let buf = String.make length '\x00' in
    List.iteri cl ~f:(fun i c -> buf.[i] <- c);
    buf

  let get s ~index =
    try Some (s.[index])
    with _ -> None

  let set s ~index ~v =
    if index > String.length s - 1
    then None
    else begin
      let cop = String.copy s in
      cop.[index] <- v;
      Some cop
    end

  let to_ocaml_string x = String.copy x
  let to_string_hum x = sprintf "%S" x

  let concat ?(sep="") sl = concat ~sep sl

end
