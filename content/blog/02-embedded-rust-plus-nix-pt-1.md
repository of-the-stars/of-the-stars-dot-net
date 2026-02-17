+++
title = "02 Embedded Rust Plus Nix, pt. 1"
date = "2026-02-03"

description = "Building an embedded Rust workflow with Nix for the Arduino Uno."
[params]
  author = 'Stellae'

tags = ["nix", "linux", "rust", "embedded-systems", "arduino"]
+++

## TL;DR

I made an embedded Rust workflow for the Arduino Uno (more broadly, the ATMega328p chips they use) using the Nix language. It takes the form of a flake, whose template you can use right now by using 

```sh 
nix flake init -t 'github:of-the-stars/flake-templates#arduino'
```

within your embedded Rust project! It allows you to build and deploy your project to your device automatically from a remote source with one simple command. It also allows you to enter a local development sandbox with all necessary dependencies included with `nix develop` command or automatically with the wonderful [direnv](https://direnv.net/) project.

My example blink project can be built from remote using the command

```sh
nix run 'github:of-the-stars/blinkyy'
``` 

Keep reading to learn about my journey on getting here!

## Motivation

Recently I found a big huge abandoned box of DIY electronics components at my job, mostly made up of an Elegoo Mega 2560 R3 Starter Kit, plus a few extra items which included a couple of ESP32 DevKit v1s. Before this I'd bought myself an Elegoo Uno R3 Starter Kit off of Amazon a couple of years back, and I wrote some baremetal C++ and Rust for it while on Ubuntu. I'd also used it for a research experience I was a part of. However, almost immediately before finding the components that I did, I'd been running into some problems creating a Nix flake-based toolchain for my Uno to use on my NixOS machine, namely getting `rustc` to actually compile for the target architecture. I'd given up, but finding all these components and more than doubling my collection motivated me to actually knuckle down and figure out what was going on. Unfortunately, I decided to choose something that's such a niche within a niche that very little documentation exists for what I'm trying to do, and I had to piece this together via various code snippets and my growing understanding of both Nix and Rust. And in the spirit of leaving things better than how I found them, I'm writing this with the hopes that I'll be able to save other the headaches I've had to fight through.

Trying to get specifically a Nix *flake* working to cross compile Rust to the `avr-none` target using Nix was my main goal, and while I eventually got it working, it took about a month's worth of trying to do so. They main goal of the project was that with the "experimental" `nix` command, it could be possible to pull an embedded project's source code, and automatically deploy it from source with the guarantee that it's going to be the exact same resulting artifact with every invocation of a single command, that being

```sh
nix run 'github:of-the-stars/blinkyy'
``` 

If you have an Arduino Uno, try it! As long as you have Nix installed, with the `nix-command` and `flakes` experimental flags, and a stable internet connection, this will build a simple Rust program that flashes the on-board LED 10 times a second.

The beautiful part is that this eliminates the hard part of embedded deployment so that anyone wanting to flash firmware can do so easily and frictionlessly. As a developer, this simplifies the often complicated installation of embedded toolchains, managing source, and building the firmware with specific flags for my end users and collaborators. 

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

Seems simple enough, and minus Ravedude and the Arduino, this looks identical to a lot of others' setups for building Rust projects with Nix. The main blocker was the hardware itself. Getting a Rust toolchain declaratively set up with Nix seemed possible; `avr-none` was at least a supported target, albeit a tier three one. If it weren't an officially supported target, like `xtensa-none-elf` which is the ESP32 target, that's a whole other ballgame, and it warrants a part 2 in this series.

The main supervoid that ate up all my time was trying to use `nixpkgs`'s built-in cross compilation framework to build the package. The main reason this simply doesn't work is because Nix isn't running on the Arduino. While getting Nix working in an embedded context seems like an interesting exercise, the ATMega328p microcontroller on the Arduino simply doesn't have the power to run such an overhead. Once I moved past this approach, I started to make leaps in progress towards the final goal.

The second major obstacle was getting Crane, the Nix library, to actually build for the Arduino. By this time,, I'd already gotten the pretty simple dev envrionment set up, and running `cargo build` or `cargo run` worked just fine to build and flash the artifact to the board. However with Crane, I kept hitting snags where certain dependencies couldn't be reached when running `nix build`, but running `cargo build` in the dev shell worked just fine. 

As it turns out, as part of its effort to maintain reproducibility, Crane *vendors* its Cargo dependencies, keeping the entire dependency graph in the Nix store. The reason this doesn't work out of the box with the Arduino target is because `avr-none` is a tier three target for the Rust language. In all Rust projects targeting ATMega microcontrollers, we have to pass `-Z build-std=core` to the Rust compiler to build the core Rust language from scratch because the Rust Foundation does not provide pre-built artifacts for the `avr-none` target. So whenever Crane vendors its dependencies, including the `rust-src` component via the custom toolchain we provided, it can't find the crates that `core` depends on. Now, when inspecting the Nix store, I found out that Rust already vendored `core`'s dependencies for us, and placed them together to be found locally. But Crane doesn't automatically know that, so I figured out that I have to provide it the `core`'s `Cargo.lock` file to let Crane know that all of its dependencies are already packaged, and that it doesn't need to look among its own vendored dependencies to find them. Unfortunately, to automatically do this from our custom Rust toolchain would result in what we in Nix circles call Import From Derivation, or IFD. Scary, no? Apparently it is, because it's a performance boogeyman that throws a wrench in the way Nix evaluates expressions. So we have to manually update the lockfile locally, which is a bit of a dirty hack. The next major version of this workflow will need to at least update this automatically and keep it tied to the `flake.lock` file which dictates which cached version of the Rust toolchain we'll use.

```nix,linenos,linenostart=59
# Helps vendor 'core' so that all its dependencies can be found
cargoVendorDir = craneLib.vendorMultipleCargoDeps {
  inherit (craneLib.findCargoFiles src) cargoConfigs;
  cargoLockList = [
    ./Cargo.lock
    ./toolchain/Cargo.lock
  ];
};
```

The goal is to make this automatic as a part of running `nix flake update`, or to just bite the bullet and just accept the IFD anyway. However, I like my builds to be completely pure, so it'll likely take me a while before I get a breakthrough with it.

## Conclusion

Now that I've built this workflow, it's gonna be time to actually put it to the test and build some projects using it. While I get the IFD situation figured out, I'll also be looking to create the same workflow for the ESP32. However, since the chips I have aren't officially supported `rustc` targets, I'll either be waiting for the `gccrs` front-end to be completed, or more likely, have the Espresif-maintained forks of Rust and LLVM be merged upstream to use.

## Resources I Used

- [oxalica Rust overlay rust-bin cheatsheet](https://github.com/oxalica/rust-overlay?tab=readme-ov-file#cheat-sheet-common-usage-of-rust-bin)
- [oxalica Rust overlay cross compilation examples](https://github.com/oxalica/rust-overlay/blob/master/examples/cross-aarch64/flake.nix)
- [oxalica Rust overlay cross compilation docs](https://github.com/oxalica/rust-overlay/blob/master/docs/cross_compilation.md)
- ["Just a simple Nix Flake for Rust and WASM" by Gijs Burghoorn](https://gburghoorn.com/posts/just-nix-rust-wasm/)
- [The avr-none section of the rustc book](https://doc.rust-lang.org/beta/rustc/platform-support/avr-none.html)
- [Cargo environment variables](https://doc.rust-lang.org/cargo/reference/environment-variables.html#environment-variables-cargo-sets-for-build-scripts)
- [avr-hal docmentation](https://github.com/Rahix/avr-hal)
- [Crane cross compilation docs](https://github.com/ipetkov/crane/blob/master/examples/cross-rust-overlay/flake.nix)
- [Crane build customization docs](https://crane.dev/customizing_builds.html)
