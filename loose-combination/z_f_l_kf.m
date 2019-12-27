clear all;
close all;
clc;
tic;
%%
%����ȫ�ֱ���
glvs
t = 284;       %��ʱ�䳤��
ts = 1;        %��������
tn = 0 + ts;
len = t/ts; 
kk = 1;        %��������kf��ѭ�����������

%%
%����ʵ������
original_data_1 = importdata('twice.txt');         %���봫��������
imu_10hz = original_data_1.data(:,:);
gps_vel = zeros(2840,3);
gps_vel_1hz = zeros(284,3);
time = imu_10hz(:,1);
for i = 1:2839                                     %����gps�������ٶ�
    pos_2 = imu_10hz(i+1,17:19);
    pos_1 = imu_10hz(i,17:19);
    gps_vel(i,:) = (pos_2 - pos_1)/(time(i+1)-time(i));
end
for i = 10:10:2840                                 %������λ����ȡ1Hz���ٶ�����   
    gps_vel_1hz(i/10,:) = median(gps_vel((i-9):i,:));    
end
gps_vel_E = gps_vel_1hz(:,1) * 111000 * cos(34.79924667); 
gps_vel_N = gps_vel_1hz(:,2) * 111000;
gps_vel_U = gps_vel_1hz(:,3);
gps_vel_ENU = [gps_vel_E, gps_vel_N, gps_vel_U];

%%
%��ʼֵ����
gps_pos_1hz = zeros(284,3);
for i = 10:10:2840                    %������λ����ȡ1Hz�ľ��ȡ�γ�ȡ��߶�����   
    gps_pos_1hz(i/10,:) = median(imu_10hz((i-9):i,17:19));    
end
gps_lon = gps_pos_1hz(:,1);
gps_lat = gps_pos_1hz(:,2);
gps_alt = gps_pos_1hz(:,3);
% att0=[0;0;0]*glv.deg;  
att0 = imu_10hz(1,8:10)' * glv.deg;    %1������ 2����� 3����ǣ���ƫ��Ϊ����%-PI/2<=pitch<=PI/2, -PI<roll<=PI, -PI<yaw<=PI
% vn0=[250;00;0];%�������ٶ�
vn0 = gps_vel_ENU(1,:)';               %gps�������ٶ�
% pos0=[30*glv.deg;120*glv.deg;2000];  %1���� 2γ�� 3�߶� 
pos_lon = gps_pos_1hz(1,1) * glv.deg;  %1���� 2γ�� 3�߶�
pos_lat = gps_pos_1hz(1,2) * glv.deg;  
pos_alt = gps_pos_1hz(1,3);
pos0 = [pos_lon; pos_lat; pos_alt];    %��3��ֵ��GPS��ֵ,�������

%%
%GPS���
phi  = [0.5;0.5;0.5] * glv.min;        %GPS������� 
dvn  = [0.1;0.1;0.1];                  %GPS(�ߵ�)�ٶ����0.1m/s (��GPS��ֵ����ΪINS�ĳ�ֵ)
dpos = [10/glv.Re; 10/glv.Re; 10];     %��3��ֵ��gps(�ߵ�)��ʼλ����� (��GPS��ֵ������ΪINS�ĳ�ֵ���)                                     
%IMU���
gyro = 5;
accm = 1;
eb  = gyro * [.01;.01;.01] * glv.dph;               %ƫ�����          %�Ƕ� 
db  = accm * [.01;.01;.01] * glv.mg;                                   %���ٶ�
web = gyro * [0.007;0.007;0.007] * glv.dph;         %�������������    %�Ƕ�
wdb = accm * [0.00018;0.00018;0.00018] * glv.mg;                       %���ٶ�

