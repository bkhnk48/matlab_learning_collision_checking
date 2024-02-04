%%
% This file is part of the mat2cpp project.
% mat2cpp is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% mat2cpp is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with mat2cpp; see the file COPYING.  If not, write to
% the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
% Boston, MA 02110-1301, USA.
%

classdef (Abstract) CollisionCheckPolicy %< handle & matlab.mixin.Copyable
    %COLLISIONCHECKPOLICY An interface class for collision checking
    %contracts

    properties
    end

    %methods (Abstract)
    %    edgeid = getEdgeToCheck(self);
        % chooses the next action

    %    setOutcome(self, selected_edge, outcome);
        % update after new observation

    %   plotDebug2D(self, graph, coord_set, path_library);
        % plot stuff

    %   printDebug(self);
        % Print anything for debugging
    %end

    methods
        function edgeid = getEdgeToCheck(self)
        % code here
        end

        function setOutcome(self, selected_edge, outcome)
        % code here
        end

        function plotDebug2D(self, graph, coord_set, path_library)
        % code here
        end

        function printDebug(self)
        % code here
        end
    end

end
