%ReadFPGA  This function is the interface from the FPGA to MATLAB
%	First initalize the FPGA by using the following command:
% 
%		[objCard,sPortDef,structVals] = InitFPGA(strBitFile,verbose,boolForce)
% 
%	Then you can use:
% 
%		structVals=ReadFPGA(objCard,intBitNumber,boolReset,structVals,sPortDef) 
% 
%	to read data from the field-programmable gate array. intBitNumber
%	supplies the target bit number; boolReset can be true/false, if true
%	the bit is reset, otherwise it is only read; structVals contains a
%	pre-allocated structure containing the fields returned by InitFPGA;
%	sPortDef is a structure with definitions. The output is a structure
%	structVals containing the current values of the FPGA.
% 
% 
% History:
%
% 2011-12-20	FPGA Interface functions created by Jorrit S. Montijn,
%				based on code by Gerrit Hardeman, adapted for MATLAB
% 2012-07-26	Updated to support FrontPanel 4.0.8

function structVals=ReadFPGA(objCard,intBitNumber,boolReset,structVals,sPortDef)
	if ~isempty(objCard)
		%if bit == -1, skip this part; 
		%however, this part is necessary for setting the bit of which you
		%want to read the pulse width or counter
		if intBitNumber ~= -1
			calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', objCard.xPointer, sPortDef.ADRES_BIT, intBitNumber, hex2dec('FFFF'));
			calllib('okFrontPanel', 'okFrontPanel_UpdateWireIns', objCard.xPointer);
		end
		
		%activate trigger in; for resetting the values of the specified bit
		success = calllib('okFrontPanel', 'okFrontPanel_ActivateTriggerIn', objCard.xPointer, sPortDef.TRIGGER, boolReset);
		if success == 0
			error('ReadFPGA:FailActivateTriggerIn','Read fail; ActivateTriggerIn error');
		end
		
		%update output wires
		calllib('okFrontPanel', 'okFrontPanel_UpdateWireOuts', objCard.xPointer);
		
		%get output wire values
		structVals.SENSOR0 = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', objCard.xPointer,sPortDef.ADRES_SENSOREN0);
		structVals.SENSOR1 = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', objCard.xPointer,sPortDef.ADRES_SENSOREN1);
		structVals.ACTUATOR0 = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', objCard.xPointer,sPortDef.ADRES_ACTUATOREN0);   
		structVals.ACTUATOR1 = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', objCard.xPointer,sPortDef.ADRES_ACTUATOREN1);
		structVals.ACTUATOR2 = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', objCard.xPointer,sPortDef.ADRES_ACTUATOREN2);   
	
		structVals.KLOK0 = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', objCard.xPointer,sPortDef.ADRES_KLOK0);   
		structVals.KLOK1 = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', objCard.xPointer,sPortDef.ADRES_KLOK1);   
		structVals.FIRSTUP0 = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', objCard.xPointer,sPortDef.ADRES_FIRSTUP0);   
		structVals.FIRSTUP1 = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', objCard.xPointer,sPortDef.ADRES_FIRSTUP1);   
		structVals.FIRSTDOWN0 = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', objCard.xPointer,sPortDef.ADRES_FIRSTDOWN0);   
		structVals.FIRSTDOWN1 = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', objCard.xPointer,sPortDef.ADRES_FIRSTDOWN1);   
		structVals.LASTDOWN0 = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', objCard.xPointer,sPortDef.ADRES_LASTDOWN0);   
		structVals.LASTDOWN1 = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', objCard.xPointer,sPortDef.ADRES_LASTDOWN1);   
		structVals.COUNTER = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', objCard.xPointer,sPortDef.ADRES_COUNTER);
		structVals.QUADRATURE = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', objCard.xPointer,sPortDef.ADRES_QUADRATURE);
	end
end