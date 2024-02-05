%% 
% Copyright (c) 2017 Carnegie Mellon University, Sanjiban Choudhury <sanjibac@andrew.cmu.edu>
%
% For License information please see the LICENSE file in the root directory.
%

function world_library_assignment = get_world_library_assignment( path_library, coll_check_results, G )
% Hàm này trả về một ma trận logic cho biết các đường dẫn trong thư viện đường dẫn có thể được gán cho thế giới không?
% Tham số đầu vào là:
% - path_library: một cell array chứa các đường dẫn được biểu diễn bởi các điểm trong đồ thị G
% - coll_check_results: một ma trận logic cho biết kết quả kiểm tra va chạm cho mỗi cạnh của đồ thị G
% - G: một đối tượng đồ thị biểu diễn môi trường
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

path_edgeid_map = get_path_edgeid_map( path_library, G );
% Gọi hàm get_path_edgeid_map để lấy một cell array chứa các chỉ số của các cạnh trong đồ thị G tương ứng với mỗi đường dẫn trong thư viện đường dẫn
world_library_assignment = false(size(coll_check_results, 1), length(path_edgeid_map));
% Khởi tạo một ma trận logic với kích thước bằng số lượng thế giới (hàng) và số lượng đường dẫn (cột), và gán tất cả các giá trị là false
for i = 1:size(world_library_assignment,2)
    % Vòng lặp qua tất cả các cột của ma trận world_library_assignment, tương ứng với các đường dẫn
    world_library_assignment(:,i) = ~any(~coll_check_results(:,path_edgeid_map{i}),2);
    % Gán giá trị của cột i bằng phủ định của phép toán any trên các hàng của ma trận coll_check_results, lấy ra các giá trị tại các chỉ số trong cell array 
    %path_edgeid_map{i}, và thực hiện theo chiều hàng. 
    %Điều này có nghĩa là, nếu một đường dẫn có bất kỳ cạnh nào bị va chạm trong một thế giới, thì giá trị tại cột đó và hàng đó sẽ là false, ngược lại sẽ là true.
end

end

