+++
title = "03 NixOS For The Layperson"
date = "2026-05-28"

description = "Managing a NixOS machine for someone who'd never used Linux before"
[params]
  author = 'Stellae'

tags = ["myself","nix", "linux", "nixos", "flatpak"]
+++

## TL;DR

I made a little NixOS setup for my girlfriend to use on this HP notebook I found at a secondhand store and fixed up. She hadn't had a computer for a good while and was wanting one to draw and use for job hunting. I saw the opportunity to try out my multi-machine NixOS setup and doing some sysadmin practice. 

## Why NixOS for a Linux newbie?

The reason I decided on NixOS and not any other more "approachable" distro is because of NixOS's *reliability*. Once I know a setup works, there's very little one can do to break it. Plus it means I have the ability to tweak the config *without access to the machine*. I can just boot up a test flash drive to try it out, and then know that it's gonna work just as I'd like it on the target machine. 

## The deets

So for the desktop environment I went with KDE Plasma. It's simple, flexible, and most like other user interfaces my girlfriend may be familiar with. It's also the same one my Steam Deck uses in desktop mode, so she's had some experience with it.

For software I put most of the basic needs and wants that would likely never change in Nixpkgs, and supplemented the rest via Flatpaks. I set up the KDE Discover store for her by wrapping it and adding it as a package in the machine's config.

```nix
  discoverWrapped = pkgs.symlinkJoin {
    name = "discoverFlatpakBackend";
    paths = [
      pkgs.kdePackages.discover
    ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/plasma-discover --add-flags "--backends flatpak"
    '';
```

## What's next

For me, the main next step is to migrate her config over to my dotfile rewrite once I'm done with that. I've made some clever snippets of nix code to iterate over host setups and I want to make as smooth a transition as possible. I also want to limit how many items are kept in the store since the computer has pretty low specs.

Another major change I'd like to make is to be able to deploy updates automatically over a network. I still haven't figured out the best way to go about that without disrupting her experience, so if anyone has any tips please reach out with them!

## Resources I Used

[2023 NixCon talk by Martin Wimpress](https://www.youtube.com/watch?v=FDY-x_hvj1o)
