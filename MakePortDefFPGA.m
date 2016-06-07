%MakePortDefFPGA  This function creates a .pdm file to supply the port
%definitions of the FPGA. This function's output is the sPortDef structure
%saved to the filename you supply as input. Syntax:
%
%		sPortDef = MakePortDefFPGA(strPortDefFile)
%
%	You can edit the sPortDef structure in the code below.
%	
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB
% 2012-09-10	Created.

function sPortDef = MakePortDefFPGA(strPortDefFile)
	if ~exist('strPortDefFile','var')
		strPortDefFile = 'portdefinitions_cageL.pdm';
	end
	
	%% do not change
	sPortDef = struct;
	
	%% you can change the values below to correspond to the addresses of your FPGA
	sPortDef.ADRES_SERVO_L = 32;
	sPortDef.ADRES_SERVO_R = 32;
	sPortDef.REWARDPOS_SERVO_L = 105000;
	sPortDef.REWARDPOS_SERVO_R = 105000;
	sPortDef.BASEPOS_SERVO_L = 98000;
	sPortDef.BASEPOS_SERVO_R = 98000;
	sPortDef.ADRES_LED = 1;
	sPortDef.ADRES_POMP = 33;
	sPortDef.ADRES_LOOPBAND = [2 3];
	sPortDef.ADRES_LEVERRIGHT = 5;
	sPortDef.ADRES_LEVERLEFT = 7;
	sPortDef.ADRES_FRAMECOUNTER = 1;
	
	%% do not change
	sPortDef.TRIGGER = hex2dec('40'); %trigger mode can be 0-4:
	sPortDef.READ = 0;
	sPortDef.RESET = 1;
	sPortDef.PULSE = 2;
	sPortDef.WRITE = 3;
	sPortDef.SERVO = 4;
	sPortDef.PWM = 9;
	sPortDef.RESETCLOCK = 10;
	
	sPortDef.ADRES_BIT = hex2dec('11');
	sPortDef.VALUE_BIT = hex2dec('12');
	sPortDef.PULSETIME0 = hex2dec('13');
	sPortDef.PULSETIME1 = hex2dec('14');
	
	sPortDef.ADRES_SENSOREN0 = hex2dec('26');
	sPortDef.ADRES_SENSOREN1 = hex2dec('27');
	sPortDef.ADRES_ACTUATOREN0 = hex2dec('28');
	sPortDef.ADRES_ACTUATOREN1 = hex2dec('29');
	sPortDef.ADRES_ACTUATOREN2 = hex2dec('39');
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
	
	
	
	save(strPortDefFile,'sPortDef')
end

