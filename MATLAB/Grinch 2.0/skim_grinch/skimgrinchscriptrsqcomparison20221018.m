function skimgrinchscriptrsqcomparison20221018(petdetcsvpath, intdenpath, nChambers, isLog, isHisto, isMultiplot, isCellplot)
%Import files declared by app
%csv file are generated by imageJ scripts with specific formatting
disp('YOU ARE USING RSQ GRINCH')
tic

petDetOptions = detectImportOptions(petdetcsvpath);
petDetMatrix = readmatrix(petdetcsvpath, petDetOptions); %(col 1 1:160) (col 2 1:160) (col 3 max intensities) (col 4 cell present == 1)
intDenOptions = detectImportOptions(intdenpath);
intDenMatrix = readmatrix(intdenpath, intDenOptions); %rows = time,  cols = chamber integrated density, COL 2 = CHAMBER 1
intDenMatrix(:,1) = []; %Removes useless col 1 
intDenSize = size(intDenMatrix);
% maxIntensity = max(intDenMatrix,[],'all'); %max value of intden (max min is to put every plot on same scale)
% minIntensity = min(min_id,[],'all');
cellSlopeArray = [];
allSlopeArray = [];
%RSQ
fitOrder = 1; 
sub_rsq_array = [];
rsq_array = [];
I = [];
rsq_percent_change = [];
%RSQ

clear figure(1);
clear figure(2);
clear figure(3);

if isMultiplot == 1
    multiplot;
elseif isCellplot == 1
    cellplot;
end


    function cellplot
        cellArray = intDenMatrix;
        blankArray = intDenMatrix;
        backroundSubtractedArray = intDenMatrix;
        cellTitleArray = [];
        color = ('g.');
        j = 1; %it just works
        for nChamber=1:nChambers
            if petDetMatrix(nChamber,4) == 1 %if cell, record chamber id number
                cellTitleArray(end+1) = nChamber;
                blankArray(:,j) = []; %Need to collect data for empty chambers for background subtraction
                j = j+1;

            else
                cellArray(:,j+1) = []; %remove intensity column if no cell
            end %if loop
        end %for loop

        %Background Subtraction
        averageBackgroundArray = mean(blankArray, 2);
        backgroundArraySize = size(averageBackgroundArray);
        intDenCellArraySize =size(cellArray);
        for n=1:backgroundArraySize(1,1)
            for itteration=2:intDenCellArraySize(1,2)
                backroundSubtractedArray(n,itteration) = cellArray(n,itteration) - averageBackgroundArray(n,1);
            end
        end %background subtraction

        f1 = tiledlayout('flow');
        for nChamber=2:intDenCellArraySize(1,2) %nightmare
            nexttile;
            if isLog == 1
                y_log = log10(backroundSubtractedArray(:,nChamber)); %convert intensity to log
                plot1 = plot(backroundSubtractedArray(:,1), y_log, color); %plot log
            else
                plot1 = plot(backroundSubtractedArray(:,1), backroundSubtractedArray(:,nChamber), color);
            end
            axis([0 intDenSize(1) minIntensity maxIntensity])
            set(gca,'xtick',[],'ytick',[]); %removes axis labels (gca get current axis)
            title(num2str(cellTitleArray(nChamber-1)));
        end
    end %func cellplot


    function multiplot
        f1 = tiledlayout(8,20);
        backgroundArray = intDenMatrix; %Array containing blanks
        

        %Get empty chamber value matrix
        j = 1; %shrinking matrix bs
        for nChamber=1:nChambers
            if petDetMatrix(nChamber,4) == 1 %petdetective
                backgroundArray(:,j) = []; %Remove data from array describing cells
            else 
                j = j+1; 
            end
        end %Get empty chamber value matrix

        %Background Subtraction
        averageBackgroundArray = mean(backgroundArray, 2);
        backroundSubtractedArray = intDenMatrix - averageBackgroundArray;
        %background subtraction
        
        maxIntensity = max(intDenMatrix, [], 'all');
        maxSubIntensity = max(backroundSubtractedArray,[],'all');
        minSubIntensity = min(backroundSubtractedArray,[],'all');
        timeArray = 1:1:intDenSize(1,1); %matrix from 1 to time limit incrementing by 1. gives row of length time
        timeArray = timeArray.';
        figure(3);
        plot(timeArray, averageBackgroundArray, 'r.');
        figure(1);

        for nChamber=1:nChambers
    		nexttile;
            sub_nChamberIntensities = backroundSubtractedArray(:,nChamber);
            nChamberIntensities = intDenMatrix(:,nChamber);
