function int32bit = short2long(int16HiVal,int16LoVal)
	int32bit = (int16HiVal * 2^16) + int16LoVal;
end