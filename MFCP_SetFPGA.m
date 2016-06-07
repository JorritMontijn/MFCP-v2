function MFCP_SetFPGA(sMS,xem,intBitNr,intValue,intPulse,intTriggerMode)
	%MFCP_SetFPGA Works similar to SetFPGA, except it's through the
	%master process (but hardly slower)
	%   Syntax:
	%	- MFCP_SetFPGA(sMS,xem,intBitNr,intValue,intPulse,intTriggerMode)
	%
	% History:
	%
	% 2012-10-04	Matlab FPGA Control Protocol functions created by
	%				Jorrit S. Montijn for use with the FPGA Interface
	
	%assign default values
	intProcesses = length(sMS.msmf_Con.Data);
	intMsgLength = 52;
	
	%assign values from struct
	msmf_Con = sMS.msmf_Con;
	msmf_IO = sMS.msmf_IO;
	intID = sMS.intID;
	intNr = sMS.intNr;
	
	%format request to master
	%set flags
	sFlagsOut.pending = 1;
	sFlagsOut.answer = 0;
	sFlagsOut.eom = 1;
	sFlagsOut.msgnr = 0;
	sFlagsOut.type = 1;
	
	%format for shared memory
	sMsg.flags = MFCP_setFlags(sFlagsOut);
	sMsg.target = msmf_Con.Data(1).processID;
	sMsg.source = intID;
	sMsg.msg = randi(intmax('uint8'),1,'uint8');
	sMsg.xem = xem;
	sMsg.data = formatDataSetFPGA(intBitNr,intValue,intPulse,intTriggerMode);
	
	%search open spot
	boolWaiting = true;
	while boolWaiting
		intMsgMax = size(msmf_IO.Data,1) / intMsgLength;
		vecPossibleQueries = zeros(intMsgMax,1);
		vecPossibleQueries(intNr:intProcesses:intMsgMax) = 1;
		vecPendingQueries = MFCP_getPendingList(msmf_IO.Data,0);
		vecOpen = vecPossibleQueries & ~vecPendingQueries;
		intMsg = find(vecOpen,1,'first');
		if ~isempty(intMsg)
			boolWaiting = false;
		end
	end
	
	%send request
	MFCP_setMsg(sMsg,msmf_IO,intMsg);
end
function arData = formatDataSetFPGA(intBitNr,intValue,intPulse,intTriggerMode)
	arData = zeros(1,32,'uint8');
	
	%set bit number
	vec8 = typecast(uint16(intBitNr), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(1) = vec8(1);
	arData(2) = vec8(2);
	
	%set value
	vec8 = typecast(uint16(intValue), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(3) = vec8(1);
	arData(4) = vec8(2);
	
	%set pulse
	vec8 = typecast(uint32(intPulse), 'uint8');
	arData(5) = vec8(1); %low16-low8
	arData(6) = vec8(2); %low16-high8
	arData(7) = vec8(3); %high16-low8
	arData(8) = vec8(4); %high16-high8

	%set trigger mode
	vec8 = typecast(uint16(intTriggerMode), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(9) = vec8(1);
	arData(10) = vec8(2);
end
