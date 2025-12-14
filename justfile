test:
        zola serve --open --drafts
deploy:
        zola built
        neocities push public --prune
clean:
        rm public -r
