{ lib, stdenv, python3, openssl
, enableSystemd ? stdenv.isLinux
}:

with python3.pkgs;

let
  matrix-synapse-ldap3 = buildPythonPackage rec {
    pname = "matrix-synapse-ldap3";
    version = "0.1.4";

    src = fetchPypi {
      inherit pname version;
      sha256 = "01bms89sl16nyh9f141idsz4mnhxvjrc3gj721wxh1fhikps0djx";
    };

    propagatedBuildInputs = [ service-identity ldap3 twisted ];

    # ldaptor is not ready for py3 yet
    doCheck = !isPy3k;
    checkInputs = [ ldaptor mock ];
  };

in buildPythonApplication rec {
  pname = "matrix-synapse";
  version = "1.9.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0ghmxzk2njid7d7ccggda8a9zx4dg1r59n5ymp8f2n9kxz7z2rj2";
  };

  patches = [
    # adds an entry point for the service
    ./homeserver-script.patch
  ];

  propagatedBuildInputs = [
    setuptools
    bcrypt
    bleach
    canonicaljson
    daemonize
    frozendict
    jinja2
    jsonschema
    lxml
    matrix-synapse-ldap3
    msgpack
    netaddr
    phonenumbers
    pillow
    (prometheus_client.overrideAttrs (x: {
      src = fetchPypi {
        pname = "prometheus_client";
        version = "0.3.1";
        sha256 = "093yhvz7lxl7irnmsfdnf2030lkj4gsfkg6pcmy4yr1ijk029g0p";
      };
    }))
    psutil
    psycopg2
    pyasn1
    pymacaroons
    pynacl
    pyopenssl
    pysaml2
    pyyaml
    requests
    signedjson
    sortedcontainers
    treq
    twisted
    unpaddedbase64
    typing-extensions
  ] ++ lib.optional enableSystemd systemd;

  checkInputs = [ mock parameterized openssl ];

  doCheck = !stdenv.isDarwin;

  checkPhase = ''
    PYTHONPATH=".:$PYTHONPATH" ${python3.interpreter} -m twisted.trial tests
  '';

  meta = with stdenv.lib; {
    homepage = https://matrix.org;
    description = "Matrix reference homeserver";
    license = licenses.asl20;
    maintainers = with maintainers; [ ralith roblabla ekleog pacien ma27 ];
  };
}
