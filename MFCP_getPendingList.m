function vecPending = MFCP_getPendingList(arrayIO,boolAnswer)
	%MFCP_getPendingList Retrieves list of pending messages
	%	vecPending = MFCP_getPendingList(arrayIO,boolAnswer)
	%
	% History:
	%
	% 2012-10-04	Matlab FPGA Control Protocol functions created by
	%				Jorrit S. Montijn for use with the FPGA Interface
	
	%define variables
	intMsgLength = 52;
	intPending = 128;
	intAnswer = 64;
	
	%get flag bytes
	vecStarts = arrayIO(1:intMsgLength:end);
	
	%get pending list from values in flag bytes
	if boolAnswer
		vecPending = vecStarts >= (intPending+intAnswer);
	else
		vecPending = vecStarts >= (intPending) & vecStarts < (intPending + intAnswer);
	end
end

