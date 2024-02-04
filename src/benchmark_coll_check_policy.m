%%
% Copyright (c) 2017 Carnegie Mellon University, Sanjiban Choudhury <sanjibac@andrew.cmu.edu>
%
% For License information please see the LICENSE file in the root directory.
%

clc; % Xóa Command Window
clear; % Xóa tất cả các biến
close all; % Đóng tất cả các cửa sổ hình

%% Load data
set_dataset = strcat(getenv('collision_checking_dataset_folder'), '/dataset_2d_1/'); % Thiết lập đường dẫn đến tập dữ liệu

G = load_graph( strcat(set_dataset,'graph.txt') ); % Tải đồ thị từ file
load(strcat(set_dataset, 'world_library_assignment.mat'), 'world_library_assignment'); % Tải thư viện gán thế giới
load(strcat(set_dataset, 'path_library.mat'), 'path_library'); % Tải thư viện đường đi
load( strcat(set_dataset, 'coll_check_results.mat'), 'coll_check_results' ); % Tải kết quả kiểm tra va chạm

%% Extract relevant info
world_library_assignment = logical(world_library_assignment); % Chuyển đổi dữ liệu gán thế giới thành kiểu logic
coll_check_results = logical(coll_check_results); % Chuyển đổi kết quả kiểm tra va chạm thành kiểu logic
edge_check_cost = ones(1, size(coll_check_results,2)); % Khởi tạo chi phí kiểm tra cạnh

path_edgeid_map = get_path_edgeid_map( path_library, G ); % Lấy bản đồ ID cạnh đường đi

%% Do a dimensionality reduction
if(isequal(tril(G), triu(G))) % Kiểm tra nếu đồ thị là không hướng
    % Loại bỏ các cạnh dư thừa
    [ G, coll_check_results, edge_check_cost, path_edgeid_map ] = remove_redundant_edges( G,coll_check_results, edge_check_cost, path_edgeid_map  );
end

%% Load train test id
load(strcat(set_dataset, 'train_id.mat'), 'train_id'); % Tải ID tập huấn luyện
load(strcat(set_dataset, 'test_id.mat'), 'test_id'); % Tải ID tập kiểm tra

train_world_library_assignment = world_library_assignment(train_id, :); % Lấy gán thế giới cho tập huấn luyện
train_coll_check_results = coll_check_results(train_id, :); % Lấy kết quả kiểm tra va chạm cho tập huấn luyện

%% Create a policy set
set = 1; % Thiết lập số
policy_set = {}; % Khởi tạo tập chính sách
switch set
    case 1
        % Các chính sách được thêm vào tập chính sách
        % LazySP, LazySP + MaxProbReg, Random, Random + MaxProbReg, MaxTally, MaxTally + MaxProbReg, MaxSetCover, MaxSetCover + MaxProbReg, MVOI, BISECT, BISECT + MaxProbReg
        % LazySP
        policy_set{length(policy_set)+1} = @() policyLazySP(path_edgeid_map, train_world_library_assignment, train_coll_check_results, G, 0.01, 0);
        % LazySP + MaxProbReg
        policy_set{length(policy_set)+1} = @() policyLazySP(path_edgeid_map, train_world_library_assignment, train_coll_check_results, G, 0.01, 1);
        % Random
        policy_set{length(policy_set)+1} = @() policyRandomEdge(path_edgeid_map, train_world_library_assignment, train_coll_check_results, 0.01, false, 0);
        % Random + MaxProbReg
        policy_set{length(policy_set)+1} = @() policyRandomEdge(path_edgeid_map, train_world_library_assignment, train_coll_check_results, 0.01, false, 1);
        % MaxTally
        policy_set{length(policy_set)+1} = @() policyMaxTallyEdge(path_edgeid_map, train_world_library_assignment, train_coll_check_results, 0.01, false, 0);
        % MaxTally + MaxProbReg
        policy_set{length(policy_set)+1} = @() policyMaxTallyEdge(path_edgeid_map, train_world_library_assignment, train_coll_check_results, 0.01, false, 1);
        % MaxSetCover
        policy_set{length(policy_set)+1} = @() policyMaxSetCover(path_edgeid_map, train_world_library_assignment, train_coll_check_results, 0.01, false, 0);
        % MaxSetCover + MaxProbReg
        policy_set{length(policy_set)+1} = @() policyMaxSetCover(path_edgeid_map, train_world_library_assignment, train_coll_check_results, 0.01, false, 1);
        % MVOI
        policy_set{length(policy_set)+1} = @() policyMaxMVOI(path_edgeid_map, train_world_library_assignment, train_coll_check_results, 0.01, false);
        % BISECT
        policy_set{length(policy_set)+1} = @() policyDRDBernoulli(path_edgeid_map, edge_check_cost, train_world_library_assignment, train_coll_check_results, 0.01, false, 0);
        % BISECT + MaxProbReg
        policy_set{length(policy_set)+1} = @() policyDRDBernoulli(path_edgeid_map, edge_check_cost, train_world_library_assignment, train_coll_check_results, 0.01, false, 1);
    case 2
        % DIRECT + BISECT
        load(strcat(set_dataset, 'saved_decision_trees/drd_decision_tree_data.mat'), 'decision_tree_data'); % Tải dữ liệu cây quyết định
        policy_set{length(policy_set)+1} = @() policyDecisionTreeandBern(decision_tree_data, path_edgeid_map, edge_check_cost, 0.01, false, 0.2); % Thêm chính sách vào tập chính sách
end

%% Perform stuff
cumulative_cost_set = zeros(length(policy_set), length(test_id)); % Khởi tạo tập chi phí tích lũy
counter = 0;
for i = 1:length(policy_set) % Vòng lặp qua tất cả các chính sách
    parfor j = 1:length(test_id) % Vòng lặp qua tất cả các ID kiểm tra
        policy_fn = policy_set{i}; % Lấy chính sách
        policy = policy_fn(); % Thực thi chính sách
        test_world = test_id(j); % Chọn thế giới kiểm tra từ tập ID kiểm tra
        selected_edge_outcome_matrix = []; % Khởi tạo ma trận kết quả cạnh đã chọn

        while (1) % Vòng lặp vô hạn
            selected_edge = policy.getEdgeToCheck(); % Gọi chính sách để chọn cạnh
            if (isempty(selected_edge)) % Kiểm tra nếu không có cạnh nào được chọn
                error('No valid selection made'); % Tạo lỗi nếu không có lựa chọn hợp lệ
            end

            outcome = coll_check_results(test_world, selected_edge); % Quan sát kết quả
            policy.setOutcome(selected_edge, outcome); % Đặt kết quả cho chính sách
            selected_edge_outcome_matrix = [selected_edge_outcome_matrix; selected_edge outcome]; % Cập nhật ma trận sự kiện

            if (any_path_feasible( path_edgeid_map, selected_edge_outcome_matrix )) % Kiểm tra nếu bất kỳ đường đi nào khả thi
                break; % Thoát khỏi vòng lặp
            end
            counter++;
            if(mod(counter, 1000) == 0)
                disp(sprintf('Loop #%d', counter));
            end
        end
        cumulative_cost_set(i, j) = sum(edge_check_cost(selected_edge_outcome_matrix(:,1))); % Tính tổng chi phí kiểm tra cạnh
        fprintf('Policy: %d Test: %d Cost of check: %f \n', i, j, cumulative_cost_set(i, j)); % In chi phí kiểm tra
    end
end
