             %%%%%%%%%%%%%%%%%��P�ĳ�ֵ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
   a=100;
   P=a*eye(15);
   x0=rand(15,1);
   z0=rand(9,1);
  wx=-0.005115;	
  wy=-0.008950;	
   wz=0.001918;	
   Wx=0.197725;
  Wy=-0.247156;	
  Wz=-9.589653;
  aa=0.001;
  bb=0.002;
  C_nb=[0.011 0.012 0.013;0.021 0.022 0.023;0.031 0.032 0.033];
 
 %%%%%%%%%%%%%%%%%%%%%%%%%% Q R  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   det_1=0.0001;det_2=0.0001;det_3=0.0001;r_1=0.1;r_2=0.1;r_3=0.1;r_4=0.05;r_5=0.005;r_6=0.005;r_7=0.002;r_8=0.002;r_9=0.002;
   Q=[det_1 0 0 0 0 0 0 0 0 0 0 0 0 0 0;0 det_2 0 0 0 0 0 0 0 0 0 0 0 0 0;0 0 det_3 0 0 0 0 0 0 0 0 0 0 0 0;zeros(12,15)];
   R=[r_1*eye(3) zeros(3,6);zeros(3,3) r_4*eye(3) zeros(3,3);zeros(3,6) r_7*eye(3)];
  A1=[0 -Wz Wy;Wz 0 -Wx;-Wy Wx 0];
  A2=[0 -wz wy;wz 0 -wx;-wy wx 0];
  A=[zeros(3) eye(3) zeros(3,9);zeros(3,6) A1 zeros(3) eye(3);zeros(3,6) A2 eye(3) zeros(3);zeros(3,9) -aa*eye(3) zeros(3);zeros(3,12) -bb*eye(3)];
  H1=[0 C_nb(1,3) -C_nb(1,2);0 C_nb(2,3) -C_nb(2,2);0 C_nb(3,3) C_nb(3,2)];
  H=[eye(3) zeros(3,12);zeros(3) eye(3) zeros(3,9);zeros(3,6) H1 zeros(3,6)];
 %%%%%%%%%%%%%%%%%%  Kalman �˲� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  [Xk, Pk, Kk] = Kalman_f(A, Q, x0, P, H, R, z0);