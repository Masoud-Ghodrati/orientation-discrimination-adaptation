function [fitresult, gof] = calculated_Sigmoid_Fit(x, y)
[xData, yData] = prepareCurveData( x, y );

% Set up fittype and options.
ft = fittype( 'b+((a-b)./(1+exp(x-c)/d))', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [0.469321781741488 0.800766989427437 0.399142339423455 0.906130625218478];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

