{ stdenv, fetchFromGitHub, lib, nodejs, yarn, gnome, glib, libgda, gsound, wrapGAppsHook }:

stdenv.mkDerivation rec {
  pname = "gnome-shell-extension-pano";
  version = "6b199fde";

  src = fetchFromGitHub {
    owner = "oae";
    repo = "gnome-shell-pano";
    rev = "6b199fde92fe62b351138b8d44a3f32d5d37c8f7";
    sha256 = "17ky1li1q251s0c6vxv6rh60f73yiryavwm8v2cdfd4by1pipki7";
    fetchSubmodules = true;
  };

  __noChroot = true;

  buildInputs = [
    gnome.gnome-shell
    libgda
    gsound
    glib
    nodejs
    yarn
  ];

  nativeBuildInputs = [
    wrapGAppsHook
  ];

  buildPhase = ''
    export HOME=$TMPDIR
    export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-bundle.crt
    yarn install
    yarn build
  '';

  installPhase = ''
    runHook preInstall

    substituteInPlace dist/extension.js \
      --replace "import GSound from 'gi://GSound'" \
"imports.gi.GIRepository.Repository.prepend_search_path('${gsound}/lib/girepository-1.0'); const GSound = (await import('gi://GSound')).default;" \
      --replace "import Gda from 'gi://Gda?version>=5.0'" \
"imports.gi.GIRepository.Repository.prepend_search_path('${libgda}/lib/girepository-1.0'); const Gda = (await import('gi://Gda?version>=5.0')).default;"

    local_ext_dir=$out/share/gnome-shell/extensions/pano@elhan.io
    install -d $local_ext_dir
    cp -r dist/* $local_ext_dir

    # Ensure typelibs are directly accessible
    mkdir -p $out/lib/girepository-1.0
    ln -s ${gsound}/lib/girepository-1.0/* $out/lib/girepository-1.0/
    ln -s ${libgda}/lib/girepository-1.0/* $out/lib/girepository-1.0/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Pano GNOME Shell Clipboard Management Extension";
    homepage = "https://github.com/oae/gnome-shell-pano";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    maintainers = [];
  };
}
