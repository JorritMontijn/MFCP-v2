function MFCP_SetAudio(sMS,dblTime,varAudio) %#ok<INUSD>
	%MFCP_SetAudio Use this function to send an audio request
	%   Syntax:  MFCP_SetAudio(sMS,dblTime,varAudio)
	%
	%	Here, sMS is the structure returned by MFCP_InitSlave(), dblTime is
	%	the requested OS time (returned by the function now()) when the
	%	command should be executed and varAudio is a variable that will be
	%	relayed to MFCP_PlayAudio() in the Audio Warden session.
	%
	%	N.B.: due to writing and reading to/from the hard disk, the command
	%	has a latency of ~10ms. Also, the precision of now() is limited to
	%	1ms resolution, so achieving higher temporal precision than 1ms is
	%	unfortunately not possible until MATLAB increases now()'s precision
	%
	% History:
	%
	% 2014-01-20	Created MFCP_SetAudio function as addition to the 
	%				Matlab FPGA Control Protocol functions
	
	%define list of accepted characters
	strAcceptedList = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
	
	%search untaken temp file name
	boolKeepSearching = true;
	while boolKeepSearching
		%get random string
		vecRand = randi(length(strAcceptedList),[1 32]);
		strRand = strAcceptedList(vecRand);
		
		%transmute to uint8
		arString = cast(strRand,'uint8');
		
		%create filename
		strFile = [strRand '.mat'];
		
		%check if it exists
		if ~exist(strFile,'file')
			boolKeepSearching = false;
		end
	end
	
	%save data to file
	save(strFile,'dblTime','varAudio');
	
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
	sMsg.target = msmf_Con.Data(2).processID;
	sMsg.source = intID;
	sMsg.msg = randi(intmax('uint8'),1,'uint8');
	sMsg.xem = zeros(1,10,'uint8');
	sMsg.data = arString;
	
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
	
	%send to setMsg
	MFCP_setMsg(sMsg,msmf_IO,intMsg);
end

