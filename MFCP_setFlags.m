function arFlags = MFCP_setFlags(sFlags)
	%MFCP_setFlags Puts flag structure into array format
	%   arFlags =  MFCP_setFlags(sFlags)
	%
	% History:
	%
	% 2012-10-04	Matlab FPGA Control Protocol functions created by
	%				Jorrit S. Montijn for use with the FPGA Interface
	
	%pre-allocate array
	arFlags = zeros(1,1,'uint8');
	
	%put flags into array from structure
	arFlags = bitset(arFlags,8,sFlags.pending);
	arFlags = bitset(arFlags,7,sFlags.answer);
	arFlags = bitset(arFlags,6,sFlags.eom);
	
	binMsg = uint8(sFlags.type);
	arFlags = bitset(arFlags,5,bitget(binMsg, 2));
	arFlags = bitset(arFlags,4,bitget(binMsg, 1));
	
	binType = uint8(sFlags.type);
	arFlags = bitset(arFlags,3,bitget(binType, 3));
	arFlags = bitset(arFlags,2,bitget(binType, 2));
	arFlags = bitset(arFlags,1,bitget(binType, 1));
end

