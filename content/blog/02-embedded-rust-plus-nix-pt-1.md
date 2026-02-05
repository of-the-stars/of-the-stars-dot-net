+++
title = "02 Embedded Rust Plus Nix, pt. 1"
date = "2026-02-03"

draft = true

description = "Building embedded Rust workflows with Nix for the Arduino."
[params]
  author = 'Stellae'

tags = ["nix", "linux", "rust", "embedded-systems", "arduino"]
+++

## Motivation

Recently I found a big huge abandoned box of DIY electronics components at my job, mostly made up of an Elegoo Mega 2560 R3 Starter Kit, plus a few extra items which included a couple of ESP32 DevKit v1s. Before this I'd bought myself an Elegoo Uno R3 Starter Kit off of Amazon a couple of years back, and I wrote some baremetal C++ and Rust for it while on Ubuntu. Plus I'd used it for a research experience I had. However almost immediately before finding the components that I did, I'd been running into some problems creating a Nix flake-based toolchain for my Uno to use on my NixOS machine, namely getting `rustc` to actually compile for the target architecture. I'd given up, but finding all these components and more than doubling my collection motivated me to actually knuckle down and figure out what was going on. Unfortunately, I decided to choose something that's such a niche within a niche that very little documentation exists for what I'm trying to do, and I had to piece this together via various code snippets and my growing understanding of both Nix and Rust. And in the spirit of leaving things better than how I found them, I'm writing this with the hopes that I'll be able to save other the headaches I've had to fight through.

Trying to get specifically a Nix *flake* working to cross compile Rust to the `avr-none` target using Nix was my main goal, and while I eventually got it working, it took about a month's worth of trying to do so. They main goal of the project was that with the "experimental" `nix` command, it could be possible to pull an embedded project's source code, and automatically deploy it from source with the guarantee that it's going to be the exact same resulting artifact with every invocation of a single command, that being

```sh
nix run 'github:of-the-stars/blinkyy'
``` 

If you have an Arduino Uno, try it! As long as you have Nix installed, with the `nix-command` and `flakes` experimental flags, and a stable internet connection, this will build a simple Rust program that flashes the on-board LED 10 times a second.

The beautiful part is that this simplifies embedded deployment so that anyone wanting to flash firmware can do so easily and frictionlessly. As a developer, this simplifies the often complicated installation of embedded toolchains, managing source, and building the firmware with specific flags for my end users and collaborators. 

## The Great Battle

The Goliath of this particular fight, as it is with most niche Nix applications, is the complete lack of comprehensive up-to-date documentation. Nix has been evolving quite rapidly in recent years, especially since 2021. The core of the Nix language and package manager, the most well documented parts, haven't changed much. But when it comes to the newer features like Nix Flakes, the best one can do follow breadcrumbs like a sleuth to piece together an understanding. And I agree with people like [cafkafk](https://cafkafk.dev/), a current member of the Nix Steering Committe, that the flake interfaces aren't unstable at all and that a path to release needs to be made immediately. For many, myself included, flakes are what finally made Nix "click" and make sense. Before I switched my system to using flakes, fiddling with channels and various `shell.nix` files felt extremely weird, since they seemed to violate the whole "pure derivation" thing that I'd seen emphasized across the project. And pulling specific revisions from hard-coded magic number git revisions felt like an ugly hack that I did not want to deal with.

This is why a flake-based approach was so important to me. It greatly simplifies the development and deployment, and the ability to do 5 different things with 2 small files and a couple command invocations seems like magic.

For this project the main stack is:

- An Elegoo Uno R3
- The [avr-hal](https://github.com/Rahix/avr-hal) to provide Rust abstractions to interact with the hardware
- Oxalica's [rust-overlay](https://github.com/oxalica/rust-overlay) to use tell Nix which Rust toolchain to use
- [Crane](https://github.com/ipetkov/crane) as the Nix library to build the rust code
- A Nix flake to create a development environment, package the code, and create a shell script to flash the firmware
- [Ravedude](https://github.com/Rahix/avr-hal/tree/main/ravedude) as a fancy `avrdude` wrapper to flash the firmware and open a console

Seems simple enough, and minus Ravedude and the special hardware, this looks identical to a lot of others' setups for building Rust projects with Nix. The main blocker was the hardware itself. Getting a Rust toolchain declaratively set up with Nix seemed possible; `avr-none` was at least a supported target, albeit a tier three one. If it weren't an officially supported target, like `xtensa-none-elf`which the ESP32 targets, that's a whole other ballgame, and it warrants a part 2 in this series.

## Resources I Used
- [oxalica Rust overlay rust-bin cheatsheet](https://github.com/oxalica/rust-overlay?tab=readme-ov-file#cheat-sheet-common-usage-of-rust-bin)
- [oxalica Rust overlay cross compilation examples](https://github.com/oxalica/rust-overlay/blob/master/examples/cross-aarch64/flake.nix)
- [oxalica Rust overlay cross compilation docs](https://github.com/oxalica/rust-overlay/blob/master/docs/cross_compilation.md)
- [steinuil's watchy-rs flake (thanks for responding to my email!)](https://github.com/steinuil/watchy-rs)
- ["Just a simple Nix Flake for Rust and WASM" by Gijs Burghoorn](https://gburghoorn.com/posts/just-nix-rust-wasm/)
- ["Setting up a reproducible cross-compiling environment in NixOS" by Zap](https://ziap.github.io/blog/nixos-cross-compilation/)
- [The avr-none section of the rustc book](https://doc.rust-lang.org/beta/rustc/platform-support/avr-none.html)
- [Cargo environment variables](https://doc.rust-lang.org/cargo/reference/environment-variables.html#environment-variables-cargo-sets-for-build-scripts)
- ["Statically Cross-Compiling Rust Projects Using Nix" by mediocregopher](https://mediocregopher.com/posts/x-compiling-rust-with-nix.gmi)
- [avr-hal docmentation](https://github.com/Rahix/avr-hal)
- [Nixpkgs cross-compilationo docs](https://nixos.org/manual/nixpkgs/stable/#chap-cross)
- [crane cross compilation docs](https://github.com/ipetkov/crane/blob/master/examples/cross-rust-overlay/flake.nix)
- [](https://ianthehenry.com/posts/how-to-learn-nix/the-standard-environment/)
- [](https://github.com/NixOS/nixpkgs/tree/master/lib/systems)
- https://crane.dev/examples/alt-registry.html
- https://crane.dev/local_development.html
- https://crane.dev/customizing_builds.html
- https://crane.dev/patching_dependency_sources.html
- https://crane.dev/faq/build-workspace-subset.html
