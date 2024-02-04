%% 
% Copyright (c) 2017 Carnegie Mellon University, Sanjiban Choudhury <sanjibac@andrew.cmu.edu>
%
% For License information please see the LICENSE file in the root directory.
%

classdef policyDRDBernoulli < CollisionCheckPolicy
    %POLICYDRD Vanilla DRD method to decide which policy to collision check
    % If test world is not from train world, this policy will not guarantee
    % that it will find a path should it exist. Refer to other extended
    % policies in such case
    properties
        region_test
        test_bias
        test_cost
        selected_test_outcome
        hyp_region
        hyp_test
        active_hyp
        mixing %0 means use only prior ... 1 means use 0.5
        update_posterior %true (update using collected data)
        test_gain
        option
    end
    
    methods
        function self = policyDRDBernoulli(path_edgeid_map, test_cost, hyp_region, hyp_test, mixing, update_posterior, option)
        % Hàm khởi tạo của lớp, nhận vào các tham số là ánh xạ của các đường đi và các cạnh, chi phí kiểm tra, các giả thuyết về các vùng và các cạnh, hệ số trộn, việc cập nhật hậu nghiệm và lựa chọn phương pháp
            self.region_test = false(length(path_edgeid_map), length(test_cost));% Khởi tạo ma trận region_test với kích thước bằng số đường đi và số cạnh, giá trị ban đầu là false
            for i = 1:length(path_edgeid_map) % Duyệt qua từng đường đi
                for e = path_edgeid_map{i} % Duyệt qua từng cạnh thuộc đường đi
                    self.region_test(i, e) = true; % Đánh dấu cạnh đó thuộc đường đi
                end
            end
            self.hyp_region = hyp_region; % Gán giá trị cho thuộc tính hyp_region
            self.hyp_test = hyp_test; % Gán giá trị cho thuộc tính hyp_test
            self.active_hyp = 1:size(hyp_region, 1); % Khởi tạo vector active_hyp với các chỉ số từ 1 đến số giả thuyết
            self.test_cost = test_cost; % Gán giá trị cho thuộc tính test_cost
            self.mixing = mixing; % Gán giá trị cho thuộc tính mixing
            self.update_posterior = update_posterior; % Gán giá trị cho thuộc tính update_posterior
            self.selected_test_outcome = []; % Khởi tạo ma trận selected_test_outcome rỗng
            self.test_gain = zeros(1, length(self.test_cost)); % Khởi tạo vector test_gain với các phần tử bằng 0
            self.option = option; % Gán giá trị cho thuộc tính option
            
            test_count = (1/size(self.hyp_test,1))*sum(self.hyp_test(self.active_hyp,:), 1);
            % Tính xác suất tiền nghiệm của các cạnh bằng cách lấy tổng số lần xuất hiện của chúng trong các giả thuyết còn hoạt động, chia cho số giả thuyết
            self.test_bias = (1 - self.mixing)*test_count + self.mixing*0.5*ones(1, length(self.test_cost));
            % Tính xác suất trộn của các cạnh bằng cách lấy trung bình cộng giữa xác suất tiền nghiệm và xác suất hậu nghiệm (giả sử bằng 0.5)
        end
        
        function edgeid = getEdgeToCheck(self) % Interface function % Phương thức để lấy cạnh cần kiểm tra va chạm tiếp theo
            if (length(self.active_hyp) >= 1) % Nếu còn giả thuyết nào hoạt động
                test_count = (1/length(self.active_hyp))*sum(self.hyp_test(self.active_hyp,:), 1); % Tính lại xác suất tiền nghiệm của các cạnh
            else % Nếu không còn giả thuyết nào hoạt động
                test_count = 0.5*ones(1, length(self.test_cost)); % Gán xác suất tiền nghiệm của các cạnh bằng 0.5
            end
            self.test_bias = (1 - self.mixing)*test_count + self.mixing*0.5*ones(1, length(self.test_cost)); % Tính lại xác suất trộn của các cạnh
            [edgeid, ~, self.test_gain] = direct_drd_bern(  self.selected_test_outcome, self.region_test, self.test_bias, self.test_cost, self.option );
            % Gọi hàm direct_drd_bern để tìm cạnh có lợi ích kiểm tra cao nhất, trả về cạnh đó, lợi ích của nó, và lợi ích của tất cả các cạnh
        end
        
        function setOutcome(self, selected_edge, outcome) %Interface function % Phương thức để cập nhật kết quả kiểm tra va chạm của một cạnh
            if (self.update_posterior) % Nếu có cập nhật xác suất hậu nghiệm
                self.active_hyp = prune_hyp( self.active_hyp, self.hyp_test, selected_edge, outcome ); % Gọi hàm prune_hyp để loại bỏ các giả thuyết không phù hợp với kết quả kiểm tra
            end
            self.selected_test_outcome = [self.selected_test_outcome; selected_edge outcome]; % Thêm kết quả kiểm tra vào ma trận selected_test_outcome
        end
        
        function plotDebug2D(self, graph, coord_set, path_library) % Phương thức để vẽ đồ thị cho việc gỡ lỗi
            plot_edge_utility(self.test_gain, graph, coord_set); % Gọi hàm plot_edge_utility để vẽ đồ thị với các cạnh được tô màu theo lợi ích kiểm tra của chúng
        end
        
        function printDebug(self)
            % Print anything for debugging
        end
    end
end

