inline bool getBit() {
	switch(getchar()) {
	case '0':
		return false;
	case '1':
		return true;
	default:
		throw invalid_argument("Invalid character received, expected '0' or '1'.");
	}
}

string revStr(string str) {
	reverse(str.begin(), str.end());
	return str;
}

int main(int argc, char** argv) {
	int nbCycles;
	scanf("%d\n", &nbCycles);

	vector<bool> ___rom(0,false);
	if(argc > 1) { // 1st argument must be ROM content
		readROM(___rom, argv[1]);
	}

