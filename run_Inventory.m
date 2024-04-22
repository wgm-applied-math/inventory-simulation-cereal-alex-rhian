%% Run samples of the Inventory simulation
%
% Collect statistics and plot histograms along the way.

%% Set up

% Set-up and administrative cost for each batch requested.
K = 25.00;

% Per-unit production cost.
c = 3.00;

% Lead time for production requests.
 randomnumber = rand;
 if randomnumber < .1
    L = 2;
elseif randomnumber <.3 && randomnumber > .1
    L = 3;
elseif randomnumber < .7 && randomnumber > .3
    L = 4;
 elseif randomnumber > .7
    L = 5;
end

% Holding cost per unit per day.
h = 0.05/7;

% Reorder point. %200
ROP = 141;

% Batch size. %1500
Q = 757;

% How many samples of the simulation to run.
NumSamples = 100;

% Run each sample for this many days.
MaxTime = 100;

%% Run simulation samples

% Fraction of orders backlogged
numbacklog = zeros(1, NumSamples);
backlog = zeros(1, NumSamples);
fulfilled = zeros(1, NumSamples);
TotalBacklog = zeros(1, NumSamples);
TotalOrders = zeros(1, NumSamples);
Fraction_of_Orders = zeros(1, NumSamples);

for j = 1:NumSamples
    inventory = InventorySamples{j};
    numbacklog(1, j) = length(inventory.Backlog);
    fulfilled(1, j) = length(inventory.Fulfilled);

    for i = 1:fulfilled(1,j)
      if inventory.Fulfilled{1,i}.OriginalTime ~= inventory.Fulfilled{1,i}.Time
            backlog(1, j) = backlog(1, j) + 1;
     end
    end

TotalBacklog(1, j) = numbacklog(1, j) + backlog(1, j);
TotalOrders(1, j) = numbacklog(1, j) + length(inventory.Fulfilled);
Fraction_of_Orders(1, j) = TotalBacklog(1, j)/TotalOrders(1, j);
end


fig1 = figure();
t1 = tiledlayout(fig1, 1, 1);
ax1 = nexttile(t1);
Fraction_Histogram = histogram(ax1, Fraction_of_Orders, Normalization = "probability", BinMethod = "auto");
title(ax1, "Fraction of Orders Backlogged");
xlabel(ax1, "Fraction");
ylabel(ax1, "Probability");


% Fraction of days with non-zero backlog

daysbacklogged = zeros(1, NumSamples);
Fraction_of_Days = zeros(1, NumSamples);

for j = 1:NumSamples
    inventory = InventorySamples{j};
    for i = 1:MaxTime
        if inventory.Log{i, 3} > 0
         daysbacklogged(1, j) = daysbacklogged(1, j) + 1;
        end
    end
    Fraction_of_Days(1, j) = daysbacklogged(1, j)/10;
end

fig2 = figure();
t2 = tiledlayout(fig2, 1, 1);
ax2 = nexttile(t2);
Fraction_of_Days_Histogram = histogram(ax2, Fraction_of_Days, Normalization = "probability", BinMethod = "auto");
title(ax2, "Fraction of Days Backlogged");
xlabel(ax2, "Fraction");
ylabel(ax2, "Probability");

%Delay time of orders that get backlogged
lengthsoffulfilled = zeros(1, NumSamples);

for j = 1:NumSamples
    inventory = InventorySamples{j};
    lengthsoffulfilled(j) = length(inventory.Fulfilled);
end

maxFulfilled = max(lengthsoffulfilled);
DelayTime = zeros(NumSamples, maxFulfilled);

for j = 1:NumSamples
    inventory = InventorySamples{j};
    for i = 1:length(inventory.Fulfilled)
        DelayTime(j, i) = inventory.Fulfilled{1,i}.Time - inventory.Fulfilled{1,i}.OriginalTime;
    end
end

DelayTimeVector = reshape(DelayTime, 1, NumSamples*maxFulfilled);
DelayTimeVectorNoZeros = DelayTimeVector(DelayTimeVector ~= 0);

fig3 = figure();
t3 = tiledlayout(fig3, 1, 1);
ax3 = nexttile(t3);
Fraction_of_Days_Histogram = histogram(ax3, DelayTimeVectorNoZeros, Normalization = "probability", BinMethod = "auto");
title(ax3, "Delay Time");
xlabel(ax3, "Delay Time");
ylabel(ax3, "Count");



% For days with a backlog, the total backlog amount

Total_Backlog_Amount = zeros(NumSamples, MaxTime);

for j = 1:NumSamples
    inventory = InventorySamples{j};
    for i = 1:MaxTime
        if inventory.Log{i, 3} > 0
         Total_Backlog_Amount(j, i) = inventory.Log{i, 3};
        end
    end
end

TotalBacklogVector = reshape(Total_Backlog_Amount, 1, NumSamples*MaxTime);
TotalBacklogVectorNoZeros = TotalBacklogVector(TotalBacklogVector ~= 0);

fig4 = figure();
t4 = tiledlayout(fig4, 1, 1);
ax4 = nexttile(t4);
Fraction_of_Days_Histogram = histogram(ax4, TotalBacklogVectorNoZeros, Normalization = "count", BinMethod = "auto");
title(ax4, "Total Backlog Amount");
xlabel(ax4, "Total Amount");
ylabel(ax4, "Count");

% Make this reproducible
rng("default");

% Samples are stored in this cell array of Inventory objects
InventorySamples = cell([NumSamples, 1]);

% Run samples of the simulation.
% Log entries are recorded at the end of every day
for SampleNum = 1:NumSamples
    fprintf("Working on %d\n", SampleNum);
    inventory = Inventory( ...
        RequestCostPerBatch=K, ...
        RequestCostPerUnit=c, ...
        RequestLeadTime=L, ...
        HoldingCostPerUnitPerDay=h, ...
        ReorderPoint=ROP, ...
        OnHand=Q, ...
        RequestBatchSize=Q);
    run_until(inventory, MaxTime);
    InventorySamples{SampleNum} = inventory;
end

%% Collect statistics

% Pull the RunningCost from each complete sample.
TotalCosts = cellfun(@(i) i.RunningCost, InventorySamples);

% Express it as cost per day and compute the mean, so that we get a number
% that doesn't depend directly on how many time steps the samples run for.
meanDailyCost = mean(TotalCosts/MaxTime);
fprintf("Mean daily cost: %f\n", meanDailyCost);

%% Make pictures

% Make a figure with one set of axes.
fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);

% Histogram of the cost per day.
h = histogram(ax, TotalCosts/MaxTime, Normalization="probability", ...
    BinWidth=5);

% Add title and axis labels
title(ax, "Daily total cost");
xlabel(ax, "Dollars");
ylabel(ax, "Probability");

% Fix the axis ranges
ylim(ax, [0, 0.5]);
xlim(ax, [240, 290]);

% Wait for MATLAB to catch up.
pause(2);

% Save figure as a PDF file
exportgraphics(fig, "Daily cost histogram.pdf");