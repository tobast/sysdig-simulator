all:
	@make -C src/
	ln -s src/simcomp .

clean:
	@make -C src/ clean
