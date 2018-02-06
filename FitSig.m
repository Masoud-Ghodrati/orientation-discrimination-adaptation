function [fitresult, gof] = FitSig(x, y, C, YLim)

[xData, yData] = prepareCurveData( x, y );
% Set up fittype and options.
ft = fittype( 'a+(b-a)./(1+10.^((c-x)*d))', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Algorithm = 'Levenberg-Marquardt';
opts.Display = 'Off';
opts.Robust = 'Bisquare';
opts.StartPoint = [0.46417994779207 0.914151504766211 0.587851100309095 0.25628921630764];
opts.TolFun = 1e-10;
% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

A = coeffvalues(fitresult);
Xout = linspace(x(1), x(end), 100);
Fun = @(x) (A(1)+(A(2)-A(1))./(1+10.^((A(3)-x)*A(4))));
Yout = Fun(Xout);
plot(Xout, Yout, 'color', C)
ylim(YLim)

