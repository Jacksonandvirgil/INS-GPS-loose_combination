function [pitch,roll,head]=astd(att)
pitch=att(1);%������
roll=att(2); %�����
head=att(3); %�����
while roll>pi
    roll=roll-2*pi;
end
while roll<-pi
    roll=roll+2*pi;
end
while head>pi
    head=head-2*pi;
end
while head<-pi
    head=head+2*pi;
end
