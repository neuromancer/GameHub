# GameHub [![Build Status](https://travis-ci.com/tkashkin/GameHub.svg?branch=master)](https://travis-ci.com/tkashkin/GameHub)
Games manager/downloader/library written in Vala for elementary OS

## flatpak packaging branch
This branch contains flatpak packaging files

#### Runtime dependencies

* `org.gnome.Platform//3.28`
* `org.freedesktop.Platform//1.6`
* `io.elementary.Loki.BaseApp//stable`
* `org.freedesktop.Platform.Compat32`
* `org.freedesktop.Platform.GL`
* `org.freedesktop.Platform.GL32`
* `org.freedesktop.Platform.ffmpeg`

#### Build dependencies

* `org.gnome.Sdk//3.28`

## Building

#### Add flathub repo

```bash
flatpak remote-add [--user] --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

#### Install dependencies

```bash
flatpak-builder --install-deps-from=flathub --install-deps-only [--user] build com.github.tkashkin.gamehub.json
flatpak update
```

#### Build

```bash
git clone https://github.com/tkashkin/GameHub.git --branch flatpak --recursive
cd GameHub
flatpak-builder --install [--user] --ccache --repo=repo --force-clean build com.github.tkashkin.gamehub.json
flatpak remote-add [--user] --if-not-exists --no-gpg-verify gamehub repo
```

#### Run

```bash
flatpak run [-v] com.github.tkashkin.gamehub [--debug]
```