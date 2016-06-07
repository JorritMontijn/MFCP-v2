%CloseFPGA  This function closes the FPGA connection
%	Use the following command:
%
%		CloseFPGA(objCard,verbose)
%
%	to close the connection to the field-programmable gate array. The input
%	objCard is obtained with InitFPGA(); verbose defines the amount of
%	output messages (1=much, 0=little)
%
%
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB
% 2012-07-26	Updated to support FrontPanel 4.0.8; and for multiple
%				simultaneous connections to different FPGAs

function CloseFPGA(objCard,verbose)
	%define verbosity
	if ~exist('verbose','var') || isempty(verbose)
		verbose = true;
	end
	%define global
	global OpalKellyInit
	
	%unload libraries
	if libisloaded('okFrontPanel')
		%close connection
		boolOpen = calllib('okFrontPanel', 'okFrontPanel_IsOpen', objCard.xPointer);
		strSerial = objCard.xem;
		if boolOpen
			%close and decrease connection number
			if verbose(1), fprintf('Closing connection to FPGA with serial [%s]\n',strSerial), end;
			calllib('okFrontPanel', 'okFrontPanel_Destruct',objCard.xPointer);
			OpalKellyInit = OpalKellyInit - 1;
			if verbose(1), fprintf('Connection successfully closed!\n'), end;
		else
			%error: is not open
			error([mfilename ':ConnectionClosed'],'Connection to FPGA with serial number [%s] was already closed',strSerial);
		end
		if OpalKellyInit < 1
			[user1 system1] = memory;
			if verbose(1), fprintf('No open connections remaining: closing Opal Kelly Matlab Interface...\n'), end;
			unloadlibrary('okFrontPanel');
			[user2 system2] = memory;
			diffMem = user1.MemUsedMATLAB - user2.MemUsedMATLAB;
			intNumberOfKBs = round(diffMem/1000);
			if verbose(1), fprintf('Opal Kelly Matlab Interface Library successfully unloaded. Freed up %.3f MB of RAM\n',intNumberOfKBs/1000), end;
		end
	else
		error('CloseFPGA:NoLibraryLoaded','Libraries were not loaded; there can be no active connections');
	end
end