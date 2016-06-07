function [msmf_Con,msmf_IO] = MFCP_Master(sConnectFPGA)
	%MFCP_Master This function connects to an FPGA and controls the I/O for
	%all connected slave processes. After you have started this function,
	%you can use MFCP_InitSlave to connect slave processes to your master;
	%you can then use MFCP_ReadFPGA, MFCP_SetFPGA, MFCP_queryReadFPGA, and
	%MFCP_getReadFPGA to communicate with the FPGA. The maximum number of
	%FPGAs connected to the master is limited by the OpalKelly DLL; which
	%is currently 4. The maximum number of connected processes is set at
	%32, of which 1 Master and 8 Wardens, but can be increased if necessary
	%
	%   Syntax:
	%	[msmf_Con,msmf_IO] = MFCP_Master(sConnectFPGA)
	%
	%	Input:
	%	- sConnectFPGA; a structure containing information to which FPGAs
	%		you wish to connect. Required fields are: strBitFile, verbose,
	%		strSerial, and strPortDefFile. For explanation of these
	%		variables, please refer to InitFPGA.m
	%
	%	Output:
	%	- msmf_Con; memory pointer referring to the connection file that
	%		contains the IDs of all connected processes
	%	- msmf_IO; memory pointer referring to the I/O file that contains
	%		all messages from the master to its slaves and from the slaves
	%		to the master
	%
	% History:
	%
	% 2012-10-04	Matlab FPGA Control Protocol functions created by
	%				Jorrit S. Montijn for use with the FPGA Interface
	% 2014-01-20	Made some small changes to accomodate MFCPv2 for Audio
	%				Warden addition [by JM]
	%
	%Note: the master does not check if it is the only master process
	%connected; it assumes you want it to take control, no matter what. If
	%another master process is already connected, that master's identity
	%will be overwritten and all its slaves removed
	
	%% define input
	if ~exist('sConnectFPGA','var')
		%define initialization settings FPGAs
		sConnectFPGA = struct;
		sConnectFPGA(1).strBitFile = 'config20121008_XEM3001.bit';
		sConnectFPGA(1).verbose = true;
		sConnectFPGA(1).strSerial = 'AIJOPFnaiZ';
		sConnectFPGA(1).strPortDefFile = 'portdefinitions_PT.pdm';
	end
	%% set memory size
	intProcesses = 32; %number
	intMessages = 256; %number
	intMsgLength = 52; %bytes
	
	%% prepare shared memory access
	%get path
	strPath = getPath();
	
	%get filenames
	strIO = [strPath 'IO.msmf'];
	strConnections = [strPath 'connections.msmf'];
	
	%generate clean IO and connections file
	genIO(strIO,intProcesses,intMessages);
	genCon(strConnections,intProcesses);
	
	%make connection to shared mem file
	msmf_Con = memmapfile(strConnections,...
		'Writable', true,...
		'Format', {                    ...
		'uint32'  [1] 'processID'});
	
	%log on to connection file by writing ID to the master place
	intID = genID();
	msmf_Con.Data(1).processID = intID;
	
	%make IO into shared mem file
	msmf_IO = memmapfile(strIO,'Writable', true);
	
	%% make connections with FPGAs
	%connect and put into structure
	sOC = struct;
	for intCard = 1:length(sConnectFPGA)
		strBitFile = sConnectFPGA(intCard).strBitFile;
		verbose = sConnectFPGA(intCard).verbose;
		strSerial = sConnectFPGA(intCard).strSerial;
		strPortDefFile = sConnectFPGA(intCard).strPortDefFile;
		[objCard,sPortDef,structVals] = InitFPGA(strBitFile,verbose,strSerial,strPortDefFile);
		sOC(intCard).objCard = objCard;
		sOC(intCard).sPortDef = sPortDef;
		sOC(intCard).structVals = structVals;
	end
	
	%% prep loop
	intMsgMax = size(msmf_IO.Data,1) / intMsgLength;
	intMsgsPerProcess = intMsgMax / intProcesses;
	vecPossibleAnswers = zeros(intMsgMax,1);
	vecPossibleAnswers(1:intProcesses:intMsgMax) = 1;
	
	%% enable communication between slaves and FPGA
	try
		fprintf('\n\n\nMatlab FPGA Control Protocol  Master is now running and will take care of all your slaves'' requests\nTo quit, send an MFCP message to the master with the identification-flag type set to 5.\n\n')
		boolRunning = true;
		while boolRunning
			%get pending messages
			vecPendingQueries = MFCP_getPendingList(msmf_IO.Data,0);
			vecPendingAnswers = MFCP_getPendingList(msmf_IO.Data,1);
			vecPendingQList = find(vecPendingQueries);
			
			%find open answer location
			vecOpen = vecPossibleAnswers & ~vecPendingAnswers;
			if ~isempty(vecPendingQList)
				for indMsg=1:length(vecPendingQList)
					intMsg = vecPendingQList(indMsg);
					[sMsg,intStart,arThisMsg] = MFCP_getMsg(msmf_IO,intMsg); %get message
					
					if sMsg.target == intID %if target is Master
						msmf_IO.Data(intStart) = arThisMsg(1)-128; %reset pending flag
						
						%get flags
						sFlags = MFCP_getFlags(sMsg.flags);
						
						if sFlags.type == 0 %readfpga
							%get target card
							[objCard,structVals,sPortDef] = getCardByXEM(sOC,sMsg.xem);
							
							%get bit number
							low8 = sMsg.data(1);
							high8 = sMsg.data(2);
							intBitNumber = typecast([low8 high8], 'uint16');
							
							%get reset
							low8 = sMsg.data(3);
							high8 = sMsg.data(4);
							boolReset = typecast([low8 high8], 'uint16');
							
							%execute
							structVals=ReadFPGA(objCard,intBitNumber,boolReset,structVals,sPortDef);
							
							%set flags
							sFlagsOut.pending = 1;
							sFlagsOut.answer = 1;
							sFlagsOut.eom = 1;
							sFlagsOut.msgnr = 0;
							sFlagsOut.type = 2;
							
							%format for shared memory
							sOut.flags = MFCP_setFlags(sFlagsOut);
							sOut.target = sMsg.source;
							sOut.source = intID;
							sOut.msg = sMsg.msg;
							sOut.xem = sMsg.xem;
							sOut.data = formatStructValsToData(structVals);
							
							% write to shared memory
							intMsgPut = find(vecOpen,1,'first');
							vecOpen(intMsgPut) = 0;
							MFCP_setMsg(sOut,msmf_IO,intMsgPut);
						elseif sFlags.type == 1 %setfpga
							%get target card
							[objCard,structVals,sPortDef] = getCardByXEM(sOC,sMsg.xem);
							
							%get bit number
							low8 = sMsg.data(1);
							high8 = sMsg.data(2);
							intBitNumber = typecast([low8 high8], 'uint16');
							
							%get value
							low8 = sMsg.data(3);
							high8 = sMsg.data(4);
							intValue = typecast([low8 high8], 'uint16');
							
							%get pulse0
							low8 = sMsg.data(5);
							high8 = sMsg.data(6);
							intPulseLow16 = typecast([low8 high8], 'uint16');
							
							%get pulse1
							low8 = sMsg.data(7);
							high8 = sMsg.data(8);
							intPulseHigh16 = typecast([low8 high8], 'uint16');
							
							%32bit pulse
							intPulse = typecast([intPulseLow16 intPulseHigh16], 'uint32');
							
							%get triggermode
							low8 = sMsg.data(9);
							high8 = sMsg.data(10);
							intTriggerMode = typecast([low8 high8], 'uint16');
							
							%execute
							SetFPGA(objCard,intBitNumber,intValue,intPulse,intTriggerMode,sPortDef);
							
							%set flags
							sFlagsOut.pending = 0; %reply to set does not have to be read; but replying anyway is common courtesy
							sFlagsOut.answer = 1;
							sFlagsOut.eom = 1;
							sFlagsOut.msgnr = 0;
							sFlagsOut.type = 6;
							
							%format for shared memory
							sOut.flags = MFCP_setFlags(sFlagsOut);
							sOut.target = sMsg.source;
							sOut.source = intID;
							sOut.msg = sMsg.msg;
							sOut.xem = sMsg.xem;
							sOut.data = zeros(1,32,'uint8');
							
							% write to shared memory
							intMsgPut = find(vecOpen,1,'first');
							vecOpen(intMsgPut) = 0;
							MFCP_setMsg(sOut,msmf_IO,intMsgPut);
							
						elseif sFlags.type == 2 %structvals
							%THIS IS A RETURN TYPE TO SLAVE
						elseif sFlags.type == 3 %data in file
							%THIS IS A RETURN TYPE TO SLAVE
						elseif sFlags.type == 4 %unused
							%Empty
						elseif sFlags.type == 5 %exit
							boolRunning = false;
						elseif sFlags.type == 6 %return ok
							%THIS IS A RETURN TYPE TO SLAVE
						elseif sFlags.type == 7 %error
							%THIS IS A RETURN TYPE TO SLAVE
						end
					end
				end
			end
		end
		
		%% Close connections to FPGAs
		for intCard = 1:length(sConnectFPGA)
			objCard = sOC(intCard).objCard;
			verbose = sConnectFPGA(intCard).verbose;
			CloseFPGA(objCard,verbose);
		end
	catch
		%% Close connections to FPGAs
		for intCard = 1:length(sConnectFPGA)
			objCard = sOC(intCard).objCard;
			verbose = sConnectFPGA(intCard).verbose;
			CloseFPGA(objCard,verbose);
		end
		rethrow(lasterror)
	end
