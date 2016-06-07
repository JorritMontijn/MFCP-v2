function MFCP_CloseSlave(sMS,boolCloseMaster)
	%MFCP_CloseSlave Closes connection the master process and frees up a
	%connection slot.
	%   Syntax:
	%	- MFCP_CloseSlave(sMS,boolCloseMaster)
	%
	%	Inputs:
	%	- sMS: structure MFCP Slave: contains data needed for communication
	%	- boolCloseMaster: if 1, sends message to the master to shut down
	%
	% History:
	%
	% 2012-10-04	Matlab FPGA Control Protocol functions created by
	%				Jorrit S. Montijn for use with the FPGA Interface
	
	%close master
	if boolCloseMaster
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
		sFlagsOut.type = 5;

		%format for shared memory
		sMsg.flags = MFCP_setFlags(sFlagsOut);
		sMsg.target = msmf_Con.Data(1).processID;
		sMsg.source = intID;
		sMsg.msg = randi(intmax('uint8'),1,'uint8');
		sMsg.xem = 0;
		sMsg.data = 0;

		%search open spot
		intMsgMax = size(msmf_IO.Data,1) / intMsgLength;
		vecPossibleQueries = zeros(intMsgMax,1);
		vecPossibleQueries(intNr:intProcesses:intMsgMax) = 1;
		vecPendingQueries = MFCP_getPendingList(msmf_IO.Data,0);
		vecOpen = vecPossibleQueries & ~vecPendingQueries;
		intMsg = find(vecOpen,1,'first');

		%send request
		MFCP_setMsg(sMsg,msmf_IO,intMsg);
	end
	
	%close connection
	sMS.msmf_Con.Data(sMS.intNr).processID = zeros(1,1,'uint32');
end

