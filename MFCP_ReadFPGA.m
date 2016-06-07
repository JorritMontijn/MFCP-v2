function structVals = MFCP_ReadFPGA(sMS,xem,intBitNr,boolReset)
	%MFCP_ReadFPGA Works similar to ReadFPGA, except it's through the
	%master process (and therefor slower)
	%   Syntax:
	%	- structVals = MFCP_ReadFPGA(sMS,xem,intBitNr,boolReset)
	%
	% History:
	%
	% 2012-10-04	Matlab FPGA Control Protocol functions created by
	%				Jorrit S. Montijn for use with the FPGA Interface
	
	%get msgID
	global MFCP_msgID
	if isempty(MFCP_msgID) || MFCP_msgID >= intmax('uint8')
		MFCP_msgID = ones(1,1,'uint8');
	else
		MFCP_msgID = MFCP_msgID + 1;
	end
	msgID = MFCP_msgID;
	
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
	sFlagsOut.type = 0;
	
	%format for shared memory
	sMsg.flags = MFCP_setFlags(sFlagsOut);
	sMsg.target = msmf_Con.Data(1).processID;
	sMsg.source = intID;
	sMsg.msg = msgID;
	sMsg.xem = xem;
	sMsg.data = formatDataReadFPGA(intBitNr,boolReset);
	
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
	
	%wait for answer from master
	boolAnswered = false;
	while ~boolAnswered
		%check for answer
		vecPendingAnswers = MFCP_getPendingList(msmf_IO.Data,1);
		vecPendingAList = find(vecPendingAnswers);
		
		if ~isempty(vecPendingAList)
			for indAns=1:length(vecPendingAList)
				%get msg
				intAns = vecPendingAList(indAns);
				
				[sAns,intStart] = MFCP_getMsg(msmf_IO,intAns,0);
				
				%check if this is the answer
				if sAns.target == intID && sAns.source == msmf_Con.Data(1).processID && sAns.msg == sMsg.msg
					sFlags =  MFCP_getFlags(sAns.flags);
					if sFlags.type == 2 %this is the answer
						boolAnswered = true;
						msmf_IO.Data(intStart) = sAns.flags-128; %unset pending
						structVals = getStructVals(sAns.data);
					end
				end
			end
		end
	end
end
function structVals = getStructVals(arrayData)
	%pre-allocate
	structVals = struct;
	
	
	%SENSOR0
	low8 = arrayData(1);
	high8 = arrayData(2);
	structVals.SENSOR0 = typecast([low8 high8], 'uint16');
	
	%SENSOR1
	low8 = arrayData(3);
	high8 = arrayData(4);
	structVals.SENSOR1 = typecast([low8 high8], 'uint16');
	
	%ACTUATOR0
	low8 = arrayData(5);
	high8 = arrayData(6);
	structVals.ACTUATOR0 = typecast([low8 high8], 'uint16');
	
	%ACTUATOR1
	low8 = arrayData(7);
	high8 = arrayData(8);
	structVals.ACTUATOR1 = typecast([low8 high8], 'uint16');
	
	%ACTUATOR2
	low8 = arrayData(9);
	high8 = arrayData(10);
	structVals.ACTUATOR2 = typecast([low8 high8], 'uint16');
	
	%KLOK0
	low8 = arrayData(11);
	high8 = arrayData(12);
	structVals.KLOK0 = typecast([low8 high8], 'uint16');
	
	%KLOK1
	low8 = arrayData(13);
	high8 = arrayData(14);
	structVals.KLOK1 = typecast([low8 high8], 'uint16');
	
	%FIRSTUP0
	low8 = arrayData(15);
	high8 = arrayData(16);
	structVals.FIRSTUP0 = typecast([low8 high8], 'uint16');
	
	%FIRSTUP1
	low8 = arrayData(17);
	high8 = arrayData(18);
	structVals.FIRSTUP1 = typecast([low8 high8], 'uint16');
	
	%FIRSTDOWN0
	low8 = arrayData(19);
	high8 = arrayData(20);
	structVals.FIRSTDOWN0 = typecast([low8 high8], 'uint16');
	
	%FIRSTDOWN1
	low8 = arrayData(21);
	high8 = arrayData(22);
	structVals.FIRSTDOWN1 = typecast([low8 high8], 'uint16');
	
	%LASTDOWN0
	low8 = arrayData(23);
	high8 = arrayData(24);
	structVals.LASTDOWN0 = typecast([low8 high8], 'uint16');
	
	%LASTDOWN1
	low8 = arrayData(25);
	high8 = arrayData(26);
	structVals.LASTDOWN1 = typecast([low8 high8], 'uint16');
	
	%COUNTER
	low8 = arrayData(27);
	high8 = arrayData(28);
	structVals.COUNTER = typecast([low8 high8], 'uint16');
	
	%QUADRATURE
	low8 = arrayData(29);
	high8 = arrayData(30);
	structVals.QUADRATURE = typecast([low8 high8], 'uint16');
end
function arData = formatDataReadFPGA(intBitNr,boolReset)
	arData = zeros(1,32,'uint8');
	
	%set bit number
	vec8 = typecast(uint16(intBitNr), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(1) = vec8(1);
	arData(2) = vec8(2);
	
	%set reset
	vec8 = typecast(uint16(boolReset), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(3) = vec8(1);
	arData(4) = vec8(2);
end