%Background Subtracted RSQ 
            sub_coefficients = polyfit(timeArray,sub_nChamberIntensities,fitOrder);
            sub_nChamberFit = polyval(sub_coefficients , timeArray);
            sub_yresid = sub_nChamberIntensities - sub_nChamberFit;
            sub_ssresid = sum(sub_yresid.^2);
            sub_sstotal = (length(sub_nChamberIntensities))*var(sub_nChamberIntensities);
            sub_rsq_value = 1-sub_ssresid/sub_sstotal;
            sub_rsq_array = [sub_rsq_array;sub_rsq_value];
% RSQ w/ no background subtraction
            coefficients = polyfit(timeArray,nChamberIntensities,fitOrder);
            nChamberFit = polyval(coefficients , timeArray);
            yresid = nChamberIntensities - nChamberFit;
            ssresid = sum(yresid.^2);
            sstotal = (length(nChamberIntensities))*var(nChamberIntensities);
            rsq_value = 1-ssresid/sstotal;
            rsq_array = [rsq_array;rsq_value];
            rsq_dif_percent = ((sub_rsq_value -rsq_value)/rsq_value) * 100;
            rsq_percent_change = [rsq_percent_change;rsq_dif_percent];
            
            if petDetMatrix(nChamber,4) == 0 %petdetective
                color = ('k.'); %black is k: no cell
            else
                color = ('g.'); %green is g: cell present
            end %petdective

            if isLog == 1 
%                 y_log = log10(backroundSubtractedArray(:,nChamber)); %convert intensity to log
%                 plot1 = plot(backroundSubtractedArray(:,1), y_log, color); %plot log
            else

                plot1 = plot(timeArray, backroundSubtractedArray(:,nChamber), color); 
                hold on
                plot(timeArray, nChamberFit, 'r-', 'LineWidth', 1);
                plot(timeArray, sub_nChamberFit, 'r-', 'LineWidth', 1);
                plot(timeArray, intDenMatrix(:,nChamber), 'b.');
                set(gca,'xtick',[],'ytick',[]); %removes axis labels (gca: get current axis) 160 axis labels is bad
                axis([0 intDenSize(1) (minSubIntensity) (maxIntensity)]) %x axis 0 to time max, y from min intensity to max intensity
                title(rsq_dif_percent);
                hold off

            end %end log

            if isHisto == 1
%                 xdata1 = get(plot1, 'xdata');
%                 ydata1 = get(plot1, 'ydata');
%                 xdata1 = xdata1(:);
%                 ydata1 = ydata1(:);
%                 fitResults1 = polyfit(xdata1,ydata1,1);
%                 slope1 = fitResults1(1,1);
%                 allSlopeArray = [allSlopeArray, slope1];
%                 if petDetMatrix(nChamber,4) == 1 %slope matrix from cells only
%     				cellSlopeArray = [cellSlopeArray, slope1];
%                 end
            end %is histo
            I = [I;nChamber];
        end %nchambers loop
T = table(I, rsq_array, sub_rsq_array, rsq_percent_change, 'VariableNames',{'Chamber','RSQ w/out Background Subtraction', 'RSQ w Background Subtraction', '% Change in RSQ'});
writetable(T, 'RSQexport.csv')
%         if isHisto == 1
%             f2 = figure(2);
%             histogram(cellSlopeArray);
%             title('Cell Slope')
%             xstr = "Slope (Fluorescence vs Time)";
%             xlabel(f2, xstr, 'FontWeight','bold');
%             ylabel(f2, "Quantity of Chambers",'FontWeight', 'bold');
%         end
          
        end %func multiplot
    toc
    end %grinchscript
