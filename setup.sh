#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')   # Always put this in Bourne shell scripts

#Install various utilities
sudo \
    apt-get install \
        pngquant \
        graphicsmagick \
        python-gdal \
        unzip \
        imagemagick \
        cpanminus \
        python-imaging \
        perltidy \
        carton \
        gdal-bin

carton install

#Get some utilities
git clone https://github.com/jlmcgraw/parallelGdal2tiles.git
git clone https://github.com/mapbox/mbutil.git
git clone https://github.com/jlmcgraw/tilers_tools.git
# git clone https://github.com/vss-devel/tilers-tools.git



#Setup hooks to run perltidy on git commit
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
find . -maxdepth 1 -type f -name '*.pl' -or -name '*.pm' | \
    xargs -I{} -P0 sh -c 'perltidy -b -noll {}'
EOF

chmod +x .git/hooks/pre-commit
