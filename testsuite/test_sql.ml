(* Copyright (C) 2014--2023  Petter A. Urkedal <paurkedal@gmail.com>
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version, with the LGPL-3.0 Linking Exception.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * and the LGPL-3.0 Linking Exception along with this library.  If not, see
 * <http://www.gnu.org/licenses/> and <https://spdx.org>, respectively.
 *)

open Printf

type abc = [`Aye | `Bee | `Cee]

let string_of_abc = function
  | `Aye -> "aye"
  | `Bee -> "bee"
  | `Cee -> "cee"

let abc_of_string = function
  | "aye" -> Ok `Aye
  | "bee" -> Ok `Bee
  | "cee" -> Ok `Cee
  | _ -> Error "abc_of_string"

module Q = struct
  open Caqti_type.Std
  open Caqti_request.Infix

  let select_null_etc =
    t2 (option int) (option int) -->! t2 bool (option int) @:-
    "SELECT ? IS NULL, ?"

  let select_and = t2 bool bool -->! bool @:-
    "SELECT ? AND ?"
  let select_plus_int = t2 int int -->! int @:-
    "SELECT ? + ?"
  let select_plus_int64 = t2 int64 int64 -->! int64 @:-
    "SELECT ? + ?"
  let select_plus_float = t2 float float -->! float @:-
    "SELECT ? + ?"
  let select_cat = t2 string string -->! string @@:- function
   | `Mysql -> "SELECT concat(?, ?)"
   | _ -> "SELECT ? || ?"
  let select_octets_identity = octets -->! octets @@:- function
   | `Mysql -> "SELECT CAST(? AS binary)"
   | `Pgsql -> "SELECT ?"
   | `Sqlite -> "SELECT CAST(? AS blob)"
   | _ -> failwith "Unimplemented."

  let select_compound_option =
    (t2 (option int) (option int) -->!
     t3 int (option (t3 (option int) (option int) (option int))) int) @:-
    "SELECT -1, $1 + 1, $2 + 1, $1 + 1, -2"

  let abc = enum ~encode:string_of_abc ~decode:abc_of_string "abc"

  let create_type_abc = unit -->. unit @:-
    "CREATE TYPE abc AS ENUM ('aye', 'bee', 'cee')"
  let drop_type_abc = unit -->. unit @:-
    "DROP TYPE IF EXISTS abc"
  let create_table_test_abc = unit -->. unit @@:- function
   | `Pgsql ->
      "CREATE TEMPORARY TABLE test_abc (e abc PRIMARY KEY, s char(3) NOT NULL)"
   | `Mysql ->
      "CREATE TEMPORARY TABLE test_abc \
        (e ENUM('aye', 'bee', 'cee') PRIMARY KEY, s char(3) NOT NULL)"
   | `Sqlite ->
      "CREATE TEMPORARY TABLE test_abc (e text PRIMARY KEY, s char(3) NOT NULL)"
   | _ -> failwith "Unimplemented."
  let drop_table_test_abc = unit -->. unit @:-
    "DROP TABLE test_abc"
  let insert_into_test_abc = t2 abc string -->. unit @:-
    "INSERT INTO test_abc VALUES (?, ?)"
  let select_from_test_abc = unit -->* t2 abc string @:-
    "SELECT * FROM test_abc"

  let select_expanded = unit -->! t2 int string @@:- function
   | `Mysql -> "SELECT $(x1), CAST($(x2) AS char)"
   | _ -> "SELECT $(x1), $(x2)"

  let create_post_connect = unit -->. unit @:-
    "CREATE TEMPORARY TABLE test_post_connect \
      (id serial PRIMARY KEY, word text NOT NULL)"
  let insert_into_post_connect = string -->. unit @:-
    "INSERT INTO test_post_connect (word) VALUES (?)"

  let create_tmp = unit -->. unit @@:- function
   | `Pgsql ->
      "CREATE TEMPORARY TABLE test_sql \
         (id SERIAL NOT NULL, \
          i INTEGER NOT NULL, \
          s TEXT NOT NULL, \
          o BYTEA NOT NULL)"
   | `Mysql ->
      "CREATE TEMPORARY TABLE test_sql \
         (id SERIAL NOT NULL, \
          i INTEGER NOT NULL, \
          s TEXT NOT NULL, \
          o BLOB NOT NULL)"
   | `Sqlite ->
      "CREATE TEMPORARY TABLE test_sql \
         (id INTEGER PRIMARY KEY, \
          i INTEGER NOT NULL, \
          s TEXT NOT NULL, \
          o BLOB NOT NULL)"
   | _ -> failwith "Unimplemented."
  let create_tmp_nullable = unit -->. unit @@:- function
   | `Pgsql ->
      "CREATE TEMPORARY TABLE test_sql \
        (id SERIAL NOT NULL, i INTEGER NOT NULL, s TEXT, o BYTEA)"
   | `Mysql ->
      "CREATE TEMPORARY TABLE test_sql \
        (id SERIAL NOT NULL, i INTEGER NOT NULL, s TEXT, o BLOB)"
   | `Sqlite ->
      "CREATE TEMPORARY TABLE test_sql \
        (id INTEGER PRIMARY KEY, i INTEGER NOT NULL, s TEXT, o BLOB)"
   | _ -> failwith "Unimplemented."
  let create_tmp_binary = unit -->. unit @@:- function
   | `Pgsql ->
      "CREATE TEMPORARY TABLE test_sql \
        (id SERIAL NOT NULL, data BYTEA NOT NULL)"
   | `Mysql ->
      "CREATE TEMPORARY TABLE test_sql \
        (id SERIAL NOT NULL, data BLOB NOT NULL)"
   | `Sqlite ->
      "CREATE TEMPORARY TABLE test_sql \
        (id INTEGER PRIMARY KEY, data BLOB NOT NULL)"
   | _ -> failwith "Unimplemented"
  let drop_tmp = unit -->. unit @@:- function
   | _ -> "DROP TABLE test_sql"
  let insert_into_tmp = t3 int string octets -->. unit @:-
    "INSERT INTO test_sql (i, s, o) VALUES (?, ?, ?)"
  let update_in_tmp_where_i = t2 octets int -->. unit @:-
    "UPDATE test_sql SET o = ? WHERE i = ?"
  let update_in_tmp = unit -->. unit @:-
    "UPDATE test_sql SET s = 'ZERO'"
  let delete_from_tmp_where_i = int -->. unit @:-
    "DELETE FROM test_sql WHERE i = ?"
  let delete_from_tmp = unit -->. unit @:-
    "DELETE FROM test_sql"
  let select_from_tmp = unit -->* t3 int string octets @:-
    "SELECT i, s, o FROM test_sql ORDER BY i ASC"
  let select_from_tmp_where_i_lt =
    int -->* t3 int string octets @:-
    "SELECT i, s, o FROM test_sql WHERE i < ?"
  let select_from_tmp_nullable =
    unit -->* t3 int (option string) (option octets) @:-
      "SELECT i, s, o FROM test_sql"
  let select_from_tmp_binary = unit -->* octets @:-
    "SELECT data FROM test_sql"

  let create_tmp_array = unit -->. unit @@:- function
   | `Pgsql ->
      "CREATE TEMPORARY TABLE test_sql_array \
        (id SERIAL NOT NULL, names TEXT[] NOT NULL)"
   | _ -> failwith "Unimplemented"
  let drop_tmp_array = unit -->. unit @@:- function
   | _ -> "DROP TABLE test_sql_array"
  let insert_into_tmp_array =
    t2 int (Caqti_type.field (Array String)) -->. unit @:-
    "INSERT INTO test_sql_array (id, names) VALUES (?, ?)"
  let select_from_tmp_array = unit -->* t2 int (Caqti_type.field (Array String)) @:-
    "SELECT id, names FROM test_sql_array ORDER BY id ASC"
  let select_from_tmp_array_where_id_in =
    Caqti_type.field (Array Int) -->* t2 int (Caqti_type.field (Array String)) @:-
      "SELECT id, names FROM test_sql_array WHERE id = ANY (?)"

  let select_current_time = unit -->! ptime @:-
    "SELECT current_timestamp"
  let select_given_time = ptime -->! ptime @@:- function
    | `Pgsql | `Sqlite -> "SELECT ?"
    | `Mysql  -> "SELECT CAST(? AS datetime)"
    | _ -> failwith "Unimplemented."
  let compare_to_known_time = ptime -->! bool @@:- function
    | `Pgsql  -> "SELECT ? = '2017-01-29T12:00:00.001002Z'"
    | `Sqlite -> "SELECT ? = '2017-01-29 12:00:00.001'"
    | `Mysql  -> "SELECT CAST(? AS datetime) \
                       = CAST('2017-01-29T12:00:00.001002' AS datetime)"
    | _ -> failwith "Unimplemented."
  let select_interval = ptime_span -->! ptime_span @@:- function
    | `Pgsql | `Sqlite -> "SELECT ?"
    | `Mysql -> "SELECT CAST(? AS double)"
    | _ -> failwith "Unimplemented"
end

module Make (Ground : Testlib.Sig.Ground) = struct
  open Ground
  open Ground.Fiber.Infix

  let repeat n f =
    let rec loop i =
      if i = n then Fiber.return () else
      f i >>= fun () -> loop (i + 1) in
    loop 0

  let env _ = let open Caqti_query in function
   | "x1" -> L"734"
   | "x2" -> Q"I'm quoted."
   | _ -> raise Not_found

  let test_expand (module Db : CONNECTION) =
    Db.find Q.select_expanded () >>= or_fail >|= fun (x1, x2) ->
    Alcotest.(check int) "expanded int" 734 x1;
    Alcotest.(check string) "expanded quote" "I'm quoted." x2

  let post_connect (module Db : CONNECTION) =
    Db.exec Q.create_post_connect () >|= function
     | Ok x -> Ok x
     | Error err -> Error (`Post_connect err)

  let test_post_connect (module Db : CONNECTION) =
    Db.exec Q.insert_into_post_connect "swallow" >>= or_fail

  let test_expr (module Db : CONNECTION) =

    let maybe_deallocate q =
      if Random.int 50 = 0 then
        Db.deallocate q >>= or_fail
      else
        Fiber.return ()
    in

    (* Non-prepared and prepared with non-linear parameters and quotes. *)
    repeat 254 (fun i ->
      let i = i mod 127 + 1 in
      let oneshot = i < 127 in
      let s1 = String.make 1 (Char.chr i) in
      let s2 = String.make i '\'' in
      let req = Caqti_request.create ~oneshot
        Caqti_type.(t2 int int)
        Caqti_type.(t8 int int int64 int string string string int)
        Caqti_mult.one
        Caqti_query.(fun di ->
          let cast_if_mariadb tn f =
            (match Caqti_driver_info.dialect_tag di with
             | `Mysql -> fun x -> S[L"CAST("; f x; L" AS "; L tn; L")"]
             | _ -> f)
          in
          let quote_int = cast_if_mariadb "INTEGER"
            (match i mod 4 with
             | 0 -> fun x -> V (Caqti_type.Field.Int, x)
             | 1 -> fun x -> V (Caqti_type.Field.Int16, x)
             | 2 -> fun x -> V (Caqti_type.Field.Int32, Int32.of_int x)
             | 3 -> fun x -> V (Caqti_type.Field.Int64, Int64.of_int x)
             | _ -> assert false)
          in
          let quote_string = cast_if_mariadb "CHAR"
            (match i mod 2 with
             | 0 -> fun x -> Q x
             | 1 -> fun x -> V (Caqti_type.Field.String, x)
             | _ -> assert false)
          in
          S[
            L "SELECT ";
            P 1; L " + 10, ";     (* last parameter first *)
            P 1; L " + 20, ";     (* and duplicated *)
            (quote_int (i + 30)); L ", "; (* first quote *)
            L (string_of_int i); L ", ";
            quote_string s1; L ", "; (* second quote *)
            L "'"; L (string_of_int i); L "'"; L ", ";
            quote_string s2; L ", "; (* third quote *)
            P 0; L " + 10";       (* first paramater last *)
          ])
      in
      Db.find req (i + 1, i + 2) >>= or_fail
        >>= fun (i12, i22, i30, i', s1', si', s2', i11) ->
      (if oneshot then Fiber.return () else Db.deallocate req >>= or_fail)
        >|= fun () ->
      Alcotest.(check int) "first $2 occurrence" (i + 12) i12;
      Alcotest.(check int) "second $2 occurrence" (i + 22) i22;
      Alcotest.(check int64) "first quote" (Int64.of_int (i + 30)) i30;
      Alcotest.(check int) "int literal" (i + 11) i11;
      Alcotest.(check int) "int literal" i i';
      Alcotest.(check string) "second quote" s1 s1';
      Alcotest.(check string) "third quote" s2 s2';
      Alcotest.(check string) "only $1 occurrence" (string_of_int i) si'
    ) >>= fun () ->

    (* Prepared: null *)
    repeat 3 (fun _ ->
      maybe_deallocate Q.select_null_etc >>= fun () ->
      Db.find Q.select_null_etc (None, None) >>= or_fail >>= fun (c1, c2) ->
      assert (c1 && c2 = None);
      Fiber.return ()
    ) >>= fun () ->

    (* Prepared: bool *)
    let ck_and a b =
      maybe_deallocate Q.select_and >>= fun () ->
      Db.find Q.select_and (a, b) >>= or_fail >|= fun c ->
      assert (c = (a && b)) in
    ck_and false false >>= fun () -> ck_and false true >>= fun () ->
    ck_and true  false >>= fun () -> ck_and true  true >>= fun () ->

    (* Prepared: int *)
    let ck_plus_int i j =
      maybe_deallocate Q.select_plus_int >>= fun () ->
      Db.find Q.select_plus_int (i, j) >>= or_fail >>= fun k ->
      assert (k = (i + j)); Fiber.return () in
    repeat 200 (fun _ ->
      let i, j = Random.int (1 lsl 29), Random.int (1 lsl 29) in
      ck_plus_int i j
    ) >>= fun () ->

    (* Prepared: int64 *)
    let ck_plus_int64 i j =
      maybe_deallocate Q.select_plus_int64 >>= fun () ->
      Db.find Q.select_plus_int64 (i, j) >>= or_fail >|= fun k ->
      assert (k = Int64.add i j) in
    repeat 200 (fun _ ->
      let i = Random.int64 Int64.(shift_left one 29) in
      let j = Random.int64 Int64.(shift_left one 29) in
      ck_plus_int64 i j
    ) >>= fun () ->

    (* Prepared: float *)
    let ck_plus_float x y =
      maybe_deallocate Q.select_plus_float >>= fun () ->
      Db.find Q.select_plus_float (x, y) >>= or_fail >>= fun z ->
      assert (abs_float (z -. (x +. y)) < 1e-6 *. (x +. y));
      Fiber.return () in
    repeat 200 (fun _ ->
      let i, j = Random.float 1e8, Random.float 1e8 in
      ck_plus_float i j
    ) >>= fun () ->

    (* Prepared: string *)
    let ck_string x y =
      maybe_deallocate Q.select_cat >>= fun () ->
      Db.find Q.select_cat (x, y) >>= or_fail >>= fun s ->
      assert (s = x ^ y); Fiber.return () in
    repeat 200 (fun _ ->
      let x = sprintf "%x" (Random.int (1 lsl 29)) in
      let y = sprintf "%x" (Random.int (1 lsl 29)) in
      ck_string x y
    ) >>= fun () ->

    (* Prepared: octets *)
    let ck_octets x =
      maybe_deallocate Q.select_cat >>= fun () ->
      Db.find Q.select_octets_identity x >>= or_fail >>= fun s ->
      assert (s = x); Fiber.return () in
    repeat 256 (fun i ->
      let x = sprintf "%c" (Char.chr i) in
      ck_octets x
    ) >>= fun () ->

    (* Prepared: time *)
    begin
      let t0 = Ptime_clock.now () in
      Db.find Q.select_current_time () >>= or_fail >>= fun t ->
      let t1 = Ptime_clock.now () in
      assert (Ptime.to_float_s t0 -. 1.1 <= Ptime.to_float_s t &&
              Ptime.to_float_s t <= Ptime.to_float_s t1 +. 1.1);
      Db.find Q.select_given_time t >>= or_fail >>= fun t' ->
      assert (Ptime.Span.to_float_s (Ptime.Span.abs (Ptime.diff t t')) < 1.1);
      Db.find Q.compare_to_known_time (Ptime.v (17195, 43200_001_002_000_000L))
               >>= or_fail >>= fun r ->
      assert r;
      let rec test_times = function
       | [] -> Fiber.return ()
       | tf :: tfs ->
          let t =
            (match Ptime.Span.of_float_s tf with
             | Some t -> t
             | None -> assert false) in
          Db.find Q.select_interval t >>= or_fail >>= fun t' ->
          assert Ptime.Span.(equal (round ~frac_s:6 t) (round ~frac_s:6 t'));
          test_times tfs
      in
      test_times [0.0; -1.2e-5; 1.23e-3; -1.001; 1.23e2; -1.23e5]
    end >>= fun () ->

    (* Prepared: compound option *)
    let check x y z =
      Db.find Q.select_compound_option (x, y) >>= or_fail
        >|= fun (a, b, c) ->
      assert (a = -1 && b = z && c = -2);
    in
    check None None None >>= fun () ->
    check None (Some 3) (Some (None, Some 4, None)) >>= fun () ->
    check (Some 7) None (Some (Some 8, None, Some 8)) >>= fun () ->
    check (Some 7) (Some 3) (Some (Some 8, Some 4, Some 8))

  let test_enum (module Db : CONNECTION) =
    let with_type_abc f =
      (match Caqti_driver_info.dialect_tag Db.driver_info with
       | `Sqlite | `Mysql -> f ()
       | _ ->
          Db.exec Q.drop_type_abc () >>=? fun () ->
          Db.exec Q.create_type_abc () >>=? fun () ->
          f () >>=? fun () ->
          Db.exec Q.drop_type_abc ())
    in
    with_type_abc begin fun () ->
      Db.exec Q.create_table_test_abc () >>=? fun () ->
      Db.exec Q.insert_into_test_abc (`Bee, "bee") >>=? fun () ->
      Db.collect_list Q.select_from_test_abc () >>=? fun rows ->
      assert (rows = [`Bee, "bee"]);
      Db.exec Q.drop_table_test_abc ()
    end >>= or_fail

  let test_table (module Db : CONNECTION) =
    (* Create, insert, select *)
    Db.exec Q.create_tmp () >>= or_fail >>= fun () ->
    begin
      if Caqti_driver_info.can_transact Db.driver_info then
        Db.start () >>= or_fail >>= fun () ->
        Db.exec Q.insert_into_tmp (1, "one", "one")
        >>= or_fail >>= fun () ->
        Db.rollback () >>= or_fail
      else
        Fiber.return ()
    end >>= fun () ->
    Db.start () >>= or_fail >>= fun () ->
    Db.exec Q.insert_into_tmp (2, "two", "two\x00")
    >>= or_fail >>= fun () ->
    Db.exec Q.insert_into_tmp (3, "three", "three'\"")
    >>= or_fail >>= fun () ->
    Db.exec Q.insert_into_tmp (5, "five", "five\x05")
    >>= or_fail >>= fun () ->
    Db.commit () >>= or_fail >>= fun () ->
    Db.fold Q.select_from_tmp
      (fun (i, s, o) (i_acc, s_acc, o_acc) ->
        i_acc + i, s_acc ^ "+" ^ s, o_acc ^ "+" ^ o)
      ()
      (0, "zero", "zero")
    >>= or_fail >>= fun (i_acc, s_acc, o_acc) ->
    assert (i_acc = 10);
    assert (s_acc = "zero+two+three+five");
    assert (o_acc = "zero+two\x00+three'\"+five\x05");
    Db.exec Q.drop_tmp () >>= or_fail

  let test_arrays (module Db : CONNECTION) = (
    match Db.driver_info |> Caqti_driver_info.dialect_tag with
    | `Pgsql -> ()
    | _ -> Alcotest.skip ());
    Db.exec Q.create_tmp_array () >>= or_fail >>= fun () ->
    Db.start () >>= or_fail >>= fun () ->
    Db.exec Q.insert_into_tmp_array (1, ["one";"un";"ein"])
    >>= or_fail >>= fun () ->
    Db.exec Q.insert_into_tmp_array (2, ["two";"deux";"zwei"])
    >>= or_fail >>= fun () ->
    Db.exec Q.insert_into_tmp_array (3, ["three";"trois";"drei"])
    >>= or_fail >>= fun () ->
    Db.commit () >>= or_fail >>= fun () ->
    Db.collect_list Q.select_from_tmp_array ()
    >>= or_fail >>= fun rows ->
    Alcotest.(check (list (pair int (list string)))) "returned rows"
      [(1,["one";"un";"ein"]);(2,["two";"deux";"zwei"]);(3,["three";"trois";"drei"])]
      rows;
    Db.collect_list Q.select_from_tmp_array_where_id_in
      [0; 1; 2]
    >>= or_fail >>= fun rows ->
    Alcotest.(check (list (pair int (list string)))) "returned rows"
      [(1,["one";"un";"ein"]);(2,["two";"deux";"zwei"])]
      rows;
    Db.exec Q.drop_tmp_array () >>= or_fail

  let test_affected_count (module Db : CONNECTION) =
    let select_all exp_i exp_s exp_o =
      Db.fold Q.select_from_tmp
        (fun (i, s, o) (i_acc, s_acc, o_acc) ->
          i_acc + i, s_acc ^ "+" ^ s, o_acc ^ "+" ^ o)
        ()
        (0, "zero", "zero")
      >>= or_fail >>= fun (i_acc, s_acc, o_acc) ->
      assert (i_acc = exp_i);
      assert (s_acc = exp_s);
      assert (o_acc = exp_o);
      Fiber.return ()
    in
    let check_affected n = function
     | Ok nrows -> assert (nrows = n); Fiber.return ()
     | Error `Unsupported -> Fiber.return ()
     | Error #Caqti_error.t as err -> or_fail err
    in

    (* prepare db *)
    Db.exec Q.create_tmp () >>= or_fail >>= fun () ->
    Db.start () >>= or_fail >>= fun () ->
    Db.exec_with_affected_count Q.insert_into_tmp (2, "two", "X")
    >>= check_affected 1 >>= fun () ->
    Db.exec Q.insert_into_tmp (3, "three", "Y")
    >>= or_fail >>= fun () ->
    Db.exec Q.insert_into_tmp (5, "five", "Z")
    >>= or_fail >>= fun () ->
    select_all 10 "zero+two+three+five" "zero+X+Y+Z" >>= fun () ->

    (* update where i = 1 -> 0 affected rows *)
    Db.exec_with_affected_count Q.update_in_tmp_where_i ("null", 0)
    >>= check_affected 0 >>= fun () ->
    select_all 10 "zero+two+three+five" "zero+X+Y+Z" >>= fun () ->

    (* update where i = 3 -> 1 affected row*)
    Db.exec_with_affected_count Q.update_in_tmp_where_i ("drei", 3)
    >>= check_affected 1 >>= fun () ->
    select_all 10 "zero+two+three+five" "zero+X+drei+Z" >>= fun () ->

    (* update w/o id -> 3 affected rows *)
    Db.exec_with_affected_count Q.update_in_tmp ()
    >>= check_affected 3 >>= fun () ->
    select_all 10 "zero+ZERO+ZERO+ZERO" "zero+X+drei+Z" >>= fun () ->

    (* delete where i = 1 -> no affected rows *)
    Db.exec_with_affected_count Q.delete_from_tmp_where_i 1
    >>= check_affected 0 >>= fun () ->
    select_all 10 "zero+ZERO+ZERO+ZERO" "zero+X+drei+Z" >>= fun () ->

    (* delete where i = 3 -> one affected row *)
    Db.exec_with_affected_count Q.delete_from_tmp_where_i 3
    >>= check_affected 1 >>= fun () ->
    select_all 7 "zero+ZERO+ZERO" "zero+X+Z" >>= fun () ->

    (* delete where i = 3 -> no affected rows *)
    Db.exec_with_affected_count Q.delete_from_tmp_where_i 3
    >>= check_affected 0 >>= fun () ->
    select_all 7 "zero+ZERO+ZERO" "zero+X+Z" >>= fun () ->

    (* delete w/o condition -> 2 affected rows *)
    Db.exec_with_affected_count Q.delete_from_tmp ()
    >>= check_affected 2 >>= fun () ->
    select_all 0 "zero" "zero" >>= fun () ->
    Db.commit () >>= or_fail >>= fun () ->
    Db.exec Q.drop_tmp () >>= or_fail

  let test_tuples =
    let module Q = struct
      open Caqti_type.Std
      open Caqti_request.Infix
      let sel2 =
        t2 int int -->! t2 int int @:-
        "SELECT -$2, -$1"
      let sel3 =
        t3 int int int -->! t3 int int int @:-
        "SELECT -$3, -$2, -$1"
      let sel4 =
        t4 int int int int -->! t4 int int int int @:-
        "SELECT -$4, -$3, -$2, -$1"
      let sel5 =
        t5 int int int int int -->! t5 int int int int int @:-
        "SELECT -$5, -$4, -$3, -$2, -$1"
      let sel6 =
        t6 int int int int int int -->! t6 int int int int int int @:-
        "SELECT -$6, -$5, -$4, -$3, -$2, -$1"
      let sel7 =
        t7 int int int int int int int -->! t7 int int int int int int int @:-
        "SELECT -$7, -$6, -$5, -$4, -$3, -$2, -$1"
      let sel8 =
        t8 int int int int int int int int -->!
        t8 int int int int int int int int @:-
        "SELECT -$8, -$7, -$6, -$5, -$4, -$3, -$2, -$1"
    end in
    fun (module Db : CONNECTION) ->
      let i1, i2, i3, i4, i5, i6, i7, i8 = 2, 3, 5, 7, 11, 13, 17, 19 in
      let check q x y =
        Db.find q x >>= or_fail >|= fun y' -> assert (y = y')
      in
      check Q.sel2 (i1, i2) (-i2, -i1) >>= fun () ->
      check Q.sel3 (i1, i2, i3) (-i3, -i2, -i1) >>= fun () ->
      check Q.sel4 (i1, i2, i3, i4) (-i4, -i3, -i2, -i1) >>= fun () ->
      check Q.sel5 (i1, i2, i3, i4, i5) (-i5, -i4, -i3, -i2, -i1) >>= fun () ->
      check Q.sel6
        (i1, i2, i3, i4, i5, i6)
        (-i6, -i5, -i4, -i3, -i2, -i1) >>= fun () ->
      check Q.sel7
        (i1, i2, i3, i4, i5, i6, i7)
        (-i7, -i6, -i5, -i4, -i3, -i2, -i1) >>= fun () ->
      check Q.sel8
        (i1, i2, i3, i4, i5, i6, i7, i8)
        (-i8, -i7, -i6, -i5, -i4, -i3, -i2, -i1)

  let test_stream (module Db : CONNECTION) =
    let assert_stream_is expected =
      Db.call
        ~f:(fun response ->
            let open Db.Response in
            Stream.to_list @@ to_stream response >>= fun actual ->
            assert (actual = expected);
            Fiber.return (Ok ()))
        Q.select_from_tmp
        ()
    in
    Db.exec Q.create_tmp () >>= or_fail >>= fun () ->
    assert_stream_is (Ok []) >>= or_fail >>= fun () ->
    Db.exec Q.insert_into_tmp (1, "one", "one") >>= or_fail >>= fun () ->
    assert_stream_is (Ok [(1, "one", "one")]) >>= or_fail >>= fun () ->
    Db.exec Q.insert_into_tmp (2, "two", "two") >>= or_fail >>= fun () ->
    assert_stream_is (Ok [(1, "one", "one"); (2, "two", "two")])
    >>= or_fail >>= fun () ->
    Db.exec Q.drop_tmp () >>= or_fail

  let test_stream_both_ways (module Db : CONNECTION) =
    let show_string_option = function
      | None -> "None"
      | Some s -> "Some \"" ^ s ^ "\""
    in
    let assert_stream_both_ways expected =
      let input_stream = Stream.of_list expected in
      Db.exec Q.create_tmp_nullable () >>= or_fail >>= fun () ->
      Db.populate
        ~table:"test_sql"
        ~columns:["i"; "s"; "o"]
        Caqti_type.(t3 int (option string) (option octets))
        input_stream
      >|= Caqti_error.uncongested >>= or_fail >>= fun () ->
      Db.collect_list Q.select_from_tmp_nullable ()
      >>= or_fail >>= fun actual ->
      if actual <> expected then
        begin
          let repr a = a
            |> List.map (fun (i, s, o) ->
                let repr_s = show_string_option s in
                let repr_o = show_string_option o in
                "(" ^ (string_of_int i) ^ "," ^ repr_s ^ "," ^ repr_o ^ ")")
            |> String.concat "; "
            |> (fun s -> "[" ^ s ^ "]")
          in
          eprintf "Expected: %s\nActual: %s\n" (repr expected) (repr actual)
        end;
      assert (actual = expected);
      Db.exec Q.drop_tmp ()
    in
    assert_stream_both_ways
      [] >>= or_fail >>= fun () ->
    assert_stream_both_ways
      [(1, Some "one", Some "one")] >>= or_fail >>= fun () ->
    assert_stream_both_ways
      [(1, Some "one", Some "one");
       (2, Some "two", Some "two")] >>= or_fail >>= fun () ->
    assert_stream_both_ways
      [(1, Some "bad1\"\"", Some "bad1\"\"");
       (2, Some "bad2,\"\n", Some "bad2,\"\n");
       (3, None, None);
       (4, Some "", Some "");
       (5, Some "\\\"", Some "\\\"")] >>= or_fail

  let test_stream_binary (module Db : CONNECTION) =
    (* Insert and retrieve all pairs of bytes as strings *)
    let all_bytes =
      Testlib.init_list 256 (fun c -> String.make 1 (Char.chr c))
    in
    let all_pairs = all_bytes
      |> List.map (fun a -> List.map (fun b -> a ^ b) all_bytes)
      |> List.flatten
    in
    let all_pairs_len = List.length all_pairs in
    assert (all_pairs_len = 65536);
    let input_stream = Stream.of_list all_pairs in
    Db.exec Q.create_tmp_binary () >>= or_fail >>= fun () ->
    Db.populate
      ~table:"test_sql"
      ~columns:["data"]
      Caqti_type.octets
      input_stream
    >|= Caqti_error.uncongested >>= or_fail >>= fun () ->
    Db.collect_list Q.select_from_tmp_binary ()
    >>= or_fail >>= fun actual ->
    if actual <> all_pairs then
      begin
        let actual_len = List.length actual in
        if actual_len <> all_pairs_len then
          eprintf
            "Expected length: %d\nActual length: %d\n"
            all_pairs_len
            actual_len
        else
          List.iteri
            (fun i (a, e) ->
              if a <> e then
                eprintf
                  "Element in position %d differs: Actual %s, Expected: %s\n"
                  i a (String.escaped e))
            (List.combine actual all_pairs)
      end;
    assert (actual = all_pairs);
    Db.exec Q.drop_tmp () >>= or_fail

  let test_drain pool = Pool.drain pool

  let connection_test_cases = [
    "post_connect", `Quick, test_post_connect;
    "expand", `Quick, test_expand;
    "expr", `Quick, test_expr;
    "enum", `Quick, test_enum;
    "table", `Quick, test_table;
    "arrays", `Quick, test_arrays;
    "tuples", `Quick, test_tuples;
    "affected_count", `Quick, test_affected_count;
    "stream", `Quick, test_stream;
    "stream_both_ways", `Quick, test_stream_both_ways;
    "stream_binary", `Quick, test_stream_binary;
  ]
  let pool_test_cases = [
    "drain", `Quick, test_drain;
  ]

end
