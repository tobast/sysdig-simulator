struct Memory {
	Memory(size_t nbBits) : nbBits(nbBits) {
		elemLen = sizeof(unsigned long) * 8;
		int len = ceil(double(nbBits)/elemLen);
		memory = new unsigned long[len];
	}
	~Memory() {
		delete[] memory;
	}
	void clear() {
		for(size_t i=0; i < nbBits/elemLen; i++)
			memory[i] = 0;
	}
	void setBit(int pos, bool bit) {
		memory[pos/elemLen] ^= (-((unsigned long)bit) ^ memory[pos/elemLen])
			& ((unsigned long)1<<(pos%elemLen));
	}
	void setByte(int pos, unsigned char byte) {
		memory[pos/sizeof(unsigned long)] &= ~((unsigned long)(0xFF)
			<< (8*(pos%sizeof(unsigned long))));
		memory[pos/sizeof(unsigned long)] |= ((unsigned long)byte)
			<< (8*(pos%sizeof(unsigned long)));
	}
	bool getBit(int pos) {
		return (memory[pos/elemLen] &
			((unsigned long)1<<(pos%elemLen))) != 0;
	}
	bool operator[](int pos) {
		return getBit(pos);
	}
	unsigned char getByte(int pos) {
		return (memory[pos/sizeof(unsigned long)])
			>> (8*(pos%sizeof(unsigned long)));
	}
	size_t size() const {
		return nbBits;
	}

	Memory slice(size_t beg, size_t end) { //end excluded
		Memory mem(end-beg);
		int shift=beg/elemLen;
		mem.memory[0] = memory[shift] >> (beg % elemLen);
		for(size_t pos=1; pos <= (end-beg-1)/elemLen; pos++) {
			mem.memory[pos] = memory[shift+pos] >> (beg % elemLen);
			mem.memory[pos-1] |= memory[shift+pos] << (elemLen - beg%elemLen);
		}
		return mem;
	}

	size_t nbBits;
	int elemLen;
	unsigned long* memory;
};
