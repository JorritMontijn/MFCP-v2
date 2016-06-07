%PWMFPGA  This function sends a pulse-width modulated signal to the FPGA,
% for instance to change the intensity of an LED
%	Use the following command:
%
%		PWMFPGA(objCard,sPortDef,intPulseWidth)
%
%	to set the servo connected to the field-programmable gate array. The
%	inputs objCard and sPortDef are obtained with InitFPGA(); intPos gives
%	the requested position of the servo
%
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB

function PWMFPGA(objCard,sPortDef,intPulseWidth)
	
	%transform to compatible values -> maybe make it into degrees (0-90)
	if (intPulseWidth > 1000), intPulseWidth = 1000; end;
	intPulseWidth = (round(intPulseWidth) + 1000) * 100;
	
	%send command to FPGA
	SetFPGA(objCard,sPortDef.ADRES_LED,1,intPulseWidth,sPortDef.PWM,sPortDef)
end

