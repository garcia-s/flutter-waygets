#! /bin/bash

## Zig on deez
curl -o zig.tar.xz https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz
mkdir $HOME/dev 
tar xf zig.tar.xz -C $HOME/dev

echo 'export PATH="$HOME/dev/zig:$PATH"' >> $HOME/.bashrc
echo '## Zig deez nuts install'

## Limpieza
rm zig.tar.xz

## Flutter deez nuts
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa
curl -o flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.0-stable.tar.xz
tar xf flutter.tar.xz -C $HOME/dev

echo '## Flutter install'
echo 'export PATH="$HOME/dev/flutter/bin:$PATH"' >> $HOME/.bashrc

## Limpiar el script
rm flutter.tar.xz


## Instalar las librerias
sudo apt-get install -y make pkgconf libxkbcommon-dev libwayland-dev libglew-dev libegl-dev
