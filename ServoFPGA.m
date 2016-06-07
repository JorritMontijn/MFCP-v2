%ServoFPGA  This function changes the FPGA's servo position
%	Use the following command:
%
%		ServoFPGA(objCard,sPortDef,intPos)
%
%	to set the servo connected to the field-programmable gate array. The
%	inputs objCard and sPortDef are obtained with InitFPGA(); intPos gives
%	the requested position of the servo
%
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB

function ServoFPGA(objCard,sPortDef,intPos)
	
	%transform to compatible values -> maybe make it into degrees (0-90)
	if (intPos > 1000), intPos = 1000; end;
	intServoPos = (round(intPos) + 1000) * 100;
	
	%0  degrees (horz) =  98000
	%90 degrees (vert) = 200000
	
	%send command to FPGA
	SetFPGA(objCard,sPortDef.ADRES_SERVO,1,intServoPos,sPortDef.SERVO,sPortDef)
end

