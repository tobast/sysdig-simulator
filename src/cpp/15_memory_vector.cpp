//###################### Useful functions if ROM/RAM are vectors ##############

template <int wordsize>
void readROM(vector<bitset<wordsize> >& rom, const char* fname) {
	ifstream handle(fname, fstream::in | fstream::binary);
	if(handle.fail())
		throw runtime_error("ROM file not found.");
	
	char c;
	bitset<wordsize> cBs;
	int bsPos=0;
	while(handle.get(c)) {
		for(int i=0; i < 8; i++) {
			cBs[bsPos] = c%2;
			bsPos++;
			if(bsPos == wordsize) {
				bsPos=0;
				rom.push_back(cBs);
				// No need to reset: will be erased by new data anyway.
			}
			c >>= 1;
		}
	}
	// NOTE if some bits are left in cBs, we silently ignore them.

	// Uncomment if we want to deal time for memory
	//rom.shrink_to_fit();
}

template<int wordsize, int addrlen> void readMemory(bitset<wordsize>& out,
		const bitset<addrlen>& addrBS, const vector<bitset<wordsize> >& mem) {
	unsigned long addr = addrBS.to_ulong();
	if(addr >= mem.size())
		throw out_of_range("Memory access.");
	
	out=mem[addr];
}

template<int wordsize, int addrlen> void writeMemory(const bitset<wordsize>& data,
		const bitset<addrlen>& addrBS, vector<bitset<wordsize> >& mem) {
	unsigned long addr = addrBS.to_ulong();
	if(addr >= mem.size())
		throw out_of_range("Memory write.");
	
	mem[addr] = data;
}

//###################### END MEMORY_VECTOR #################################### 
