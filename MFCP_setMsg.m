function MFCP_setMsg(sMsg,msmf_IO,intMsg)
	%MFCP_setMsg Puts a message (sMsg) into shared mem at location intMsg
	%   MFCP_setMsg(sMsg,msmf_IO,intMsg)
	%
	% History:
	%
	% 2012-10-04	Matlab FPGA Control Protocol functions created by
	%				Jorrit S. Montijn for use with the FPGA Interface
	
	%define variables
	intMsgLength = 52;
	
	%get location of target message
	intStart = (intMsgLength * (intMsg - 1)) + 1;
	intStop = intStart + intMsgLength - 1;
	
	%pre-allocate aaray
	arThisMsg = zeros(1,52,'uint8');

	%assign values into array
	arThisMsg(1) = sMsg.flags;
	arThisMsg(2:5) = typecast(uint32(sMsg.target), 'uint8');
	arThisMsg(6:9) = typecast(uint32(sMsg.source), 'uint8');
	arThisMsg(10) = sMsg.msg;
	arThisMsg(11:20) = sMsg.xem;
	arThisMsg(21:52) = sMsg.data;
	
	%set msg
	msmf_IO.Data(intStart:intStop) = arThisMsg;
end

