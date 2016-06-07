%InitFPGA  This function initializes an FPGA for use in MATLAB
%	Use the following command:
%
%		[objCard,sPortDef,structVals] = InitFPGA(strBitFile,verbose,strSerial,strPortDefFile)
%
%	to initialize the field-programmable gate array. The input strBitFile
%	contains the path and filename of the bit-file with which you want to
%	configure the FPGA; verbose defines the amount of output messages
%	(1=much, 0=little); strSerial defines the serial number of the FPGA you
%	want to make the connection to. If none is supplied, the connection
%	will be established to the first FPGA the program encounters. The
%	outputs are:
% 
%	- objCard: the FPGA object
%	- sPortDef: a structure containing bit definitions
%	- structVals: the initial values of the FPGA
%
%
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB
% 2012-07-26	Added support for FrontPanel 4.0.8; EEPROM-configuration;
%				and multiple simultaneous connections to different FPGAs

% Note: the only functions you really need are InitFPGA() to initalize a
% connection; SetFPGA() to send commands to the FPGA; ReadFPGA() to get
% information from the FPGA; and CloseFPGA() to close down connections. The
% functions also depend on long2short() and short2long(), but all other
% functions in this toolbox are simply wrappers to provide easier use

function [objCard,sPortDef,structVals] = InitFPGA(strBitFile,verbose,strSerial,strPortDefFile)
	%define verbosity
	if ~exist('verbose','var') || isempty(verbose)
		verbose = true;
	end
	%define serial
	if ~exist('strSerial','var') || ~ischar(strSerial)
		strSerial = '';
	end
	%define port definition file
	if ~exist('strPortDefFile','var') || ~ischar(strPortDefFile)
		strPortDefFile = '';
	end
	
	%define global
	global OpalKellyInit
	
	%starting message
	if verbose(1), fprintf('Initializing Opal Kelly Matlab Interface...\n'), end;
	if ~isempty(strSerial)
		if verbose(1), fprintf('You requested a connection to the FPGA with serial number [%s]\n',strSerial), end;
	else
		if verbose(1), fprintf('You did not supply a serial number: will open connection to first FPGA that is found\n'), end;
	end
	
	%check if a .bit file was supplied
	if ~exist('strBitFile','var') || isempty(strBitFile)
		boolDoConfigure = false;
		if verbose(1), fprintf('No .bit file was supplied; assuming target FPGA is XEM6001 series with configuration on EEPROM\n'), end;
	else
		boolDoConfigure = true;
		if ~exist(strBitFile,'file')
			error('InitFPGA:NoBitFile','supplied .bit filename [%s] was not found anywhere',strBitFile);
		else
			strFullName = which(strBitFile);
			vecFindSep = strfind(strFullName,filesep);
			strFilePath = strFullName(1:vecFindSep(end));
			if ~strcmp([pwd filesep],strFilePath)
				if verbose(1), fprintf('Will append path to bit-file: supplied .bit filename [%s] was found in [%s]\n',strBitFile,strFilePath), end;
				strBitFile = [strFilePath strBitFile];
			end
		end
	end
	
	%load libraries
	if ~libisloaded('okFrontPanel')
		if verbose(1), fprintf('Loading libraries [okFrontPanel.dll] [okFrontPanelDLL.h]...\n'), end;
		loadlibrary('okFrontPanel', 'okFrontPanelDLL.h');
	elseif isempty(OpalKellyInit) || OpalKellyInit < 1
		warning('InitFPGA:LibraryAlreadyLoaded','Libraries already loaded, but no connections are active...\n');
	end
	
	%load structure with bit definitions
	if verbose(1), fprintf('Loading port locations...\n'), end;
	[sPortDef,strPortDefFile] = DefinePortsFPGA(strPortDefFile);
	if verbose(1), fprintf('\b\tDone! File [%s] loaded\n',strPortDefFile), end
	
	%create object
	objCard.xPointer = calllib('okFrontPanel', 'okFrontPanel_Construct');
	try
		%check if only one is connected
		if verbose(1), fprintf('Checking for devices...\n'), end;
		intNumDevices = calllib('okFrontPanel', 'okFrontPanel_GetDeviceCount', objCard.xPointer);
		if intNumDevices == 0
			error([mfilename ':NoDevices'],'No devices detected; if it is connected, try restarting the FPGA');
		elseif intNumDevices > 1
			if verbose(1), fprintf('\b\tMultiple devices connected [%d]\n',intNumDevices), end
		else
			if verbose(1), fprintf('\b\tThere is one device connected\n'), end
		end

		
		%generate device model list
		intReqIndex = 0;
		for intDevice=1:intNumDevices
			objCard.modelList{intDevice} = calllib('okFrontPanel', 'okFrontPanel_GetDeviceListModel', objCard.xPointer, intDevice-1);
			objCard.serialList{intDevice} = calllib('okFrontPanel', 'okFrontPanel_GetDeviceListSerial', objCard.xPointer, intDevice-1,'                         ');
			if verbose(1), fprintf('Device %d:\n      model: %s\n      serial: %s\n',intDevice,objCard.modelList{intDevice},objCard.serialList{intDevice}), end;
			if strcmp(objCard.serialList{intDevice},strSerial) %requested serial found
				intReqIndex = intDevice;
				if verbose(1), fprintf('\b [Connection requested]\n'), end;
			end
		end
		
		%check requested device
		if isempty(strSerial)
			%no specific FPGA requested; opening first in list
			objCard.xem = objCard.serialList{1};
			objCard.model = objCard.modelList{1};
			if verbose(1), fprintf('Opening connection to FPGA first on list. Serial number: [%s]\n',objCard.xem), end;
		else
			%specific FPGA requested; check if present
			if intReqIndex == 0
				error([mfilename ':SerialNotFound'],'No FPGA with serial number [%s] found...\n',strSerial)
			else
				objCard.xem = objCard.serialList{intReqIndex};
				objCard.model = objCard.modelList{intReqIndex};
				if verbose(1), fprintf('Opening connection to FPGA with device number %d. Serial number: [%s]\n',intReqIndex,objCard.xem), end;
			end
		end
		
		%open connection
        boolOpen = calllib('okFrontPanel', 'okFrontPanel_IsOpen', objCard.xPointer);
		if boolOpen
			if verbose(1), fprintf('The connection on pointer %d is already open.\n',objCard.xPointer), end;
		else
			if verbose(1), fprintf('Attempting to open the FPGA...\n'), end
			resultOfAttemptingToOpenFpga = calllib('okFrontPanel', 'okFrontPanel_OpenBySerial',objCard.xPointer, objCard.xem);
			if verbose(1) && ~isempty(resultOfAttemptingToOpenFpga), fprintf('\b\tSuccess!\n'), end;
			
			%increase connection number
			if ~isempty(OpalKellyInit)
				OpalKellyInit = OpalKellyInit + 1;
			else
				OpalKellyInit = 1;
			end
			if verbose(1), fprintf('Number of connections now open: [%d]\n',OpalKellyInit), end
		end
		
		%get some info
		[objCard.major] = calllib('okFrontPanel', 'okFrontPanel_GetDeviceMajorVersion', objCard.xPointer);
		[objCard.minor] = calllib('okFrontPanel', 'okFrontPanel_GetDeviceMinorVersion', objCard.xPointer);
		[objCard.deviceID] = calllib('okFrontPanel', 'okFrontPanel_GetDeviceID', objCard.xPointer, '                                 ');
		if verbose(1)
			fprintf(['Device ID: ' objCard.deviceID '\n'])
			fprintf(['Version: ' num2str(objCard.major) '.' num2str(objCard.minor) '\n'])
		end

		if boolDoConfigure
			%configure FPGA
			resultOfAttemptingToConfigureFpga = calllib('okFrontPanel', 'okFrontPanel_ConfigureFPGA', objCard.xPointer, strBitFile);
			if strcmp(resultOfAttemptingToConfigureFpga,'ok_NoError')
				if verbose(1), fprintf(['Configuring the FPGA: ' resultOfAttemptingToConfigureFpga '\n']), end;
			else
				warning([mfilename ':FailConfig'],['Configuration failed, message was: ' resultOfAttemptingToConfigureFpga '\n'])
			end
		else
			if strcmp(objCard.model,'ok_brdXEM6001')
				if verbose(1), fprintf('Configuration is unnecessary: Your FPGA is an XEM6001 series\n'), end;
			else
				warning([mfilename ':NoBitFile'],'Your FPGA is _NOT_ an XEM6001 series; but you have not supplied a .bit file; configuration may still be necessary');
			end
		end
		
		%attempt write
		intBitNumber = 40;
		intValue = 500;
		intPulse = 500;
		intTriggerMode = 1;
		if verbose(1), fprintf('Attempting write...\n'), end;
		SetFPGA(objCard,intBitNumber,intValue,intPulse,intTriggerMode,sPortDef);
		if verbose(1), fprintf('\b\tWrite succeeded!\n'), end;
		
		
		%attempt read
		intBitNumber = 1;
		intReadOrReset = 1;
		structVals = struct;
		if verbose(1), fprintf('Attempting read...\n'), end;
		structVals=ReadFPGA(objCard,intBitNumber,intReadOrReset,structVals,sPortDef);
		if isempty(structVals) || isempty(structVals.COUNTER)
			warning('InitFPGA:FailRead','Read failed, structVals was empty')
		elseif verbose(1)
			fprintf('\b\tRead succeeded!\n');
		end
		
		%initialization complete!
		fprintf('Opal Kelly Matlab Interface Initialization complete.\n')
		if verbose(1), fprintf('Don''t forget to close the connection when you''re done!\n'), end;
	catch
		%when there is an error, try to destruct the handle
		calllib('okFrontPanel', 'okFrontPanel_Destruct',objCard.xPointer);
		rethrow(lasterror)
	end
