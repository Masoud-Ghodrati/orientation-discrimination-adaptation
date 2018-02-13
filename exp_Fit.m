function [fitresult, gof] = exp_Fit(x, y)

fitresult = cell( 2, 1 );
gof = struct( 'sse', cell( 2, 1 ), ...
    'rsquare', [], 'dfe', [], 'adjrsquare', [], 'rmse', [] );

%% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( x, y );

% Set up fittype and options.
ft = fittype( 'a./(1+exp(-(x-b))/c)', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [0.196039171128035 0.138736255434066 0.744506836440447];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );




