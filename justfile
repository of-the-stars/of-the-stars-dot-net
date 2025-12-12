test:
        hugo serve -OD
preview:
        hugo serve -O
deploy:
        hugo
        neocities push public --prune
clean:
        rm public -r