%%
%�˲�����ֵ����
Qt = diag([web; wdb; .01*dpos;.1*eb;.1*db])^2; %�������Ƕ������������ٶ���IMUλ����ƫ�����Ƕȡ�ƫ�������ٶȣ���ʼϵͳ����������
Rk = diag([dvn;dpos])^2;                       %��������������
Pk = diag([[1;1;1] * glv.deg; 10 * dvn; 100 * dpos; 100 * web; 10 * wdb])^2;    %Ԥ��״̬Э�������
Xk = zeros(15,1);                                                               %��ʼʱ��nά״̬����
Hk = [zeros(6,3),eye(6),zeros(6)];                                              %��ʼʱ�̵��������

%%
%�洢�վ���ȶ���
errphi = zeros(t,3);               %��̬�ǽ������ 
errvn = errphi;                    %�ٶȽ������
errpos = errphi;                   %λ�ý������ 
Xkk = zeros(t,15);                 %��̬�������&����������
hwaitbar = waitbar(0,'��Ⱥ�...');
deltapos = zeros(t,3);             %���Ե������-���kf�˲����� = ����λ����� 
deltavn = zeros(t,3);              %���Ե������-���kf�˲����� = �����ٶ���� 
deltaphi = zeros(t,3);             %���Ե������-���kf�˲����� = ������̬��� 
Kkminmatrix = zeros(t,1);          %������������Сֵ
Kkmaxmatrix = zeros(t,1);          %�������������ֵ
pkminmatrix = zeros(t,1);          %Ԥ��״̬Э���������Сֵ
pkmaxmatrix = zeros(t,1);          %Ԥ��״̬Э����������ֵ
testmatrix = zeros(t,3);           %��������̬���״̬��
gyrooutm = zeros(len,4);           %�����ǵ�ʵ������洢����
accoutm = zeros(len,4);            %���ٶȼƵ�ʵ������洢����

