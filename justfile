test:
        zola serve --open --drafts
build:
        zola build
deploy:
        zola build
        neocities push public --prune
clean:
        rm public -r
