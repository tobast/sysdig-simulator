//###################### Useful functions if ROM/RAM are vectors ##############

void readROM(vector<bool>& rom, const char* fname) {
	ifstream handle(fname, fstream::in | fstream::binary);
	if(handle.fail())
		throw runtime_error("ROM file not found.");
	
	char c;
	while(handle.get(c)) {
		for(int i=0; i < 8; i++) {
			rom.push_back(c%2);
			c >>= 1;
		}
	}
	// Uncomment if we want to deal time for memory
	//rom.shrink_to_fit();
}

template<int outlen, int addrlen> void readMemory(bitset<outlen>& out,
		const bitset<addrlen>& addrBS, const vector<bool>& mem) {
	unsigned long addr = addrBS.to_ulong();
	if(addr + outlen >= mem.size())
		throw out_of_range("Memory access.");
	
	for(int i=0; i < outlen; i++)
		out[i] = mem[addr+i];
}

//###################### END MEMORY_VECTOR #################################### 
