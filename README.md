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
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

#### Install dependencies

```bash
flatpak install [--user] flathub org.gnome.Platform//3.28
flatpak install [--user] flathub org.freedesktop.Platform//1.6
flatpak install [--user] flathub org.freedesktop.Platform.GL
flatpak install [--user] flathub org.freedesktop.Platform.GL32
flatpak install [--user] flathub io.elementary.Loki.BaseApp//stable
flatpak install [--user] flathub org.gnome.Sdk//3.28
flatpak update [--user]
```

#### Build

```bash
git clone https://github.com/tkashkin/GameHub.git --branch flatpak
cd GameHub
flatpak-builder --ccache --repo=repo --force-clean build com.github.tkashkin.gamehub.json
flatpak remote-add --if-not-exists --no-gpg-verify gamehub repo
```

#### Install

```bash
flatpak install [--user] gamehub com.github.tkashkin.gamehub
```

#### Run

```bash
flatpak run [-v] com.github.tkashkin.gamehub [--debug]
```