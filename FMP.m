% دریافت دبی و هد از کاربر
debi = input('لطفا دبی را وارد کنید: ');
hed = input('لطفا هد را وارد کنید: ');

% انتخاب مسیر پوشه
data_folder = uigetdir('', 'پوشه فایل‌ها را انتخاب کنید');
if data_folder == 0
    disp('پوشه‌ای انتخاب نشد.');
    return;
end

% لیست فایل‌های مدل پمپ
pump_files = {'d110.csv', 'd115.csv', 'd120.csv', 'd125.csv', 'd130.csv', 'd135.csv', 'd139.csv'};

% -------------------- مرحله ۱: یافتن مدل پمپ --------------------
pump_model = 0;
for i = 1:length(pump_files)
    filename = fullfile(data_folder, pump_files{i});
    if ~isfile(filename)
        continue;
    end
    data = readmatrix(filename);
    data = sortrows(data, [1,2]); % مرتب‌سازی بر اساس دبی و هد
    [found, idx] = stepInterpolation(data, debi, hed);
    if found
        pump_model = i;
        break;
    end
end

if pump_model == 0
    fprintf('❌ هیچ مدل پمپی با دبی %.2f و هد %.2f یافت نشد.\n', debi, hed);
    return;
end

% -------------------- مرحله ۲: یافتن قطر پره --------------------
impeller_model = 0;
for j = 1:5
    impeller_file = fullfile(data_folder, sprintf('impeller%d_%d.csv', pump_model, j));
    if ~isfile(impeller_file)
        continue;
    end
    data = readmatrix(impeller_file);
    data = sortrows(data, [1,2]);
    [found, idx] = stepInterpolation(data, debi, hed);
    if found
        impeller_model = j;
        break;
    end
end

if impeller_model == 0
    fprintf('❌ هیچ قطر پره‌ای مناسب با مدل پمپ %s یافت نشد.\n', pump_files{pump_model});
    return;
end

% -------------------- مرحله ۳: یافتن بازده --------------------
efficiency_model = 0;
for k = 1:6
    efficiency_file = fullfile(data_folder, sprintf('efficiency%d_%d.csv', pump_model, k));
    if ~isfile(efficiency_file)
        continue;
    end
    data = readmatrix(efficiency_file);
    data = sortrows(data, [1,2]);
    [found, idx] = stepInterpolation(data, debi, hed);
    if found
        efficiency_model = k;
        break;
    end
end

if efficiency_model == 0
    fprintf('❌ هیچ فایل بازده‌ای مناسب برای مدل پمپ %s یافت نشد.\n', pump_files{pump_model});
    return;
end

% -------------------- نمایش نتایج --------------------
fprintf('\n✅ نتیجه:\n');
fprintf('مدل پمپ: %d (%s)\n', pump_model, pump_files{pump_model});
fprintf('قطر پره: %d (impeller%d_%d.csv)\n', impeller_model, pump_model, impeller_model);
fprintf('بازده: %d (efficiency%d_%d.csv)\n', efficiency_model, pump_model, efficiency_model);

% -------------------- تابع میان‌یابی پله‌ای --------------------
function [found, idx] = stepInterpolation(data, debi, hed)
    found = false;
    idx = -1;
    for i = 1:size(data,1)-1
        d1 = data(i,1); h1 = data(i,2);
        d2 = data(i+1,1); h2 = data(i+1,2);

        if debi == d1 && hed == h1
            found = true;
            idx = i;
            return;
        end

        if (debi >= d1 && debi <= d2) && (hed >= h1 && hed <= h2)
            found = true;
            idx = i;
            return;
        end
    end
end
