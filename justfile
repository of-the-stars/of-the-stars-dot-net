test:
        zola serve --open --drafts
deploy:
        zola build
        neocities push public --prune
clean:
        rm public -r
