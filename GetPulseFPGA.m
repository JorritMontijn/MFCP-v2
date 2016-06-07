%GetPulseFPGA  This function changes the FPGA's servo position
%	Use the following command:
%
%		[intElapsedTime,structVals] = GetPulseFPGA(objCard,sPortDef,intBit,structVals[,boolReset])
%
%	to get the elapsed time since the pulse on intBit was started.
%
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB

function [intElapsedTime,structVals] = GetPulseFPGA(objCard,sPortDef,intBit,structVals,boolReset)
	%define reset
	if ~exist('boolReset','var') || isempty(boolReset)
		boolReset = false;
	end
	
	%send command to FPGA
	structVals = ReadFPGA(objCard,intBit,boolReset,structVals,sPortDef);
	
	%calculate elapsed time
	intElapsedTime = short2long(structVals.FIRSTDOWN1,structVals.FIRSTDOWN0) - short2long(structVals.FIRSTUP1,structVals.FIRSTUP0);
end