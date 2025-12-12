test:
        hugo serve -OD
preview:
        hugo serve -O
deploy:
        hugo
        neocities push public
clean:
        rm public -r