%%
%�켣���� 
for k = 1:len    
    if k < 10/ts       %10
        div_pitch = 0 * glv.deg;     %-PI/2<=pitch<=PI/2����ʼ��̬�Ƕ���
        div_roll  = 0 * glv.deg;
        div_head  = 0 * glv.deg;
        aby = 0;                     %������ٶȣ�
    elseif k < 20/ts   %20
        div_pitch = 0 * glv.deg;
        div_roll  = 0 * glv.deg;
        div_head  = 0 * glv.deg;
        aby = 0;
    elseif k < 30/ts   %30
        div_pitch = 0 * glv.deg;
        div_roll  = 0 * glv.deg;
        div_head  = 0 * glv.deg;
        aby = 0;
    %{
    if k<10/ts
        div_pitch=1*glv.deg;
        div_roll=0*glv.deg;
        div_head=0*glv.deg;
        aby=0;
    elseif k<20/ts
        div_pitch=-1*glv.deg;
        div_roll=0*glv.deg;
        div_head=0*glv.deg;
        aby=00;
    elseif k<30/ts
        div_pitch=0*glv.deg;
        div_roll=1*glv.deg;
        div_head=0*glv.deg;
        aby=-0;   
    elseif k<40/ts
        div_pitch=0*glv.deg;
        div_roll=-1*glv.deg;
        div_head=0*glv.deg;
        aby=-00;
    elseif k<50/ts
        div_pitch=0*glv.deg;
        div_roll=0*glv.deg;
        div_head=1*glv.deg;
        aby=0;
    elseif k<60/ts
        div_pitch=0*glv.deg;
        div_roll=0*glv.deg;
        div_head=-1*glv.deg;
        aby=0;
    elseif k<70/ts
        div_pitch=0*glv.deg;
        div_roll=0*glv.deg;
        div_head=0*glv.deg;
        aby=.5*glv.g0;
    elseif k<80/ts
        div_pitch=0*glv.deg;
        div_roll=0*glv.deg;
        div_head=0*glv.deg;
        aby=-.5*glv.g0;
    elseif k<90/ts
        div_pitch=0*glv.deg;
        div_roll=0*glv.deg;
        div_head=0*glv.deg;
        aby=0;       
        %}
    else
    end
    att0(1) = att0(1) + div_pitch * ts;
    att0(2) = att0(2) + div_roll * ts;
    att0(3) = att0(3) + div_head * ts;
    [pitch0,roll0,head0] = astd(att0);                %��̬�ǵ���ֵ
    delvby = aby * ts;                                %�����ٶȣ�
    
    [wnie, wnen, RMh, RNh, gn] = earth(pos0, vn0);    %����GPS�ĳ�ʼλ�úͳ�ʼ�ٶȼ��������ת�����ʣ���������ϵ��...
                                                      %...����������ڵ���ת���Ľ��ٶȣ���������ϵ���Ȳ���
    qnb0 = a2qnb(att0);                               %��ʼ��Ԫ��/��ȷ��Ԫ��
    vn0 = vn0 + a2cnb(att0) * [0;delvby;0];           %��ȷ�ٶȣ��ͽ���������ͬʱ�̣�
    pos0 = pos0 + ts * [vn0(2)/RMh; (vn0(1)/RNh) * sec(pos0(1)); vn0(3)];  %��ȷλ��
    if k == 1                                  
        vn  = vn0;                                    %��ȷ�ٶ�      
        pos = pos0;                                   %��ȷλ��
        qnb = qaddphi(a2qnb(att0),phi);               %��������ϵ����������ϵת�������Ԫ��
    end                      
    m0 = [cos(roll0)   0    sin(roll0)*cos(pitch0);
                  0    1              -sin(pitch0);
          sin(roll0)   0   -cos(roll0)*cos(pitch0)];                    %��ת����
    wbnb = m0 * [div_pitch;div_roll;div_head];                          %��������ϵ�µ���̬�Ƕ����
    wbib = qmulv(qconj(qnb0),(wnie + wnen)) + wbnb;                     %��������ϵ����������ϵ��ת��
    fb = [0;aby;0] + (a2cnb(att0))' * (askew(2 * wnie + wnen) * vn0-gn);%�������������ٶ�
 
    wm = (wbib + web .* randn(3,1)) * ts;             %��λʱ��Ƕ�����=���ݲ����Ľ��ٶ�*ʱ����
    vm = (fb + wdb .* randn(3,1)) * ts;               %��λʱ���ٶ�����=�ӱ�����ļ��ٶ�*ʱ����

    gyrooutm(k,:) = [tn,(wbib + eb + web .* randn(3,1))']; %�����ǵ�ʵ������洢����
    accoutm(k,:)  = [tn,(fb + db + wdb .* randn(3,1))'];   %���ٶȵ�ʵ������洢����
    
    %%
    %��������   
    [qnb,vn,pos] = sins(qnb,vn,pos,wm,vm,ts); %�õ�nϵ�µ���Ԫ�����������ٶȺ�λ��
    att = q2att(qnb);
    pitch = att(1);
    roll  = att(2);
    head  = att(3);
    Ft = getf(qnb, vn, pos, vm./ts);          %��ʼ״̬ת�ƾ��� 
    [Fikk_1, Qk] = kfdis(Ft, Qt, ts, 1);      %�õ�״̬ת�ƾ����ϵͳ����������

%%
%��ʼ�˲�    
    if mod(k,1/ts) == 0                       %ÿһ���˲�һ��
        vnGPS = vn0 + dvn .* randn(3,1);      %������GPS���ߵ����ٶ�����GPS�ٶ�
        posGPS = pos0 + dpos .* randn(3,1);   %�����˹ߵ���ʼλ������GPSλ�� 

%       Zk = [vn - vnGPS;pos - posGPS];
        Zk = [vn - vnGPS;pos - posGPS];       %���������ٶȺͽ�������λ�ü�ȥGPS�ٶȺ�λ�õ������Ե���������Ϊ��������
        
        [Xk, Pk, Kk] = kf(Fikk_1, Qk, Xk, Pk, Hk, Rk, Zk);   %�õ�Ԥ��״̬��Ԥ��״̬Э�������
        
        %��������delta���� 
        pkmin = msearch(Pk,1);                 %Ԥ��״̬Э������Сֵ
        pkminmatrix(kk) = pkmin;
        pkmax = msearch(Pk,2);                 %Ԥ��״̬Э�������ֵ
        pkmaxmatrix(kk) = pkmax;
        
        Kkmin = msearch(Kk,1);                 %������Сֵ
        Kkminmatrix(kk) = Kkmin;
        Kkmax = msearch(Kk,2);                 %�������ֵ
        Kkmaxmatrix(kk) = Kkmax;      
        
        errphi(kk,:) = qq2phi(qnb,qnb0)';      %��̬�ǽ������
        errvn(kk,:)  = (vn-vn0)';              %�ٶȽ������
        errpos(kk,:) = (pos-pos0)';            %λ�ý�������������λ��-gps��ȷλ�ã�
        
        Xkk(kk,:) = Xk';                       %Xkk��̬���ٶȣ�λ�ã����ݣ��Ӽ�
        
        deltaphi(kk,:) = errphi(kk,:)-Xk(1:3)';%���Ե������-���kf�˲�����=��������̬���� 
        deltavn(kk,:)  = (vn-vn0)'-Xk(4:6)';   %���Ե������-���kf�˲�����=�������ٶ���
        deltapos(kk,:) = (pos-pos0)'-Xk(7:9)'; %���Ե������-���kf�˲�����=������λ����
   
        testmatrix(kk,:) = Xk(1:3)';           %���kf�˲����ƾ�����̬�ǣ� 
        
        kk = kk + 1;
        waitbar(kk/(len * ts),hwaitbar,[num2str(fix(100 * kk/(len * ts))),'%']) %������ʾ 
    else
        [Xk, Pk] = kf(Fikk_1, Qk, Xk, Pk);     %�޹۲�ʱֻ����Ԥ��-Ԥ��ֵ��Ϊ��һ��״̬�ĳ�ֵ
    end       
    tn = tn + ts;
end

%%
%�������ͼ
figure;                                         %��̬�������&����������
subplot(3,1,1),plot(errphi(:,1)*10/glv.deg,'r'),title('��̬�ǽ������');
ylabel('\it\delta\theta \rm(deg)'); grid on; legend('������');
subplot(3,1,2),plot(errphi(:,2)/100/glv.deg,'k'),
ylabel('\it\delta\gamma \rm(deg)'); grid on; legend('������');
subplot(3,1,3),plot(errphi(:,3)/100/glv.deg,'b'),
xlabel('\itt\rm(sec)'); ylabel('\it\delta\psi \rm(deg)'); grid on; legend('�����');
%legend('����ǽ������','���������������');

figure;                                         %�ٶȽ������&����������
subplot(3,1,1),plot(errvn(:,1),'r'),title('�ٶȽ������');
ylabel('\it\deltaV_{E}\rm(m/s)'); grid on; legend('�����ٶ�');
subplot(3,1,2),plot(errvn(:,2),'k'),
ylabel('\it\deltaV_{N}\rm(m/s)'); grid on; legend('�����ٶ�');
subplot(3,1,3),plot(errvn(:,3),'b'),
xlabel('\itt\rm(sec)'); ylabel('\it\deltaV_{U}\rm(m/s)'); grid on; legend('�����ٶ�');

figure;                                         %λ�ý������&����������
subplot(3,1,1),plot(errpos(:,1)*glv.Re,'r'),title('λ�ý������');
ylabel('\it\deltaL\rm(m)'); grid on; legend('����');
subplot(3,1,2),plot(errpos(:,2)*glv.Re,'k'),
ylabel('\it\delta\lambda\rm(m)'); grid on; legend('γ��');
subplot(3,1,3),plot(errpos(:,3),'b'),
xlabel('\itt\rm(sec)');ylabel('\it\deltah\rm(m)'); grid on; legend('�߶�');
%{
figure;
subplot(3,1,1),plot(gyrooutm(:,1),gyrooutm(:,2)/glv.deg,'k');title('������ʵ�����');
ylabel('\it\omega_{ibx}^{b}\rm (deg/s)');grid;
subplot(3,1,2),plot(gyrooutm(:,1),gyrooutm(:,3)/glv.deg,'k');
ylabel('\it\omega_{iby}^{b}\rm (deg/s)');grid; 
subplot(3,1,3),plot(gyrooutm(:,1),gyrooutm(:,4)/glv.deg,'k');
xlabel('\itk');ylabel('\it\omega_{ibz}^{b}\rm (deg/s)');grid;

figure;
subplot(3,1,1),plot(accoutm(:,1),accoutm(:,2),'k');title('���ٶȼ�ʵ�����');
ylabel('\itf_{x}^{ b}\rm (m/s^{2})');grid;
subplot(3,1,2),plot(accoutm(:,1),accoutm(:,3),'k');
ylabel('\itf_{y}^{ b}\rm (m/s^{2})');grid; 
subplot(3,1,3),plot(accoutm(:,1),accoutm(:,4),'k');
xlabel('\itk');ylabel('\itf_{z}^{ b}\rm (m/s^{2})');grid;
%}
figure;                                             %��̬�ղ�
subplot(3,1,1),plot(deltaphi(:,1)/100/glv.deg,'r');title('�ղ�-��̬�����');
ylabel('\it\delta\theta \rm(deg)');grid on; legend('������');
subplot(3,1,2),plot(deltaphi(:,2)/100/glv.deg,'k');
ylabel('\it\delta\gamma \rm(deg)');grid on; legend('������');
subplot(3,1,3),plot(flipud(deltaphi(:,3))/100/glv.deg,'b');
xlabel('\itt\rm(sec)');ylabel('\it\delta\psi \rm(deg)');grid on; legend('�����');

figure;                                              %�ٶ��ղ�
subplot(3,1,1),plot(deltavn(:,1),'r');title('�ղ�-�ٶ����');
ylabel('\it\deltaV_{E}\rm(m/s)');grid on; legend('�����ٶ�');
subplot(3,1,2),plot(deltavn(:,2),'k');
ylabel('\it\deltaV_{N}\rm(m/s)');grid on; legend('�����ٶ�');
subplot(3,1,3),plot(deltavn(:,3),'b');
xlabel('\itt\rm(sec)');ylabel('\it\deltaV_{U}\rm(m/s)');grid on; legend('�����ٶ�');

figure;                                              %λ���ղ�
subplot(3,1,1),plot(deltapos(:,1)*glv.Re,'r');title('�ղ�-λ�����');
ylabel('\it\deltaL\rm(m)');grid on; legend('����');
subplot(3,1,2),plot(deltapos(:,2)*glv.Re,'k');
ylabel('\it\delta\lambda\rm(m)');grid on; legend('γ��');
subplot(3,1,3),plot(deltapos(:,3),'b');
xlabel('\itt\rm(sec)');ylabel('\it\deltah\rm(m)');grid on; legend('�߶�');

figure;                                              %��̬�������&����������
subplot(3,1,1),plot(errphi(:,1)/glv.min,'r'),title('��̬�������&����������');
subplot(3,1,1),hold on,plot(Xkk(:,1)/glv.min,'b'), 
xlabel('\itt\rm / s'); ylabel('\it\phi \rm / arcmin(�Ƿ�)'); grid on
legend('�����ǽ������','����������������');
subplot(3,1,2),plot(errphi(:,2)/glv.min,'r'),
subplot(3,1,2),hold on,plot(Xkk(:,2)/glv.min,'b'), 
xlabel('\itt\rm / s'); ylabel('\it\phi \rm / arcmin(�Ƿ�)'); grid on
legend('����ǽ������','���������������');
subplot(3,1,3),plot(errphi(:,3)/glv.min,'r'),
subplot(3,1,3),hold on,plot(Xkk(:,3)/glv.min,'b'), 
xlabel('\itt\rm / s'); ylabel('\it\phi \rm / arcmin(�Ƿ�)'); grid on
legend('����ǽ������','���������������');

figure;                                              %�ٶȽ������&����������
subplot(3,1,1),plot(errvn(:,1),'r'),title('�ٶȽ������&����������');
subplot(3,1,1),hold on,plot(Xkk(:,4),'b'), 
xlabel('\itt\rm / s'); ylabel('�����ٶ�\it\delta V \rm / m/s'); grid on
legend('�����ٶȽ������','�����ٶ�����������');
subplot(3,1,2),plot(errvn(:,2),'r'),
subplot(3,1,2),hold on,plot(Xkk(:,5),'b'), 
xlabel('\itt\rm / s'); ylabel('�����ٶ�\it\delta V \rm / m/s'); grid on
legend('�����ٶȽ������','�����ٶ�����������');
subplot(3,1,3),plot(errvn(:,3),'r'),
subplot(3,1,3),hold on,plot(Xkk(:,6),'b'), 
xlabel('\itt\rm / s'); ylabel('�����ٶ�\it\delta V \rm / m/s'); grid on
legend('�����ٶȽ������','�����ٶ�����������');

figure;                                              %λ�ý������&����������
subplot(3,1,1),plot(errpos(:,1)*glv.Re,'r'),title('λ�ý������&����������');
subplot(3,1,1),hold on,plot(Xkk(:,7)*glv.Re,'b'), 
xlabel('\itt\rm / s'); ylabel('\it\delta P \rm / m'); grid on
legend('���Ƚ������','��������������');
subplot(3,1,2),plot(errpos(:,2)*glv.Re,'r'),
subplot(3,1,2),hold on,plot(Xkk(:,8)*glv.Re,'b'), 
xlabel('\itt\rm / s'); ylabel('\it\delta P \rm / m'); grid on
legend('γ�Ƚ������','γ������������');
subplot(3,1,3),plot(errpos(:,3),'r'),
subplot(3,1,3),hold on,plot(Xkk(:,9),'b'), 
xlabel('\itt\rm / s'); ylabel('\it\delta P \rm / m'); grid on
legend('�߶Ƚ������','�߶�����������');

figure;                                                 %����Ư�ƹ���
subplot(3,1,1),plot(Xkk(:,10)/glv.dph,'r');title('����Ư�ƹ���');
ylabel('x��\it\epsilon \rm / \circ/h');grid on; legend('x��');
subplot(3,1,2),plot(Xkk(:,11)/glv.dph,'k');
ylabel('y��\it\epsilon \rm / \circ/h');grid on; legend('y��');
subplot(3,1,3),plot(Xkk(:,12)/glv.dph,'b');
xlabel('\itt\rm / s');ylabel('z��\it\epsilon \rm / \circ/h');grid on; legend('z��');

figure;                                                 %�Ӽ�Ư�ƹ���
subplot(3,1,1),plot(Xkk(:,13)/glv.mg,'r');title('�Ӽ�Ư�ƹ���');
ylabel('x��\it\nabla \rm / mg');grid on; legend('x��');
subplot(3,1,2),plot(Xkk(:,14)/glv.mg,'k');
ylabel('y��\it\nabla \rm / mg');grid on; legend('y��');
subplot(3,1,3),plot(Xkk(:,15)/glv.mg,'b');
xlabel('\itt\rm / s');ylabel('z��\it\nabla \rm / mg');grid on; legend('z��');

figure;
plot(Kkminmatrix,'r');title('Kk�仯');grid on
hold on;plot(Kkmaxmatrix,'b');
legend('min','max');

figure;
plot(pkminmatrix,'r');title('Pk�仯');grid on
hold on;plot(pkmaxmatrix,'b');
legend('min','max');

close(hwaitbar);
toc;


