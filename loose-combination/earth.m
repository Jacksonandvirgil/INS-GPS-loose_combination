function [wnie, wnen, RMh, RNh, gn] = earth(pos, vn)
global glv
    sl=sin(pos(1)); cl=cos(pos(1)); tl=sl/cl; sl2=sl*sl; sl4=sl2*sl2;
    wnie = glv.wie*[0; cl; sl];
    sq = 1-glv.e2*sl2; sq2 = sqrt(sq);                  %glv.f = 1/298.3�������
    RMh = glv.Re*(1-glv.e2)/sq/sq2+pos(3);              %����Ȧ���ʰ뾶
    RNh = glv.Re/sq2+pos(3);                            %î��Ȧ���ʰ뾶
    wnen = [-vn(2)/RMh; vn(1)/RNh; vn(1)/RNh*tl];
    g = glv.g0*(1+5.27094e-3*sl2+2.32718e-5*sl4)-3.086e-6*pos(3);
    gn = [0;0;-g];
