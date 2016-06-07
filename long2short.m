function [int16HiVal,int16LoVal] = long2short(int32Bit)
	%bits 1-16 of int32Bit
	int16LoVal = bitand(uint32(int32Bit), uint32(intmax('uint16')));
	
	%bits 17-32 of int32Bit
	int16HiVal = bitshift(int32Bit,-16,32);
end