end

%{

%% obsolete as of 2012-09-10 %%

function sPortDef = DefinePorts()
	%this function creates a structure containing the bit definitions and
	%adresses of the FPGA
	
	sPortDef = struct;
	sPortDef.ADRES_SERVO = 32;
	sPortDef.ADRES_LED = 1;
	sPortDef.ADRES_SENSOREN0 = hex2dec('26');
	sPortDef.ADRES_SENSOREN1 = hex2dec('27');
	sPortDef.ADRES_ACTUATOREN0 = hex2dec('28');
	sPortDef.ADRES_ACTUATOREN1 = hex2dec('29');
	sPortDef.ADRES_ACTUATOREN2 = hex2dec('39');
	sPortDef.ADRES_POMP = 33;
	sPortDef.ADRES_LOOPBAND = [2 3];
	sPortDef.ADRES_PEDAALRECHTS = 5;
	sPortDef.ADRES_PEDAALLINKS = 7;
	sPortDef.ADRES_FRAMECOUNTER = 1;
	
	
	sPortDef.TRIGGER = hex2dec('40'); %trigger mode can be 0-4:
	sPortDef.READ = 0;
	sPortDef.RESET = 1;
	sPortDef.PULSE = 2;
	sPortDef.WRITE = 3;
	sPortDef.SERVO = 4;
	sPortDef.PWM = 9;
	
	sPortDef.ADRES_BIT = hex2dec('11');
	sPortDef.VALUE_BIT = hex2dec('12');
	sPortDef.PULSETIME0 = hex2dec('13');
	sPortDef.PULSETIME1 = hex2dec('14');
	
	sPortDef.ADRES_KLOK0 = hex2dec('30');
	sPortDef.ADRES_KLOK1 = hex2dec('31');
	sPortDef.ADRES_FIRSTUP0 = hex2dec('32');
	sPortDef.ADRES_FIRSTUP1 = hex2dec('33');
	sPortDef.ADRES_FIRSTDOWN0 = hex2dec('34');
	sPortDef.ADRES_FIRSTDOWN1 = hex2dec('35');
	sPortDef.ADRES_LASTDOWN0 = hex2dec('36');
	sPortDef.ADRES_LASTDOWN1 = hex2dec('37');
	sPortDef.ADRES_COUNTER = hex2dec('38');
	sPortDef.ADRES_QUADRATURE = hex2dec('3A');
	
	sPortDef.SENSOR0 = 0;
	sPortDef.SENSOR1 = 1;
	sPortDef.ACTUATOR0 = 2;
	sPortDef.ACTUATOR1 = 3;
	sPortDef.ACTUATOR2 = 4;
	sPortDef.KLOK0 = 5;
	sPortDef.KLOK1 = 6;
	sPortDef.FIRSTUP0 = 7;
	sPortDef.FIRSTUP1 = 8;
	sPortDef.FIRSTDOWN0 = 9;
	sPortDef.FIRSTDOWN1 = 10;
	sPortDef.LASTDOWN0 = 11;
	sPortDef.LASTDOWN1 = 12;
	sPortDef.COUNTER = 13;
	sPortDef.QUADRATURE = 14;
	
	sPortDef.MAX_FPGA_VALUES = 14;
	sPortDef.MAX_OK_CARDS = 4;
end
%}