end
function arData = formatStructValsToData(structVals)
	arData = zeros(1,32,'uint8');
	
	%SENSOR0
	vec8 = typecast(uint16(structVals.SENSOR0), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(1) = vec8(1);
	arData(2) = vec8(2);
	
	%SENSOR1
	vec8 = typecast(uint16(structVals.SENSOR1), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(3) = vec8(1);
	arData(4) = vec8(2);
	
	%ACTUATOR0
	vec8 = typecast(uint16(structVals.ACTUATOR0), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(5) = vec8(1);
	arData(6) = vec8(2);
	
	%ACTUATOR1
	vec8 = typecast(uint16(structVals.ACTUATOR1), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(7) = vec8(1);
	arData(8) = vec8(2);
	
	%ACTUATOR2
	vec8 = typecast(uint16(structVals.ACTUATOR2), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(9) = vec8(1);
	arData(10) = vec8(2);
	
	%KLOK0
	vec8 = typecast(uint16(structVals.KLOK0), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(11) = vec8(1);
	arData(12) = vec8(2);
	
	%KLOK1
	vec8 = typecast(uint16(structVals.KLOK1), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(13) = vec8(1);
	arData(14) = vec8(2);
	
	%FIRSTUP0
	vec8 = typecast(uint16(structVals.FIRSTUP0), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(15) = vec8(1);
	arData(16) = vec8(2);
	
	%FIRSTUP1
	vec8 = typecast(uint16(structVals.FIRSTUP1), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(17) = vec8(1);
	arData(18) = vec8(2);
	
	%FIRSTDOWN0
	vec8 = typecast(uint16(structVals.FIRSTDOWN0), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(19) = vec8(1);
	arData(20) = vec8(2);
	
	%FIRSTDOWN1
	vec8 = typecast(uint16(structVals.FIRSTDOWN1), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(21) = vec8(1);
	arData(22) = vec8(2);
	
	%LASTDOWN0
	vec8 = typecast(uint16(structVals.LASTDOWN0), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(23) = vec8(1);
	arData(24) = vec8(2);
	
	%LASTDOWN1
	vec8 = typecast(uint16(structVals.LASTDOWN1), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(25) = vec8(1);
	arData(26) = vec8(2);
	
	%COUNTER
	vec8 = typecast(uint16(structVals.COUNTER), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(27) = vec8(1);
	arData(28) = vec8(2);
	
	%QUADRATURE
	vec8 = typecast(uint16(structVals.QUADRATURE), 'uint8'); %low8=vec8(1);high8 = vec8(2)
	arData(29) = vec8(1);
	arData(30) = vec8(2);
	
	%Empty
	arData(31) = 0;
	arData(32) = 0;
end
function [objCardOut,structValsOut,sPortDefOut] = getCardByXEM(sOC,XEM)
	%get card variables by XEM
	for intObjCard = 1:length(sOC)
		if strcmp(sOC(intObjCard).objCard.xem,XEM)
			objCardOut = sOC(intObjCard).objCard;
			structValsOut = sOC(intObjCard).structVals;
			sPortDefOut = sOC(intObjCard).sPortDef;
		end
	end
end
function strPath = getPath()
	%get path of this file
	strFullName = mfilename('fullpath');
	
	%find path name
	vecFindSep = strfind(strFullName,filesep);
	strPath = strFullName(1:vecFindSep(end));
end
function genIO(strFile,intProcesses,intMessages)
	%set required size
	intMsgLength = 52;
	intByteSizeIO =  intProcesses * intMessages * intMsgLength;
	
	%generate IO file
	[ptrFile, msg] = fopen(strFile, 'w');
	if ptrFile ~= -1
		fwrite(ptrFile, zeros(1,intByteSizeIO,'uint8'), 'uint8');
		fclose(ptrFile);
	else
		error([mfilename ':genIO:cannotOpenFile'],'Cannot open file "%s": %s.',strFile, msg);
	end
end
function genCon(strFile,intProcesses)
	%set required size
	intIDsize = 4;
	intByteSizeCon = intProcesses * intIDsize;
	
	% generate connections file
	[ptrFile, msg] = fopen(strFile, 'w');
	if ptrFile ~= -1
		fwrite(ptrFile, zeros(1,intByteSizeCon,'uint8'), 'uint8');
		fclose(ptrFile);
	else
		error([mfilename ':genIO:cannotOpenFile'],'Cannot open file "%s": %s.',strFile, msg);
	end
end
function intID = genID()
	%generate random ID
	rng('shuffle');
	intID = randi(intmax('uint32'),'uint32');
end