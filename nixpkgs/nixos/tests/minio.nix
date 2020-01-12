import ./make-test.nix ({ pkgs, ...} :
let
    accessKey = "BKIKJAA5BMMU2RHO6IBB";
    secretKey = "V7f1CwQqAcwo80UEIJEjc5gVQUSSx5ohQ9GSrr12";
    minioPythonScript = pkgs.writeScript "minio-test.py" ''
      #! ${pkgs.python3.withPackages(ps: [ ps.minio ])}/bin/python
      import io
      import os
      from minio import Minio
      minioClient = Minio('localhost:9000',
                    access_key='${accessKey}',
                    secret_key='${secretKey}',
                    secure=False)
      sio = io.BytesIO()
      sio.write(b'Test from Python')
      sio.seek(0, os.SEEK_END)
      sio_len = sio.tell()
      sio.seek(0)
      minioClient.put_object('test-bucket', 'test.txt', sio, sio_len, content_type='text/plain')
    '';
  in {
  name = "minio";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ bachp ];
  };

  nodes = {
    machine = { pkgs, ... }: {
      services.minio = {
        enable = true;
        inherit accessKey secretKey;
      };
      environment.systemPackages = [ pkgs.minio-client ];

      # Minio requires at least 1GiB of free disk space to run.
      virtualisation.diskSize = 4 * 1024;
    };
  };

  testScript =
    ''
      startAll;
      $machine->waitForUnit("minio.service");
      $machine->waitForOpenPort(9000);

      # Create a test bucket on the server
      $machine->succeed("mc config host add minio http://localhost:9000 ${accessKey} ${secretKey} S3v4");
      $machine->succeed("mc mb minio/test-bucket");
      $machine->succeed("${minioPythonScript}");
      $machine->succeed("mc ls minio") =~ /test-bucket/ or die;
      $machine->succeed("mc cat minio/test-bucket/test.txt") =~ /Test from Python/ or die;
      $machine->shutdown;

    '';
})