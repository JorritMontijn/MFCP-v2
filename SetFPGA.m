%SetFPGA  This function is the interface from MATLAB to the FPGA
%	First initalize the FPGA by using the following command:
% 
%		[objCard,sPortDef,structVals] = InitFPGA(strBitFile,verbose,boolForce)
% 
%	Then you can use:
% 
%		SetFPGA(objCard,intBitNumber,intValue,intPulse,intTriggerMode,sPortDef)
% 
%	to set the field-programmable gate array.
% 
% 
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB
% 2012-07-26	Updated to support FrontPanel 4.0.8

function SetFPGA(objCard,intBitNumber,intValue,intPulse,intTriggerMode,sPortDef)
	if ~isempty(objCard)
		
		%transform 32bit input to 2 times 16bit input
		[intPulse16HiVal,intPulse16LoVal] = long2short(intPulse);
		
		%set values
		if intBitNumber > 0
			calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', objCard.xPointer, sPortDef.ADRES_BIT, intBitNumber, hex2dec('FFFF'));
			calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', objCard.xPointer, sPortDef.VALUE_BIT, intValue, hex2dec('FFFF'));
			calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', objCard.xPointer, sPortDef.PULSETIME0, intPulse16LoVal, hex2dec('FFFF'));
			calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', objCard.xPointer, sPortDef.PULSETIME1, intPulse16HiVal, hex2dec('FFFF'));
		end
		
		%update
		calllib('okFrontPanel', 'okFrontPanel_UpdateWireIns', objCard.xPointer);
		
		%activate trigger in
		success = calllib('okFrontPanel', 'okFrontPanel_ActivateTriggerIn', objCard.xPointer, sPortDef.TRIGGER, intTriggerMode);
		if success == 0
			error('SetFPGA:FailActivateTriggerIn','Write fail; ActivateTriggerIn error');
		end
	end
end