all:
	@make -C src/
	([ "`readlink simcomp`" != "src/simcomp" ] && (rm -f simcomp ; ln -s src/simcomp .)) ; true

clean:
	@make -C src/ clean
