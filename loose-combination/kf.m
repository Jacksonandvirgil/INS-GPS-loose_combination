function [Xk, Pk, Kk] = kf(Phikk_1, Qk, Xk_1, Pk_1, Hk, Rk, Zk)
    if nargin<7                         %������״̬����    
        Xk = Phikk_1*Xk_1;
        Pk = Phikk_1*Pk_1*Phikk_1'+Qk;
    else                                %�в���ʱ�˲�   
        %---time update
        Xkk_1=Phikk_1*Xk_1;             %��̬    
        Pkk_1 = Phikk_1*Pk_1*Phikk_1' + Qk; 
        %---measure update
        Pxz = Pkk_1*Hk';
        Pzz = Hk*Pxz + Rk;
        Kk = Pxz*Pzz^-1;                %����
        Xk = Xkk_1 + Kk*(Zk-Hk*Xkk_1);  %Ԥ��״̬
        Pk = Pkk_1 - Kk*Pzz*Kk';        %Ԥ��״̬Э����
    end
