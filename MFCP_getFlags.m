function sFlags = MFCP_getFlags(arFlags)
	%MFCP_getFlags Puts flag byte array into structure format
	%   sFlags =  MFCP_getFlags(arFlags)
	%
	% History:
	%
	% 2012-10-04	Matlab FPGA Control Protocol functions created by
	%				Jorrit S. Montijn for use with the FPGA Interface
	
	sFlags.pending = bitget(arFlags,8);
	sFlags.answer = bitget(arFlags,7);
	sFlags.eom = bitget(arFlags,6);
	sFlags.msgnr = bitget(arFlags,5)*2 + bitget(arFlags,4);
	sFlags.type = bitget(arFlags,3)*4 + bitget(arFlags,2)*2 + bitget(arFlags,1);
end

