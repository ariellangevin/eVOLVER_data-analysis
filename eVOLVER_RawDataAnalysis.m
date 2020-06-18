% Raw data analysis for eVOLVER

% This code was written by A.M. Langevin, with the exception of code from
% C. Mancuso on Lines 18-41, last edited on 6/20/2019 by A.M. Langevin.

clc, clear, close all

N=[12:15,8:11,4:7,0:3]; % arrangement of vials on eVOLVER from FynchBio

for i=1:length(N)

    n=N(i); % pick a vial

    %%Open files from folder
    % The following file opening code was written by C.P. Mancuso in 2017.
    % (Lines 18-41)
    
    od_file = sprintf('%s/OD/vial%d_OD.txt',pwd, n);
    odset_file = sprintf('%s/ODset/vial%d_ODset.txt',pwd, n);
    temp_file = sprintf('%s/temp/vial%d_temp.txt',pwd, n);
    pump_file = sprintf('%s/pump_log/vial%d_pump_log.txt',pwd, n);
    
    od_file_open = fopen(od_file);
    od = textscan(od_file_open,'%f %f','Headerlines',1,'delimiter',',');
    fclose(od_file_open);
    
    odset_file_open = fopen(odset_file);
    odset = textscan(odset_file_open,'%f %f','Headerlines',3,'delimiter',',');
    fclose(odset_file_open);
    
    pump_file_open = fopen(pump_file);
    pump_rate = textscan(pump_file_open,'%f %f','Headerlines',1,'delimiter',',');
    fclose(pump_file_open);

    dilution_events = [];
    g_rate = [];
    NumberofDilutions=[];
    OD_data = [od{1} od{2}];
    pump_log = [odset{1} odset{2}];
    graph_dim = ceil(sqrt(length(pump_log(:,1))));
    flow_rate=[pump_rate{1} pump_rate{2}];
    
    
    count=0; % initialize counting of number of dilutions
    
   %% Segment data into dilution cycles and measure growth rate from trace
   
    if isempty(pump_log)~=1
        count = count+1; % count first dilution even though it will be ignored for growth rate calculations
    end
   
    for m=2:length(pump_log(:,1))
       if (pump_log(m,2) < pump_log(m-1,2)) && (pump_log(m,1) - pump_log(m-1,1) >.01)
           
            %%Split OD to Each Dilution Cycle
            [ODrow, ODcol] = find(OD_data(:,1)>pump_log(m-1,1) & OD_data(:,1)<pump_log(m,1));
            
            ODx = OD_data(ODrow,1)-OD_data(ODrow(1,1));
            ODy = OD_data(ODrow,2);
            
            if length(ODx) > 5 % make sure there is enough data to count the dilution
                od_start = nanmean(ODy(end-5:end));
                od_end = nanmean(ODy(1:5));
                duration = ODx(end);
                
                rate = ((od_start-od_end)/od_start)/duration; % linear growth
                % or alternatively:
                % r = fit(ODx,ODy,'exp1'); rate=r.b; % exponential growth
                
                g_rate(end+1,:) = [OD_data(ODrow(end,1)) rate]; % compile calculated growth rates

                count=count+1; % count this new dilution
                NumberofDilutions(end+1,:)=[OD_data(ODrow(1,1)) count]; % count number of diltuion events
            end
       end
    end
   
     
    figure(1) % visualize OD for each vial
    subplot(4,4,i)
    plot(cell2mat(od(1)),cell2mat(od(2)),'k-')
    title(['Vial ' num2str(n)])
    axis([0 5.5 0 0.5])
    if n==0
        ylabel('OD_{600}')
        xlabel('Time, h')
    end
    
    figure(2) % visualize OD, growth rate, and number of dilutions for each vial
    subplot(4,4,i)
    hold on
    yyaxis left
    plot(cell2mat(od(1)),cell2mat(od(2)),'-')
    hold on
    plot(cell2mat(odset(1)),cell2mat(odset(2)),'*')
    if n==0
        ylabel('OD_{600}')
        xlabel('Time, h')
    end
    axis([0 5.5 0 0.75])
    
    yyaxis right
    if isempty(g_rate)==0
    plot(g_rate(:,1),g_rate(:,2),'-o')
    if n==0
        ylabel('Growth Rate, 1/h','rotation',270, 'VerticalAlignment','bottom', 'HorizontalAlignment','center')
    end
    end
    axis([0 5.5 0 1.3])
    
    hold off
    box on
    title({['Vial ' num2str(n)]; [num2str(count),' dilutions']})
    
end