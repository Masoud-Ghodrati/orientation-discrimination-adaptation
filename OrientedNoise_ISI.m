function NoiseImg = OrientedNoise_ISI(stim, thisStim, scr, sc, st)

F = (scr.ppd*[0:stim.diamPix(1)/2])./stim.diamPix(1);
Siz = stim.diamPix(1);
Siz = floor(Siz/2);
% [fx, fy] = meshgrid(-Siz : Siz, Siz :-1: -Siz);
[fx, fy] = meshgrid([-F(end:-1:1) F(2:end)], [F(end:-1:1) -F(2:end)]);
fr = (fx.^2+fy.^2).^0.5;
Theta = atand(fy./fx);
Theta(fx < 0 & fy > 0) = Theta(fx < 0 & fy > 0) + 180; % quadrant II
Theta(fx < 0 & fy < 0) = Theta(fx < 0 & fy < 0) + 180;
Theta(fx > 0 & fy < 0) = Theta(fx > 0 & fy < 0) + 360;
Gr = exp(-0.5*((fr-stim.SfCenterTest)./stim.SfBWISI).^2);
Gth = exp(-0.5*((Theta-thisStim)./stim.OriBWISI).^2) + exp(-0.5*((Theta-(thisStim+180))./stim.OriBWISI).^2);
S = Gr.*Gth;
S(isnan(S)) = 0;

Img = rand(size(S));
originalImage_fft = fft2(Img);
Phase = angle(originalImage_fft);
NoiseImg = real(ifft2(fftshift(S).* exp(1i*Phase)));
NoiseImg = (NoiseImg-min(NoiseImg(:)))./(max(NoiseImg(:))-min(NoiseImg(:)));
ThisCont = st(2, sc-1); 
ThisLum = st(3, sc-1); 
NoiseImg = imadjust(NoiseImg, [0 1],[max(ThisLum-(ThisCont/2), 0), max(ThisLum+(ThisCont/2), 0)]);
NoiseImg(fr>=F(end)) = stim.BackGrLum;
