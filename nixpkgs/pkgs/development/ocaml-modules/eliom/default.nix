{ stdenv, fetchzip, which, ocsigen_server, ocsigen_deriving, ocaml, lwt_camlp4,
  lwt_react,
  opaline, ppx_tools, ppx_deriving, findlib
, js_of_ocaml-ocamlbuild, js_of_ocaml-ppx, js_of_ocaml-ppx_deriving_json
, js_of_ocaml-lwt
, js_of_ocaml-tyxml
, lwt_ppx
}:

stdenv.mkDerivation rec
{
  pname = "eliom";
  version = "6.7.0";

  src = fetchzip {
    url = "https://github.com/ocsigen/eliom/archive/${version}.tar.gz";
    sha256 = "0mrlpvjaihpsf2xr6p1gs0sz4cwzkknf5b1s32bhmqq5qzsh4j8k";
  };

  patches = [ ./camlp4.patch ];

  buildInputs = [ ocaml which findlib js_of_ocaml-ocamlbuild js_of_ocaml-ppx_deriving_json opaline ppx_tools
    ocsigen_deriving
  ];

  propagatedBuildInputs = [
    js_of_ocaml-lwt
    js_of_ocaml-ppx
    js_of_ocaml-tyxml
    lwt_camlp4
    lwt_ppx
    lwt_react
    ocsigen_server
    ppx_deriving
  ];

  installPhase = "opaline -prefix $out -libdir $OCAMLFIND_DESTDIR";

  setupHook = [ ./setup-hook.sh ];

  meta = {
    homepage = http://ocsigen.org/eliom/;
    description = "Ocaml Framework for programming Web sites and client/server Web applications";

    longDescription =''Eliom is a framework for programming Web sites
    and client/server Web applications. It introduces new concepts to
    simplify programming common behaviours and uses advanced static
    typing features of OCaml to check many properties of the Web site
    at compile time. If you want to write a Web application, Eliom
    makes possible to write the whole application as a single program
    (client and server parts). A syntax extension is used to
    distinguish both parts and the client side is compiled to JS using
    Ocsigen Js_of_ocaml.'';

    license = stdenv.lib.licenses.lgpl21;

    maintainers = [ stdenv.lib.maintainers.gal_bolle ];
  };
}