	vector<bitset<__ROM_WORD_SIZE> > ___rom(0,false);
	if(argc > 1) // 1st argument must be ROM content
		readROM<__ROM_WORD_SIZE>(___rom, argv[1]);

