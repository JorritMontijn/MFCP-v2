function sMS = MFCP_InitSlave()
	%MFCP_InitSlave Use this function to initialize a slave process.
	%   Returns sMS; a structure containing all data required for MFCP
	%   slave processes. After initializing, you can use the following
	%   functions to interact with any FPGA connected to the master:
	%
	%	- structVals = MFCP_ReadFPGA(sMS,xem,intBitNr,boolReset);
	%	- MFCP_SetFPGA(sMS,xem,intBitNr,intValue,intPulse,intTriggerMode);
	%	- msgID = MFCP_queryReadFPGA(sMS,xem,intBitNr,boolReset);
	%	- structVals = MFCP_getReadFPGA(sMS,msgID);
	%
	%	Here, sMS is the structure returned by this function and xem is the
	%	serial number of the target FPGA. For all other arguments, please
	%	refer to either ReadFPGA() or to SetFPGA(). In order to speed up
	%	communication, you can use the twin functions MFCP_queryReadFPGA
	%	and MFCP_getReadFPGA to asynchronously retrieve data.
	%
	%	N.B.: after you've finished your experiment, you must use
	%	MFCP_CloseSlave() to empty up connections for other slave
	%	processes. If you get an error that all slave process spots are
	%	taken, try restarting the MFCP Master.
	%
	% History:
	%
	% 2012-10-04	Matlab FPGA Control Protocol functions created by
	%				Jorrit S. Montijn for use with the FPGA Interface
	% 2014-01-20	Made some small changes to accomodate MFCPv2 for Audio
	%				Warden addition (limited slave positions) [by JM]
	
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
	
	%log on to connection file by writing ID to a slave place
	[intNr,intID] = connectToMaster(msmf_Con);
	
	%make IO into shared mem file
	msmf_IO = memmapfile(strIO,'Writable', true);
	
	sMS = struct; %structure MFCP Slave
	sMS.msmf_Con = msmf_Con;
	sMS.msmf_IO = msmf_IO;
	sMS.intID = intID;
	sMS.intNr = intNr;
	
	%% end msg
	fprintf('\n\n\nMatlab FPGA Control Protocol  Slave initiated.\n\nYou can now use MFCP_ReadFPGA() and MFCP_SetFPGA(). \nDon''t forget to close the connection with MFCP_CloseSlave() when you''re done!\n')
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
function [intFoundSpot,intID] = connectToMaster(msmf_Con)
	%find empty spot
	intFoundSpot = 0;
	boolRunning = true;
	intID = genID();
	intFirstSlaveSpot = 9;
	while boolRunning
		boolUnique = true; %default is unique
		boolFound = false; %default is no space
		for intNr=1:length(msmf_Con.Data) %loop all spots
			if msmf_Con.Data(intNr).processID == 0 && ~boolFound && intNr >= intFirstSlaveSpot  %found spot
				boolFound = true;
				intFoundSpot = intNr;
			end
			if msmf_Con.Data(intNr).processID == intID %ID is not unique
				boolUnique = false;
			end
		end
		if ~boolFound %error if no spot found
			error([mfilename ':connectToMaster:NoEmptySpots'],'All slave process spots are already filled!');
		end
		if boolUnique %if unique, then spot was found and we can stop
			boolRunning = false;
		else %not unique; create new ID and check again
			intID = genID();
		end
	end

	%assign ID to spot
	msmf_Con.Data(intFoundSpot).processID = intID;
end