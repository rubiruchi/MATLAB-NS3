function resultPacket = WSTCallback(txPacket, senderPosition, ...
    receiverPosition, powerLevel, txGain, rxGain, isNotLegacy, rateMcs, ...
    channelBW, senderVelocity, receiverVelocity, senderId, receiverId, ...
    timeStamp)
% WSTCallback MATLAB callback function for modeling PHY and Channel, on the
% MAC packets given by NS-3. The modeling is done using WLAN Toolbox.
% This function is called while the simulation runs in NS3, on each packet,
% for each receiver. If there are 10 receiving nodes around the
% transmitter, this function will be called 10 times for each transmitted
% packet.
% This callback has to be implemented by user to perform the modeling of
% PHY and Channel, compatible with the configuration given in the scenario.
% The result (modified packet for receiver) and its Rx power in dBm have to
% be returned in the resultPacket output arguemnt.
% The reference implementation is applicable for 802.11a standard.
% Note: Currently this callback does not model interference.
%
% RESULTPACKET = WSTCallback(TXPACKET, SENDERPOSITION, RECEIVERPOSITION, ...
%   POWERLEVEL, TXGAIN, RXGAIN, ISNOTLEGACY,RATEMCS, ...
%   CHANNELBW, SENDERVELOCITY, RECEIVERVELOCITY, SENDERID, RECEIVERID,
%   TIMESTAMP) perfoms the MATLAB PHY and Channel modelling on the given
%   TXPACKET and returns RESULTPACKET which is a vector containing modified
%   packet and rxpowerdBm (received signal strength for receiver in dBm
%   based on distance, channel and other paramters).
%
%   input parameters list:
%   TXPACKET           - Vector of transmitted packet octects.
%   SENDERPOSITION     - Position (x,y,z) vector of the sender as double
%   values.
%   RECEIVERPOSITION   - Position (x,y,z) vector of the receiver as double
%   values.
%   POWERLEVEL         - Transmit power level in dBm as a double value.
%   TXGAIN             - Transmitter gain in Db as a double value.
%   RXGAIN             - Receiver gain in Db as a double value.
%   ISNOTLEGACY        - Flag indicates whether the packet is transmitted
%   with legacy or non-HT PHY (0=legacy, 1=non-HT).
%   RATEMCS            - Rate/Mcs as integer. If ISNOTLEGACY (HT/VHT) is
%   non-zero, contains MCS. Otherwise, contains PHY data rate as a
%   multiple of 500Kbps.
%   CHANNELBW          - Bandwidth of channel in MHz as integer.
%   SENDERVELOCITY     - Vector (x,y,z) of sender velocity in m/sec as
%   double values.
%   RECEIVERVELOCITY   - Vector (x,y,z) of the receiver velocity in m/sec
%   as double values.
%   SENDERID           - Unique node id of sender as given by NS-3 as
%   integer
%   RECEIVERID         - Unique node id of the receiver as given by NS-3
%   as integer
%   TIMESTAMP          - Simulation time (of NS-3) in microseconds as
%   64-bit integer.

%
% Copyright (C) Vamsi.  2017-18 All rights reserved.
%
% This copyrighted material is made available to anyone wishing to use,
% modify, copy, or redistribute it subject to the terms and conditions
% of the GNU General Public License version 2.
%

% If isNotLegacy is non-zero, it is HT / VHT. The rateMcs contains MCS.
% If zero, the mode is non-HT and the rateMcs is a multiple of 500Kbps.
if(isNotLegacy == 0)
    % Value is multiples of 500Kbps. So converting into Mbps speed.
    dataRate = (rateMcs * 500)/1000;
end

%% Encoding
% Convert packet from decimal to binary format
for i=1:length(txPacket)
    packet((i-1)*8+1:i*8) = (de2bi(txPacket(i), 8));
end
% Convert row vector to column vector
packet = packet';
% Non-HT waveform configuration object
genConfig = mlWifiConfig(dataRate);
genConfig.PSDULength = length(packet)/8;
% Send packet to the encoder
txPPDU = mlWifiGenerator(packet, genConfig, txGain);

%% Channel modeling
% Passing signal to channel
[rxPPDU, rxPowerdBm] = mlWifiChannel(txPPDU, ...
    senderPosition, receiverPosition, powerLevel, txGain, rxGain, channelBW);

%% Decoding
% Non-HT waveform configuration object
recoverConfig = genConfig;
% Decode the signal which is generated by generator
% In a real receiver we would use an AGC, but here we can just add a
% gain, based on the known loss due to FSPL (less TX and RX gains)
agcGain = -(rxPowerdBm-30)-rxGain; % Convert dBm to dBW
[rxPSDU] = mlWifiRecover(rxPPDU, recoverConfig, rxGain, agcGain);
% Convert column vector to row vector
rxPSDU = rxPSDU';
rxPacket = zeros(1, length(rxPSDU)/8);
% Convert binary number to decimal
for j=1:length(rxPSDU)/8
    rxPacket(j) = (bi2de(rxPSDU((j-1)*8+1:j*8)));
end
% Parameters returned to ns3
resultPacket = [rxPacket rxPowerdBm];
end
