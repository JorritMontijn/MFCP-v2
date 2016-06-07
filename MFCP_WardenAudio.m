function MFCP_WardenAudio()
	%MFCP_WardenAudio This function handles all audio requests by slaves
	%You can use MFCP_SetAudio(sMS,dblTime,varAudio) in your slave sessions
	%once the Audio Warden is running. MFCP_AudioWarden will then relay the
	%request to MFCP_PlayAudio with the specified time and other variables.
	%
	%	N.B.: you should start MFCP_WardenAudio() after you've started the
	%	MFCP_Master and before running your slave sessions. Also, please be
	%	aware that there is a ~10ms latency between sending at SetAudio and
	%	receiving at PlayAudio. Moreover, the time specification has a
	%	resolution of only 1ms, so high-precision timing is unfortunately
	%	not possible until MATLAB increases now()'s precision
	%
	% History:
	%
	% 2014-01-20	Created WardenAudio function as addition to the 
	%				Matlab FPGA Control Protocol functions
	
	%% prepare shared memory access
	%get path
	strPath = getPath();
	
	%get filenames
	strIO = [strPath 'IO.msmf'];
	strConnections = [strPath 'connections.msmf'];
	
	%make connection to shared mem file
	msmf_Con = memmapfile(strConnections,...
		'Writable', true,...
		'Format', {                    ...
		'uint32'  [1] 'processID'});
	
	%make IO into shared mem file
	msmf_IO = memmapfile(strIO,'Writable', true);
	
	%check if warden spot is empty
	intAudioWardenSpot = 2;
	if msmf_Con.Data(intAudioWardenSpot).processID ~= 0
		warning([mfilename ':SpotTaken'],'Another process is already connected at the Audio Warden location [ID=%d]',msmf_Con.Data(intAudioWardenSpot).processID);
		msmf_Con.Data(intAudioWardenSpot).processID = zeros(1,1,'uint32');
	end
	
	%check if ID is unique
	boolRunning = true;
	intID = genID();
	while boolRunning
		boolUnique = true; %default is unique
		for intNr=1:length(msmf_Con.Data) %loop all spots
			if msmf_Con.Data(intNr).processID == intID %ID is not unique
				boolUnique = false;
			end
		end
		if boolUnique %if unique, then spot was found and we can stop
			boolRunning = false;
		else %not unique; create new ID and check again
			intID = genID();
		end
	end
	
	%assign ID to audio warden spot
	msmf_Con.Data(intAudioWardenSpot).processID = intID;
	
	%% set memory size
	intProcesses = 32; %number
	intMessages = 256; %number
	intMsgLength = 52; %bytes
	
	%% prep loop
	intMsgMax = size(msmf_IO.Data,1) / intMsgLength;
	intMsgsPerProcess = intMsgMax / intProcesses;
	vecPossibleAnswers = zeros(intMsgMax,1);
	vecPossibleAnswers(intAudioWardenSpot:intProcesses:intMsgMax) = 1;
	
	%% enable communication between slaves and audio function
	try
		fprintf('\n\n\nMatlab FPGA Control Protocol  Audio Warden is now running and will take care of all your slaves'' requests\n\n')
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
					if sMsg.target == intID %if target is Audio Warden
						%reset pending flag
						msmf_IO.Data(intStart) = arThisMsg(1)-128;
						
						%get flags
						sFlags = MFCP_getFlags(sMsg.flags);
						if sFlags.type == 0 %readfpga
							
						elseif sFlags.type == 1 %PlayAudio
							%get data location
							arString = typecast(sMsg.data, 'uint8');
							strRand = cast(arString, 'char')';
							strFile = [strRand '.mat'];
							
							%load data
							sLoad = load(strFile);
							dblTime = sLoad.dblTime;
							varAudio = sLoad.varAudio;
							
							%remove file
							strLastState=recycle('off');
							delete(strFile);
							recycle(strLastState);
							
							%execute command
							MFCP_PlayAudio(dblTime,varAudio);
							
							%set flags
							sFlagsOut.pending = 0; %reply does not have to be read by querying slave; but replying anyway is common courtesy
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
						end
					end
				end
			end
		end
	catch
		%rethrow error
		rethrow(lasterror)
	end
end
function strPath = getPath()
	%get path of this file
	strFullName = mfilename('fullpath');
	
	%find path name
	vecFindSep = strfind(strFullName,filesep);
	strPath = strFullName(1:vecFindSep(end));
end
function intID = genID()
	%generate random ID
	rng('shuffle');
	intID = randi(intmax('uint32'),'uint32');
end