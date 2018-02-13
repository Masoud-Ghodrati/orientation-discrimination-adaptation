function mask = calculate_Mask_Aperture(stim, scr)


F = (scr.ppd*[0:stim.diamPix(1)/2])./stim.diamPix(1);
[fx, fy] = meshgrid([-F(end:-1:1) F(2:end)], [F(end:-1:1) -F(2:end)]);
fr = 1 ./ (1 + ( (fx/stim.MaskD0).^2 + (fy/stim.MaskD0).^2 ).^stim.MaskN);
[s1, s2] = size(fr);
frImg = imadjust(fr, [0 1],[max(ThisLum-(ThisCont/2), 0), max(ThisLum+(ThisCont/2), 0)]);
mask = ones(s1, s2, 2) * (scr.white/2);
mask(:, :, 2) = scr.white * (1 - frImg);
