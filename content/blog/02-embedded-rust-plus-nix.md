+++
title = "02 Embedded Rust Plus Nix"
date = "2025-12-17"

description = "Building embedded Rust workflows with Nix."
[params]
  author = 'Stell'

tags = ["myself","nix", "linux", "rust", "embedded-systems", "esp32", "arduino"]
+++

## Motivation

Recently I found a big huge abandoned box of DIY electronics components at my job, mostly made up of an Elegoo Mega 2560 R3 Starter Kit, plus a few extra items which included a couple of ESP32 DevKit v1s. Before this I'd bought myself an Elegoo Uno R3 Starter Kit off of Amazon a couple of years back, and I wrote some baremetal C and Rust for it while on Ubuntu. However almost immediately before finding the components that I did, I'd been running into some problems creating a Nix flake-based toolchain for my Uno to use on my NixOS machine, namely getting rust-src to actually compile for the target architecture. I'd given up, but finding all these components and more than doubling my collection motivated me to actually knuckle down and figure out what was going on. Unfortunately, I decided to choose something that's a niche within a niche of a niche that very little documentation exists for what I'm trying to do, and I had to piece this together via various code snippets and my growing understanding of both Nix and Rust. And in the spirit of leaving things better than how I found them, I'm writing this with the hopes that I'll be able to save other the headaches I've had to fight through.



## Resources I Used
- [oxalica's Rust overlay rust-bin cheatsheet](https://github.com/oxalica/rust-overlay?tab=readme-ov-file#cheat-sheet-common-usage-of-rust-bin)
- [oxalica's Rust overlay cross compilation examples](https://github.com/oxalica/rust-overlay/blob/master/examples/cross-aarch64/flake.nix)
- [steinuil's watchy-rs flake (thanks for responding to my email!)](https://github.com/steinuil/watchy-rs)
- ["Just a simple Nix Flake for Rust and WASM" by Gijs Burghoorn](https://gburghoorn.com/posts/just-nix-rust-wasm/)
- ["Setting up a reproducible cross-compiling environment in NixOS" by Zap](https://ziap.github.io/blog/nixos-cross-compilation/)
- [The avr-none section of the rustc book](https://doc.rust-lang.org/beta/rustc/platform-support/avr-none.html)
- [Cargo environment variables](https://doc.rust-lang.org/cargo/reference/environment-variables.html#environment-variables-cargo-sets-for-build-scripts)
- [Unstable Cargo build-std](https://doc.rust-lang.org/cargo/reference/unstable.html#build-std)
- ["Statically Cross-Compiling Rust Projects Using Nix" by mediocregopher](https://mediocregopher.com/posts/x-compiling-rust-with-nix.gmi)
- [avr-hal docmentation](https://github.com/Rahix/avr-hal)
